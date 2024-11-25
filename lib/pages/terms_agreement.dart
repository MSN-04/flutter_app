import 'dart:convert'; // JSON 데이터를 처리하기 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 구성 요소
import 'package:nk_push_app/Utils/util.dart'; // 유틸리티 클래스
import 'package:nk_push_app/constants/url_constants.dart'; // URL 상수 모음
import 'package:nk_push_app/http/http_service.dart'; // HTTP 요청 처리 클래스
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 접근

/// 약관 동의 화면
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  _TermsAgreementScreenState createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  List<bool> isScrolledToEndList = []; // 약관 스크롤 완료 여부 리스트
  List<bool> isCheckedList = []; // 약관 체크 상태 리스트
  List<dynamic> termsList = []; // 약관 데이터 리스트
  List<int> tosIdList = []; // 약관 ID 리스트
  Map<String, dynamic>? userData; // 사용자 데이터

  @override
  void initState() {
    super.initState();
    _fetchTerms(); // 약관 데이터 가져오기
  }

  /// 약관 데이터를 서버에서 가져오는 메서드
  Future<void> _fetchTerms() async {
    try {
      var url =
          Uri.parse(UrlConstants.apiUrl + UrlConstants.getTos); // 약관 API URL
      var response = await HttpService.get(url.toString());

      if (response.statusCode == 200) {
        termsList = jsonDecode(response.body); // 약관 데이터를 JSON으로 변환
        for (var term in termsList) {
          tosIdList.add(term['TOS_ID']); // 약관 ID 추가
        }
        setState(() {
          isScrolledToEndList =
              List<bool>.filled(termsList.length, false); // 스크롤 상태 초기화
          isCheckedList =
              List<bool>.filled(termsList.length, false); // 체크 상태 초기화
        });
      } else {
        Util.showErrorAlert("Failed to load terms"); // 오류 메시지 표시
      }
    } catch (e) {
      Util.showErrorAlert("Error loading terms: $e"); // 예외 처리
    }
  }

  /// 약관 동의를 서버에 전송하는 메서드
  void _submitAgreement() async {
    bool success = await _sendAgreementData();
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard'); // 대시보드로 이동
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("동의 저장 실패"))); // 저장 실패 메시지
      _rejectAgreement(); // 동의 거부 처리
    }
  }

  /// 로컬 저장소에서 사용자 데이터를 가져오는 메서드
  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user'); // 저장된 사용자 데이터 가져오기
    return userData != null ? jsonDecode(userData) : {};
  }

  /// 약관 동의 데이터를 서버로 전송
  Future<bool> _sendAgreementData() async {
    var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.saveTos).toString();
    userData = await loadUserData();
    var response = await HttpService.post(url, {
      'userId': userData?['PSPSN_NO'],
      'tosId': tosIdList,
      'termYn':
          isCheckedList.every((isChecked) => isChecked), // 모든 약관이 체크되었는지 확인
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['resultState'] == "Y") {
        return true;
      } else {
        Util.showErrorAlert(data['resultMessage']); // 서버 응답 메시지 표시
      }
    }
    return false;
  }

  /// 약관 동의를 거부하는 메서드
  Future<void> _rejectAgreement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("user"); // 사용자 데이터 삭제
    prefs.remove("comp"); // 회사 데이터 삭제
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (route) => false); // 로그인 화면으로 이동
  }

  /// 화면 렌더링 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), // 앱바 아이콘 색상
        title: const Text(
          '약관 동의',
          style: TextStyle(color: Colors.white, fontSize: 20), // 앱바 제목 스타일
        ),
        backgroundColor: const Color(0xFF004A99), // 앱바 배경색
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: termsList.isEmpty
            ? const Center(child: CircularProgressIndicator()) // 로딩 상태 표시
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: termsList.length, // 약관 개수
                      itemBuilder: (context, index) => _buildAgreementSection(
                        termsList[index]['TOS_TITLE'] ??
                            "약관 ${index + 1}", // 약관 제목
                        termsList[index]['TOS_BODY'] ?? "", // 약관 내용
                        true, // 스크롤 상태
                        (value) {
                          setState(() {
                            isScrolledToEndList[index] = value; // 스크롤 상태 업데이트
                          });
                        },
                        (value) {
                          setState(() {
                            isCheckedList[index] = value!; // 체크 상태 업데이트
                          });
                        },
                        isCheckedList[index], // 현재 체크 상태
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 동의 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isCheckedList.every((isChecked) => isChecked)
                          ? _submitAgreement
                          : null, // 모든 체크 완료 시 활성화
                      child: const Text(
                        "동의합니다.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 동의하지 않음 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _rejectAgreement,
                      child: const Text(
                        "동의하지 않습니다.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 약관 섹션을 생성하는 메서드
  Widget _buildAgreementSection(
    String title,
    String content,
    bool isScrolledToEnd,
    Function(bool) onScrollEnd,
    Function(bool?) onCheckboxChanged,
    bool isChecked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 약관 제목 표시
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // 약관 내용 스크롤 가능한 컨테이너
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 179, 179, 179)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 약관 내용이 짧으면 자동으로 스크롤 완료 상태 설정
              Future.microtask(() {
                if (content.length < constraints.maxHeight ~/ 20) {
                  onScrollEnd(true);
                }
              });

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                    onScrollEnd(true); // 스크롤 완료 상태 업데이트
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(content), // 약관 내용 표시
                  ),
                ),
              );
            },
          ),
        ),
        // 스크롤 완료 시 동의 체크박스 표시
        if (isScrolledToEnd) //isScrolledToEnd
          Row(
            children: [
              Checkbox(
                value: isChecked,
                onChanged: onCheckboxChanged,
              ),
              const Text("이용약관과 개인정보 수집 및 이용에 모두 동의합니다."),
            ],
          ),
      ],
    );
  }
}
