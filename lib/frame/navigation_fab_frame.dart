import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nk_push_app/Utils/util.dart';
import 'package:nk_push_app/constants/url_constants.dart';
import 'package:nk_push_app/http/http_service.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 네비게이션 및 플로팅 액션 버튼을 포함한 화면의 공통 프레임
class NavigationFABFrame extends StatefulWidget {
  final Widget child; // 화면의 주요 내용을 포함하는 위젯

  const NavigationFABFrame({super.key, required this.child});

  @override
  _NavigationFABFrameState createState() => _NavigationFABFrameState();
}

class _NavigationFABFrameState extends State<NavigationFABFrame>
    with WidgetsBindingObserver {
  // Drawer 메뉴 데이터를 저장할 리스트
  List<Map<String, dynamic>> menus = [];

  // 로컬 인증 객체
  final LocalAuthentication auth = LocalAuthentication();

  // 마지막 인증 시간
  DateTime? _lastAuthenticatedTime;

  // 인증 타임아웃 설정
  static const _authTimeout = Duration(seconds: 1);
  static const _noAuthTimeout = Duration(hours: 8);

  // 사용자 데이터
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 라이프사이클 상태 관찰자 등록
    _fetchPendingTasks(); // 서버에서 메뉴 데이터 가져오기
    _initializeData(); // 초기 사용자 데이터 로드
  }

  Future<void> _initializeData() async {
    userData = await loadUserData(); // SharedPreferences에서 사용자 데이터 로드
    await checkFcmToken();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 라이프사이클 상태 관찰자 제거
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    var logout = false; // 로그아웃 여부 플래그

    // 앱이 재개되었을 때의 처리
    if (state == AppLifecycleState.resumed) {
      bool isDeviceSupported =
          await auth.isDeviceSupported(); // 장치가 생체 인증 지원 여부 확인
      bool canCheckBiometrics = await auth.canCheckBiometrics; // 생체 인증 가능 여부 확인
      if (!isDeviceSupported) {
        logout = _shouldAuthenticate(_noAuthTimeout); // 인증 시간 초과 여부 확인
      } else if (!canCheckBiometrics) {
        logout = _shouldAuthenticate(_authTimeout); // 인증 시간 초과 여부 확인
      } else {
        logout = _shouldAuthenticate(_authTimeout);
      }

      // 로그아웃 필요 시 처리
      if (logout) {
        _handleAppResume();
      }
    }

    // 인증 시간 갱신
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.resumed) {
      _lastAuthenticatedTime = DateTime.now();
    }
  }

  /// SharedPreferences에서 사용자 데이터 로드
  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    return userData != null ? jsonDecode(userData) : {};
  }

  Future checkFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? newToken = Platform.isAndroid
        ? await messaging.getToken()
        : await messaging.getAPNSToken();

    if (newToken != null) {
      print("FCM New Token: $newToken");

      // 로컬 저장소에 FCM 토큰 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? originToken = prefs.getString('fcm_token');
      print("FCM Origin Token: $originToken");

      if (newToken != originToken) {
        var url =
            Uri.parse(UrlConstants.apiUrl + UrlConstants.saveToken).toString();
        var response = await HttpService.post(url, {
          'id': userData?['PSPSN_NO'],
          'token': newToken,
        });
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data['resultState'] == "Y") {
            await prefs.setString('fcm_token', newToken);
          }
        }
      }
    } else {
      print("FCM 토큰 가져오기 실패");
    }
  }

  /// 인증 필요 여부 확인
  bool _shouldAuthenticate(Duration timeout) {
    if (_lastAuthenticatedTime == null) return true;
    final timeSinceLastAuth =
        DateTime.now().difference(_lastAuthenticatedTime!);
    return timeSinceLastAuth >= timeout;
  }

  /// 앱이 재개될 때 처리
  Future<void> _handleAppResume() async {
    bool isDeviceSupported = await auth.isDeviceSupported();
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    if (!isDeviceSupported) {
      // 장치가 생체 인증을 지원하지 않는 경우 로그아웃 처리
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else if (!canCheckBiometrics) {
      // 생체 인증을 사용할 수 없는 경우 사용자 알림 후 로그아웃 처리
      Util.showAlert('생체 인증이 활성화되지 않았습니다. 설정에서 활성화해주세요.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      // 생체 인증 시도
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

  /// 생체 인증 수행
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

  /// 로그아웃 조건 확인
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

  /// 서버에서 메뉴 데이터를 가져옴
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
      // End Drawer 설정
      endDrawer: Drawer(
        width: 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
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
            // 대시보드 메뉴
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('대시보드'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            // 동적으로 생성된 메뉴
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
            // 로그아웃 메뉴
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
      // 플로팅 액션 버튼
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
      // 전달된 자식 위젯 렌더링
      body: widget.child,
    );
  }
}
