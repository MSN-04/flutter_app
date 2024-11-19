// lib/notification_detail_screen.dart
import 'dart:convert'; // JSON 변환을 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 구성 요소
import 'package:nk_push_app/http/http_service.dart'; // HTTP 요청 처리 클래스

import '../Utils/util.dart'; // 유틸리티 클래스
import '../constants/url_constants.dart'; // URL 상수 모음
import '../frame/navigation_fab_frame.dart'; // 공통 프레임 위젯

/// 알림 상세 화면 위젯
class PushTypeDetailScreen extends StatelessWidget {
  const PushTypeDetailScreen({super.key});

  /// 알림을 처리하는 메서드
  ///
  /// [context]: 현재 화면의 빌드 컨텍스트
  /// [pushId]: 처리할 알림의 ID
  Future<void> _handlePushProcessing(BuildContext context, int pushId) async {
    try {
      // 전달된 알림 상세 정보를 가져옴
      final Map<String, dynamic> pushTypeDetail =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      int id = pushTypeDetail['PUSH_ID'];

      // 알림 처리 API 호출
      final url = Uri.parse('${UrlConstants.apiUrl}${UrlConstants.pushcheck}')
          .toString();
      final response = await HttpService.post(url, {'id': id});

      // API 호출 성공 시 처리 결과에 따른 행동 수행
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['resultState'] == "Y") {
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "처리되었습니다.",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF004A99),
            ),
          );
          Navigator.pop(context, true); // 이전 화면으로 처리 상태 전달
        } else {
          // 실패 메시지 표시
          Util.showErrorAlert(data['resultMessage']);
        }
      } else {
        throw Exception("Failed to process notification");
      }
    } catch (e) {
      // 예외 처리
      print("Error processing notification: $e");
      Util.showErrorAlert("처리 중 오류가 발생했습니다.");
    }
  }

  /// 화면 렌더링 메서드
  @override
  Widget build(BuildContext context) {
    // 이전 화면에서 전달된 알림 상세 데이터를 가져옴
    final Map<String, dynamic> pushTypeDetail =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // 알림이 처리 가능한 상태인지 확인
    final bool isProcessable = pushTypeDetail['PUSH_CHK'] == false;

    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white), // 아이콘 색상 설정
          title: const Text(
            '알림 상세',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF004A99), // 앱바 배경색
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0), // 화면 여백
          child: SizedBox(
            width: double.infinity, // 카드 너비를 화면에 맞춤
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 카드 모서리 둥글기 설정
              ),
              elevation: 4, // 카드 그림자 효과
              child: Padding(
                padding: const EdgeInsets.all(20.0), // 카드 내부 여백
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                  children: [
                    // 알림 전송 날짜 표시
                    Text(
                      Util.formatDate(pushTypeDetail['PUSH_SEND_DATE'] ?? ''),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 알림 제목 표시
                    Text(
                      pushTypeDetail['PUSH_TITLE'] ?? '알림 제목',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 알림 내용 표시
                    Text(
                      pushTypeDetail['PUSH_CONTENTS'] ??
                          '이곳에 알림의 상세 내용이 표시됩니다.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5, // 줄 간격
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // "처리 완료" 버튼 (처리 가능 상태일 때만 표시)
                    if (isProcessable)
                      SizedBox(
                        width: double.infinity, // 버튼 너비를 화면에 맞춤
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // 버튼 색상
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // 버튼 모서리 둥글기
                            ),
                          ),
                          onPressed: () {
                            _handlePushProcessing(context,
                                pushTypeDetail['PUSH_ID']); // 버튼 클릭 시 알림 처리
                          },
                          child: const Text(
                            "처리 완료",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
