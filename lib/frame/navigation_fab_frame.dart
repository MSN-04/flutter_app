import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nk_push_app/Utils/util.dart';
import 'package:nk_push_app/constants/url_constants.dart';
import 'package:nk_push_app/http/http_service.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NavigationFABFrame extends StatefulWidget {
  final Widget child;

  const NavigationFABFrame({super.key, required this.child});

  @override
  _NavigationFABFrameState createState() => _NavigationFABFrameState();
}

class _NavigationFABFrameState extends State<NavigationFABFrame>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> menus = [];
  final LocalAuthentication auth = LocalAuthentication();
  DateTime? _lastAuthenticatedTime;
  static const _authTimeout = Duration(minutes: 10);
  static const _noAuthTimeout = Duration(hours: 8);
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Lifecycle Observer 등록
    _fetchPendingTasks(); // 데이터 가져오기
    _initializeData();
  }

  Future<void> _initializeData() async {
    userData = await loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer 제거
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    var logout = false; //true 면 로그아웃이다
    if (state == AppLifecycleState.resumed) {
      bool isDeviceSupported = await auth.isDeviceSupported();
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (!isDeviceSupported) {
        logout = _shouldAuthenticate(_noAuthTimeout);
      } else if (!canCheckBiometrics) {
        logout = _shouldAuthenticate(_authTimeout);
      } else {
        logout = _shouldAuthenticate(_authTimeout);
      }

      if (logout) {
        _handleAppResume();
      }
    }

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.resumed) {
      _lastAuthenticatedTime = DateTime.now();
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    return userData != null ? jsonDecode(userData) : {};
  }

  bool _shouldAuthenticate(Duration timeout) {
    if (_lastAuthenticatedTime == null) return true;
    final timeSinceLastAuth =
        DateTime.now().difference(_lastAuthenticatedTime!);
    return timeSinceLastAuth >= timeout;
  }

  Future<void> _handleAppResume() async {
    bool isDeviceSupported = await auth.isDeviceSupported();
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    if (!isDeviceSupported) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else if (!canCheckBiometrics) {
      // 생체 인증을 사용할 수 없는 경우 사용자에게 안내 메시지를 표시
      Util.showAlert('생체 인증이 활성화되지 않았습니다. 설정에서 활성화해주세요.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      bool authenticated = await _authenticateUser();
      if (authenticated) {
        _lastAuthenticatedTime = DateTime.now(); // 인증 성공 시각 갱신
        bool shouldLogout = await _checkLogoutConditions();
        if (!shouldLogout) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      } else {
        // 인증 실패 시 로그인 화면으로 전환
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Future<bool> _authenticateUser() async {
    try {
      return await auth.authenticate(
        localizedReason: '앱을 사용하기 위해 생체 인증이 필요합니다',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print("Authentication error: $e");
      return false;
    }
  }

  Future<bool> _checkLogoutConditions() async {
    try {
      final url =
          Uri.parse(UrlConstants.apiUrl + UrlConstants.getTos).toString();
      final response = await HttpService.get('$url/${userData?['PSPSN_NO']}');
      bool checkTos = false;
      if (response.statusCode == 200) {
        checkTos = json.decode(response.body);
      }
      return checkTos;
    } catch (e) {
      print("Error checking logout conditions: $e");
      return false;
    }
  }

  Future<void> _fetchPendingTasks() async {
    try {
      final url = Uri.parse(UrlConstants.apiUrl + UrlConstants.menu).toString();
      final response = await HttpService.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          menus =
              decodedData.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        width: 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 120,
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF004A99)),
                child: Center(
                  child: Image.asset(
                    'assets/img/nk_logo.png',
                    height: 25,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('대시보드'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ...menus.map((menu) {
              return ListTile(
                leading: Icon(Util.getIcon(menu['TYPE_ICON'] ?? 'null')),
                title: Text(menu['TYPE_NAME']),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/push_type',
                      arguments: {
                        'typeCode': menu['TYPE_CODE'],
                        'typeName': menu['TYPE_NAME'],
                        'typeIcon': menu['TYPE_ICON']
                      });
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (BuildContext context) {
          return FloatingActionButton(
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            backgroundColor: const Color(0xFF8cc63f),
            child: const Icon(Icons.menu),
          );
        },
      ),
      body: widget.child,
    );
  }
}
