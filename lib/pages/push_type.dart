import 'dart:convert'; // JSON 데이터 처리 패키지
import 'package:flutter/material.dart'; // Flutter UI 구성 요소
import 'package:http/http.dart' as http; // HTTP 요청 처리 패키지
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 접근

import '../Utils/util.dart'; // 유틸리티 클래스
import '../constants/url_constants.dart'; // URL 상수 모음
import '../frame/navigation_fab_frame.dart'; // 공통 프레임 위젯

/// 특정 알림 유형의 목록을 표시하는 화면
class PushTypeScreen extends StatefulWidget {
  const PushTypeScreen({super.key});

  @override
  PushTypeScreenState createState() => PushTypeScreenState();
}

class PushTypeScreenState extends State<PushTypeScreen> {
  final List<Map<String, dynamic>> _pushTypeList = []; // 알림 데이터 리스트
  final ScrollController _scrollController = ScrollController(); // 스크롤 제어
  bool _isLoading = false; // 데이터 로딩 상태
  int _page = 1; // 현재 페이지 번호
  Map<String, dynamic>? userData; // 사용자 데이터
  String? typeCode; // 알림 유형 코드

  @override
  void initState() {
    super.initState();
    _initializeData(); // 초기 데이터 로드
    _scrollController.addListener(_onScroll); // 스크롤 이벤트 리스너 추가
  }

  /// 초기 데이터를 로드하는 메서드
  Future<void> _initializeData() async {
    setState(() => _isLoading = true); // 로딩 상태 활성화
    userData = await loadUserData(); // 로컬 저장소에서 사용자 데이터 가져오기
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, dynamic>?; // 전달된 데이터
    typeCode = args?['typeCode']; // 알림 유형 코드
    await _fetchPushTypeList(); // 알림 리스트 가져오기
    setState(() => _isLoading = false); // 로딩 상태 해제
  }

  /// 알림 데이터를 가져오는 메서드
  Future<void> _fetchPushTypeList() async {
    if (userData == null || typeCode == null) return;

    try {
      // API 호출 URL 생성
      final url = Uri.parse(
          '${UrlConstants.apiUrl}${UrlConstants.push}/$typeCode/${userData?['PSPSN_NO']}/$_page');
      final response = await http.get(url); // GET 요청

      if (response.statusCode == 200) {
        // API 응답 데이터를 리스트에 추가
        List<dynamic> newPushTypeList = jsonDecode(response.body);
        setState(() {
          _pushTypeList.addAll(newPushTypeList.cast<Map<String, dynamic>>());
          _page++; // 페이지 증가
        });
      } else {
        print("Failed to load push: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching push: $e");
    }
  }

  /// 새로고침 메서드
  Future<void> _refreshPushTypeList() async {
    if (_isLoading) return; // 로딩 중일 경우 동작하지 않음

    setState(() {
      _pushTypeList.clear(); // 기존 데이터 초기화
      _page = 1; // 페이지 번호 초기화
    });
    await _fetchPushTypeList(); // 데이터 다시 가져오기
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 스크롤 리스너 제거
    super.dispose();
  }

  /// 스크롤 이벤트 처리
  void _onScroll() {
    // 스크롤이 끝에 도달하고 로딩 중이 아닐 경우 데이터 추가 로드
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchPushTypeList();
    }
  }

  /// 로컬 저장소에서 사용자 데이터를 가져오는 메서드
  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    return userData != null ? jsonDecode(userData) : {};
  }

  /// 화면 렌더링 메서드
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, dynamic>?; // 전달된 데이터
    String typeName = args?['typeName'] ?? '알림 목록'; // 알림 유형 이름
    String typeIcon = args?['typeIcon'] ?? 'notification'; // 알림 아이콘

    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          leading: Icon(Util.getIcon(typeIcon)), // 알림 유형 아이콘
          iconTheme: const IconThemeData(color: Colors.white), // 아이콘 색상
          title: Text(
            typeName,
            style: const TextStyle(color: Colors.white, fontSize: 20), // 앱바 제목
          ),
          backgroundColor: const Color(0xFF004A99), // 앱바 배경색
        ),
        body: Stack(
          children: [
            // 로딩 상태가 아닐 경우 RefreshIndicator 사용
            if (!_isLoading)
              RefreshIndicator(
                onRefresh: _refreshPushTypeList, // 새로고침 핸들러
                child: _pushTypeList.isEmpty
                    ? const Center(
                        // 데이터가 없을 경우 표시
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
                        itemCount: _pushTypeList.length, // 데이터 수
                        itemBuilder: (context, index) {
                          var pushType = _pushTypeList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8), // 카드 여백
                            child: ListTile(
                              leading: Icon(
                                Util.getIcon(pushType['TYPE_ICON_D'] ?? 'null'),
                              ),
                              title: Text(
                                pushType['TYPE_NAME_D'] ?? '알림 제목',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis, // 텍스트 줄임
                              ),
                              trailing: Text.rich(
                                TextSpan(children: [
                                  // 미확인 알림 개수 표시
                                  TextSpan(
                                    text:
                                        '미확인 (${pushType['PUSH_READ_COUNT'] ?? '0'})',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  // 미처리 알림 개수 표시
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
                                // 알림 상세 화면으로 이동
                                Navigator.pushNamed(
                                  context,
                                  '/push_type_list',
                                  arguments: pushType,
                                ).then((_) {
                                  setState(() {
                                    pushType['PUSH_READ'] = 'Y'; // 읽음 상태 업데이트
                                  });
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            // 로딩 중일 경우 중앙에 스피너 표시
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
