// lib/notification_detail_screen.dart
import 'package:flutter/material.dart';

import '../Utils/util.dart';
import '../frame/navigation_fab_frame.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> notificationDetail =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

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
                      Util.formatDate(
                          notificationDetail['PUSH_SEND_DATE'] ?? ''),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notificationDetail['PUSH_TITLE'] ?? '알림 제목',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      notificationDetail['PUSH_CONTENTS'] ??
                          '이곳에 알림의 상세 내용이 표시됩니다.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black54,
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
