import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/util.dart';
import '../constants/url_constants.dart';
import '../frame/navigation_fab_frame.dart';
import '../http/http_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> pushs = [];
  bool isLoading = true;
  String unreadCnt = '0';
  String unCheckCnt = '0';
  String comp = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    userData = await loadUserData();
    if (userData != null) {
      pushs = await fetchPush(userData!);
    }

    setState(() => isLoading = false);
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    comp = prefs.getString('comp').toString();
    return userData != null ? jsonDecode(userData) : {};
  }

  Future<List<Map<String, dynamic>>> fetchPush(
      Map<String, dynamic> userData) async {
    final url =
        Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardList).toString();
    final response = await HttpService.get('$url/${userData['PSPSN_NO']}');

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      final url2 = Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardUnread)
          .toString();
      final response2 = await HttpService.get('$url2/${userData['PSPSN_NO']}');
      unreadCnt = response2.body;

      final url3 =
          Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardUnckeck)
              .toString();
      final response3 = await HttpService.get('$url3/${userData['PSPSN_NO']}');
      unCheckCnt = response3.body;

      return jsonData.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load push");
    }
  }

  Future<void> _refreshPushData() async {
    if (userData != null) {
      List<Map<String, dynamic>> updatedPushs = await fetchPush(userData!);
      setState(() {
        pushs = updatedPushs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : NavigationFABFrame(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          top: 50.0, left: 16.0, right: 16.0, bottom: 16.0),
                      color: const Color(0xFF004A99),
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                '${getPictureUrl()}${userData!['PSPSN_PICTURE'].toString()}',
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                          color: Colors.white,
                                          textBaseline:
                                              TextBaseline.ideographic),
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0), // Remove bottom padding here
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  const Text(
                                    '최근 알림',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Badge(
                                    label: Text(unreadCnt),
                                    backgroundColor: Colors.blueAccent,
                                    child: const Icon(Icons.mark_email_unread),
                                  ),
                                  const SizedBox(width: 8),
                                  Badge(
                                    label: Text(unCheckCnt),
                                    backgroundColor: Colors.redAccent,
                                    child: const Icon(Icons.report),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                                height:
                                    8), // Adjust this or remove if not needed
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refreshPushData,
                                child: pushs.isEmpty
                                    ? const Center(
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
                                        padding: EdgeInsets
                                            .zero, // Ensure no extra padding in the ListView
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
                                                style: TextStyle(
                                                  fontWeight:
                                                      push['PUSH_CHK'] == false
                                                          ? FontWeight.bold
                                                          : push['PUSH_READ'] ==
                                                                  false
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                ),
                                              ),
                                              subtitle: Text(
                                                push['PUSH_CONTENTS'] ??
                                                    '알림 내용',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight:
                                                      push['PUSH_CHK'] == false
                                                          ? FontWeight.bold
                                                          : push['PUSH_READ'] ==
                                                                  false
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                ),
                                              ),
                                              trailing: Text(
                                                Util.formatDate(
                                                    push['PUSH_SEND_DATE']),
                                                style: TextStyle(
                                                    color: Colors.grey[600]),
                                              ),
                                              onTap: () async {
                                                await Util
                                                    .markNotificationAsRead();
                                                await setPushRead(
                                                    push['PUSH_ID']);
                                                Navigator.pushNamed(
                                                  context,
                                                  '/push_type_detail',
                                                  arguments: push,
                                                ).then((_) {
                                                  setState(() {
                                                    push['PUSH_READ'] = true;
                                                  });
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
                    ),
                  ],
                ),
              ],
            ),
          );
  }

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
