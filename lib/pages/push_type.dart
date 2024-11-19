import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/util.dart';
import '../constants/url_constants.dart';
import '../frame/navigation_fab_frame.dart';

class PushTypeScreen extends StatefulWidget {
  const PushTypeScreen({super.key});

  @override
  PushTypeScreenState createState() => PushTypeScreenState();
}

class PushTypeScreenState extends State<PushTypeScreen> {
  final List<Map<String, dynamic>> _pushTypeList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false; // 초기 로딩 상태
// 새로고침 상태
  int _page = 1;
  Map<String, dynamic>? userData;
  String? typeCode;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true); // 초기 로딩 시작
    userData = await loadUserData();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    typeCode = args?['typeCode'];
    await _fetchPushTypeList();
    setState(() => _isLoading = false); // 초기 로딩 완료
  }

  Future<void> _fetchPushTypeList() async {
    if (userData == null || typeCode == null) return;

    try {
      final url = Uri.parse(
          '${UrlConstants.apiUrl}${UrlConstants.push}/$typeCode/${userData?['PSPSN_NO']}/$_page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> newPushTypeList = jsonDecode(response.body);
        setState(() {
          _pushTypeList.addAll(newPushTypeList.cast<Map<String, dynamic>>());
          _page++;
        });
      } else {
        print("Failed to load push: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching push: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshPushTypeList() async {
    if (_isLoading) return; // 초기 로딩 중일 때는 새로고침을 하지 않음

    setState(() {
      _pushTypeList.clear();
      _page = 1;
    });
    await _fetchPushTypeList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchPushTypeList();
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    return userData != null ? jsonDecode(userData) : {};
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    String typeName = args?['typeName'] ?? '알림 목록';
    String typeIcon = args?['typeIcon'] ?? 'notificatrion';

    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          leading: Icon(Util.getIcon(typeIcon)),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            typeName,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: const Color(0xFF004A99),
        ),
        body: Stack(
          children: [
            // RefreshIndicator는 _isLoading이 아닐 때만 작동하도록
            if (!_isLoading)
              RefreshIndicator(
                onRefresh: _refreshPushTypeList,
                child: _pushTypeList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '알림이 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _pushTypeList.length,
                        itemBuilder: (context, index) {
                          var pushType = _pushTypeList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: ListTile(
                              leading: Icon(
                                Util.getIcon(pushType['TYPE_ICON_D'] ?? 'null'),
                              ),
                              title: Text(
                                pushType['TYPE_NAME_D'] ?? '알림 제목',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text:
                                        '미확인 (${pushType['PUSH_READ_COUNT'] ?? '0'})',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '미처리 (${pushType['PUSH_CHK_COUNT'] ?? '0'})',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ]),
                              ),
                              onTap: () async {
                                Navigator.pushNamed(
                                  context,
                                  '/push_type_list',
                                  arguments: pushType,
                                ).then((_) {
                                  setState(() {
                                    pushType['PUSH_READ'] = 'Y';
                                  });
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            // 초기 로딩 상태에만 중앙 스피너 표시
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
