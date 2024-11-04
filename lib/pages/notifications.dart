import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/util.dart';
import '../constants/url_constants.dart';
import '../frame/navigation_fab_frame.dart';
import '../http/http_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _page = 1;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeData() async {
    userData = await loadUserData();
    await _fetchNotifications();
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
      _fetchNotifications();
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    return userData != null ? jsonDecode(userData) : {};
  }

  Future<void> _fetchNotifications() async {
    if (userData == null) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          '${UrlConstants.apiUrl}${UrlConstants.pushListEndPoint}/${userData?['PSPSN_NO']}/$_page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> newNotifications = jsonDecode(response.body);
        setState(() {
          _notifications.addAll(newNotifications.cast<Map<String, dynamic>>());
          _page++;
        });
      } else {
        print("Failed to load notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '전체 알림 목록',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: const Color(0xFF004A99),
        ),
        body: ListView.builder(
          controller: _scrollController,
          itemCount: _notifications.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _notifications.length) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            var notification = _notifications[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: Icon(
                  Util.getIcon(notification['PUSH_ICON'] ?? 'null'),
                  color: notification['PUSH_READ'] == 'N'
                      ? Colors.blue
                      : Colors.grey,
                ),
                title: Text(
                  notification['PUSH_TITLE'] ?? '알림 제목',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: notification['PUSH_READ'] == 'N'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  notification['PUSH_CONTENTS'] ?? '알림 내용',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: notification['PUSH_READ'] == 'N'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  Util.formatDate(notification['PUSH_SEND_DATE']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: notification['PUSH_READ'] == 'N'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () async {
                  await Util.markNotificationAsRead();
                  await setPushRead(notification['PUSH_ID']);
                  Navigator.pushNamed(
                    context,
                    '/notificationDetail',
                    arguments: notification,
                  ).then((_) {
                    setState(() {
                      notification['PUSH_READ'] = 'Y';
                    });
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> setPushRead(int Id) async {
    print(Id);
    var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.pushReadEndPoint)
        .toString();
    print(url);
    var response = await HttpService.post(url, {'id': Id});
    print(response.statusCode);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print(data);
      if (data['resultState'] == "Y") {
        return true;
      } else {
        Util.showErrorAlert(data['resultMessage']);
      }
    }
    return false;
  }
}
