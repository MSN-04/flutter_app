import 'dart:convert'; // JSON 변환을 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 구성 요소
import 'package:http/http.dart' as http; // HTTP 요청 처리 패키지
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 접근
import 'package:flutter_html/flutter_html.dart'; // HTML 렌더링을 위한 패키지

import '../Utils/util.dart'; // 유틸리티 클래스
import '../constants/url_constants.dart'; // URL 상수 모음
import '../frame/navigation_fab_frame.dart'; // 공통 프레임 위젯
import '../http/http_service.dart'; // HTTP 서비스 클래스

/// 알림 유형 목록 화면
class PushTypeListScreen extends StatefulWidget {
  const PushTypeListScreen({super.key});

  @override
  PushTypeListScreenState createState() => PushTypeListScreenState();
}

class PushTypeListScreenState extends State<PushTypeListScreen> {
  final List<Map<String, dynamic>> _pushTypeList = []; // 알림 유형 데이터 리스트
  final ScrollController _scrollController = ScrollController(); // 스크롤 제어
  bool _isLoading = false; // 데이터 로딩 상태
  bool _isRefreshing = false; // 새로고침 상태
  int _page = 1; // 현재 페이지 번호
  Map<String, dynamic>? userData; // 사용자 데이터
  Map<String, dynamic>? pushTypeData; // 알림 유형 데이터

  String _selectedFilter = 'All'; // 선택된 필터 옵션

  @override
  void initState() {
    super.initState();
    _initializeData(); // 초기 데이터 로드
    _scrollController.addListener(_onScroll); // 스크롤 이벤트 리스너 등록
  }

  /// 초기 데이터를 로드하는 메서드
  Future<void> _initializeData() async {
    setState(() => _isLoading = true); // 로딩 상태 활성화
    userData = await loadUserData(); // 로컬 저장소에서 사용자 데이터 가져오기
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, dynamic>?; // 전달된 알림 유형 데이터
    pushTypeData = args;
    await _fetchPushTypeList(); // 알림 유형 리스트 가져오기
    setState(() => _isLoading = false); // 로딩 상태 해제
  }

