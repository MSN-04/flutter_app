import 'dart:convert'; // JSON 변환을 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 구성 요소
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 사용

import '../Utils/util.dart'; // 유틸리티 클래스
import '../constants/url_constants.dart'; // URL 상수 모음
import '../frame/navigation_fab_frame.dart'; // 공통 프레임 위젯
import '../http/http_service.dart'; // HTTP 요청 처리 클래스

/// 대시보드 화면을 나타내는 StatefulWidget
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData; // 사용자 데이터
  List<Map<String, dynamic>> pushs = []; // 푸시 알림 데이터 리스트
  bool isLoading = true; // 데이터 로딩 상태
  String unreadCnt = '0'; // 읽지 않은 알림 수
  String unCheckCnt = '0'; // 확인되지 않은 알림 수
  String comp = ''; // 회사 코드

  @override
  void initState() {
    super.initState();
    _initializeData(); // 초기 데이터 로드
  }

  /// 초기 데이터를 로드하는 메서드
  Future<void> _initializeData() async {
    setState(() => isLoading = true); // 로딩 상태 활성화

    userData = await loadUserData(); // 로컬 저장소에서 사용자 데이터 로드
    if (userData != null) {
      pushs = await fetchPush(userData!); // 서버에서 푸시 알림 데이터 가져오기
    }

    setState(() => isLoading = false); // 로딩 상태 해제
  }

  /// 로컬 저장소에서 사용자 데이터를 가져오는 메서드
  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user'); // 저장된 사용자 데이터
    comp = prefs.getString('comp').toString(); // 저장된 회사 코드
    return userData != null ? jsonDecode(userData) : {}; // JSON 파싱 후 반환
  }

  /// 서버에서 푸시 알림 데이터를 가져오는 메서드
  Future<List<Map<String, dynamic>>> fetchPush(
      Map<String, dynamic> userData) async {
    // 푸시 알림 리스트를 가져오는 API 호출
    final url =
        Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardList).toString();
    final response = await HttpService.get('$url/${userData['PSPSN_NO']}');

    if (response.statusCode == 200) {
      // 데이터를 성공적으로 가져왔을 때 처리
      List<dynamic> jsonData = jsonDecode(response.body);

      // 읽지 않은 알림 수를 가져오는 API 호출
      final url2 = Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardUnread)
          .toString();
      final response2 = await HttpService.get('$url2/${userData['PSPSN_NO']}');
      unreadCnt = response2.body;

      // 확인되지 않은 알림 수를 가져오는 API 호출
      final url3 =
          Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardUnckeck)
              .toString();
      final response3 = await HttpService.get('$url3/${userData['PSPSN_NO']}');
      unCheckCnt = response3.body;

      // 데이터 리스트 반환
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      // 에러 발생 시 예외 처리
      throw Exception("Failed to load push");
    }
  }

  /// 푸시 데이터를 새로 고침하는 메서드
  Future<void> _refreshPushData() async {
    if (userData != null) {
      List<Map<String, dynamic>> updatedPushs = await fetchPush(userData!);
      setState(() {
        pushs = updatedPushs; // 새로 가져온 데이터로 업데이트
      });
    }
  }

  /// 화면을 렌더링하는 메서드
  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator()) // 로딩 중에는 프로그레스 표시
        : NavigationFABFrame(
            child: Stack(
              children: [
                Column(
                  children: [
                    // 사용자 정보 표시 헤더
                    Container(
                      padding: const EdgeInsets.only(
                          top: 50.0, left: 16.0, right: 16.0, bottom: 16.0),
                      color: const Color(0xFF004A99), // 배경색 설정
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Row(
                          children: [
                            // 프로필 이미지
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                '${getPictureUrl()}${userData!['PSPSN_PICTURE'].toString()}',
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 사용자 이름, 직책, 부서 정보
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      userData!['SYUSR_NAME'] ?? '홍길동',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      userData!['PSGRD_NAME'] ?? '책임',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userData!['PSDPT_NAME'] ??
                                      '(주) NK > 특수기기사업본부 운영최적화',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  userData!['PSPSN_EMAIL'] ??
                                      'honggildong@example.com',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 푸시 알림 리스트
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 헤더와 통계 표시
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Text(
                                    '최근 알림',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 읽지 않은 알림 수
                                  Badge(
                                    label: Text(unreadCnt),
                                    backgroundColor: Colors.blueAccent,
                                    child: const Icon(Icons.mark_email_unread),
                                  ),
                                  const SizedBox(width: 8),
                                  // 확인되지 않은 알림 수
                                  Badge(
                                    label: Text(unCheckCnt),
                                    backgroundColor: Colors.redAccent,
                                    child: const Icon(Icons.report),
                                  ),
                                ],
                              ),
                            ),
                            // 푸시 알림 리스트뷰
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refreshPushData, // 새로 고침 핸들러
                                child: pushs.isEmpty
                                    ? const Center(
                                        // 알림이 없을 경우 표시
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                        itemCount: pushs.length,
                                        itemBuilder: (context, index) {
                                          var push = pushs[index];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: ListTile(
                                              leading: Icon(
                                                Util.getIcon(
                                                    push['PUSH_ICON'] ??
                                                        'null'),
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
                                              ),
                                              subtitle: Text(
                                                push['PUSH_CONTENTS'] ??
                                                    '알림 내용',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: Text(
                                                Util.formatDate(
                                                    push['PUSH_SEND_DATE']),
                                              ),
                                              onTap: () async {
                                                await setPushRead(
                                                    push['PUSH_ID']);
                                                _refreshPushData();
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
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  /// 푸시 알림을 읽음으로 표시하는 메서드
  Future<bool> setPushRead(int id) async {
    var url =
        Uri.parse(UrlConstants.apiUrl + UrlConstants.pushDoRead).toString();
    var response = await HttpService.post(url, {'id': id});
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['resultState'] == "Y") {
        return true;
      } else {
        Util.showErrorAlert(data['resultMessage']);
      }
    }
    return false;
  }

  /// 사용자 회사에 따라 프로필 이미지 URL 반환
  String getPictureUrl() {
    switch (comp) {
      case 'NK':
        return 'https://ep.nkcf.com';
      case 'KHNT':
        return 'https://ep.nkspe.com';
      case 'ENK':
        return 'https://ep.enkcf.com';
      case 'TS':
        return 'https://ep.thesafety.com';
      case 'TECH':
        return 'https://ep.nkcng.com';
      default:
        return 'https://ep.nkcf.com';
    }
  }
}
