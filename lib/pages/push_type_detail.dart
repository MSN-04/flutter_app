// lib/notification_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nk_app/http/http_service.dart';

import '../Utils/util.dart';
import '../constants/url_constants.dart';
import '../frame/navigation_fab_frame.dart';

class PushTypeDetailScreen extends StatelessWidget {
  const PushTypeDetailScreen({super.key});

  Future<void> _handlePushProcessing(BuildContext context, int pushId) async {
    try {
      final Map<String, dynamic> pushTypeDetail =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      int id = pushTypeDetail['PUSH_ID'];

      final url = Uri.parse('${UrlConstants.apiUrl}${UrlConstants.pushcheck}')
          .toString();
      final response = await HttpService.post(url, {'id': id});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['resultState'] == "Y") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "처리되었습니다.",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF004A99),
            ),
          );
          Navigator.pop(context, true); // 화면을 닫고 이전 화면에 처리 상태 전달
        } else {
          Util.showErrorAlert(data['resultMessage']);
        }
      } else {
        throw Exception("Failed to process notification");
      }
    } catch (e) {
      print("Error processing notification: $e");
      Util.showErrorAlert("처리 중 오류가 발생했습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> pushTypeDetail =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final bool isProcessable = pushTypeDetail['PUSH_CHK'] == false;

    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            '알림 상세',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF004A99),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Util.formatDate(pushTypeDetail['PUSH_SEND_DATE'] ?? ''),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pushTypeDetail['PUSH_TITLE'] ?? '알림 제목',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pushTypeDetail['PUSH_CONTENTS'] ??
                          '이곳에 알림의 상세 내용이 표시됩니다.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // "처리" 버튼
                    if (isProcessable)
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
                          onPressed: () {
                            _handlePushProcessing(
                                context, pushTypeDetail['PUSH_ID']);
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