  /// 알림 유형 리스트를 가져오는 메서드
  Future<void> _fetchPushTypeList() async {
    String? typeCode = pushTypeData?['TYPE_CODE_M']; // 메인 코드
    String? typeSubCode = pushTypeData?['TYPE_CODE_D']; // 서브 코드
    if (userData == null || typeCode == null || typeSubCode == null) return;

    setState(() => _isLoading = true); // 로딩 상태 활성화

    try {
      // API 호출 URL 구성
      final url = Uri.parse(
          '${UrlConstants.apiUrl}${UrlConstants.push}/$typeCode/$typeSubCode/${userData?['PSPSN_NO']}/$_page');
      final response = await http.get(url); // GET 요청

      if (response.statusCode == 200) {
        // 데이터 성공적으로 로드
        List<dynamic> newPushTypeList = jsonDecode(response.body);
        setState(() {
          _pushTypeList.addAll(newPushTypeList.cast<Map<String, dynamic>>());
          _page++; // 페이지 번호 증가
        });
      } else {
        print("Failed to load PushType: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching PushType: $e");
    }

    setState(() {
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  /// 새로고침을 수행하는 메서드
  Future<void> _refreshPushTypeList() async {
    if (_isLoading) return;

    setState(() {
      _isRefreshing = true; // 새로고침 상태 활성화
      _pushTypeList.clear(); // 기존 데이터 초기화
      _page = 1; // 페이지 번호 초기화
    });
    await _fetchPushTypeList(); // 새로고침 데이터 가져오기
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 리스너 제거
    super.dispose();
  }

  /// 스크롤 이벤트 처리 메서드
  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _fetchPushTypeList(); // 스크롤 끝에 도달 시 다음 페이지 데이터 가져오기
    }
  }

  /// 로컬 저장소에서 사용자 데이터를 가져오는 메서드
  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user'); // 사용자 데이터 로드
    return userData != null ? jsonDecode(userData) : {};
  }

  /// 필터를 적용한 데이터 리스트 반환
  List<Map<String, dynamic>> _applyFilter() {
    if (_selectedFilter == 'Unread') {
      return _pushTypeList.where((item) => item['PUSH_READ'] == false).toList();
    } else if (_selectedFilter == 'Unchecked') {
      return _pushTypeList.where((item) => item['PUSH_CHK'] == false).toList();
    } else {
      return _pushTypeList; // 필터 없음
    }
  }

  /// 화면 렌더링 메서드
  @override
  Widget build(BuildContext context) {
    String typeName = pushTypeData?['TYPE_NAME_D'] ?? '알림 목록'; // 알림 유형 이름

    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white), // 아이콘 색상
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 제목과 필터 정렬
            children: [
              Text(
                typeName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              // 필터 드롭다운
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF004A99), // 드롭다운 배경색
                    underline: Container(),
                    value: _selectedFilter, // 현재 필터 값
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                          value: 'All',
                          child: Text('전체 보기',
                              style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(
                          value: 'Unread',
                          child: Text('읽지 않은 알림',
                              style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(
                          value: 'Unchecked',
                          child: Text('확인되지 않은 알림',
                              style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!; // 선택된 필터 업데이트
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF004A99), // 앱바 배경색
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator()) // 로딩 상태 표시
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshPushTypeList, // 새로고침 핸들러
                      child: _applyFilter().isEmpty
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
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _applyFilter().length +
                                  (_isRefreshing ? 1 : 0), // 데이터 수 + 로딩 상태
                              itemBuilder: (context, index) {
                                if (index == _applyFilter().length &&
                                    _isRefreshing) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                var push = _applyFilter()[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      Util.getIcon(push['TYPE_ICON'] ?? 'null'),
                                      color: push['PUSH_CHK'] == false
                                          ? Colors.redAccent
                                          : push['PUSH_READ'] == false
                                              ? Colors.blueAccent
                                              : Colors.grey,
                                    ),
                                    title: Text(
                                      push['PUSH_TITLE'] ?? '알림 제목',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: push['PUSH_CHK'] == false
                                            ? FontWeight.bold
                                            : push['PUSH_READ'] == false
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Html(
                                      data: (push['PUSH_CONTENTS'] ?? '알림 내용')
                                          .replaceAll(RegExp(r'<br\s*/?>'),
                                              ' ') // <br> 태그를 공백으로 치환
                                          .replaceAll(RegExp(r'<[^>]*>'),
                                              ' ') // 모든 HTML 태그 제거
                                          .trim(), // 불필요한 공백 제거,
                                      style: {
                                        "body": Style(
                                          fontSize: FontSize(14.0),
                                          maxLines: 1,
                                          textOverflow: TextOverflow.ellipsis,
                                          color: Colors.grey[600],
                                        ),
                                      },
                                    ),
                                    trailing: Text(
                                      Util.formatDate(push['PUSH_SEND_DATE']),
                                    ),
                                    onTap: () async {
                                      await Util
                                          .markNotificationAsRead(); // 알림 읽음 처리
                                      await setPushRead(
                                          push['PUSH_ID']); // 서버에 읽음 전송
                                      Navigator.pushNamed(
                                        context,
                                        '/push_type_detail',
                                        arguments: push, // 상세 화면으로 데이터 전달
                                      ).then((result) {
                                        if (result != null &&
                                            result is bool &&
                                            result) {
                                          setState(() {
                                            _refreshPushTypeList(); // 데이터 새로고침
                                          });
                                        } else {
                                          setState(() {
                                            push['PUSH_READ'] =
                                                true; // 읽음 상태 업데이트
                                          });
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 서버에 알림 읽음 상태를 업데이트하는 메서드
  Future<bool> setPushRead(int id) async {
    var url =
        Uri.parse(UrlConstants.apiUrl + UrlConstants.pushDoRead).toString();
    var response = await HttpService.post(url, {'id': id});
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['resultState'] == "Y";
    }
    return false;
  }
}
