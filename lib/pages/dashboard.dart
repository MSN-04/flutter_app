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
    return userData != null ? jsonDecode(userData) : {};
  }

  Future<List<Map<String, dynamic>>> fetchPush(
      Map<String, dynamic> userData) async {
    final url =
        Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardPushEndPoint)
            .toString();
    final response = await HttpService.get('$url/${userData['PSPSN_NO']}');

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
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
                                '${UrlConstants.fileDownloadUrl}?COMP_ID=${userData!['COMP_ID']}&SYBSN_CODE=${userData!['SYUSR_BSN_CODE']}&ATCH_BSN_TYP=PSPSN&ATCH_DATA_KEY=${userData!['PSPSN_NO']}&ATCH_DATA_SEQ=1&WIDTH=119&HEIGHT=159',
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
                        padding: const EdgeInsets.only(
                            top: 15.0, left: 12.0, right: 12.0, bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '읽지 않은 알림',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Badge(
                                  label: Text(pushs.length.toString()),
                                  child: const Icon(Icons.notifications),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refreshPushData,
                                child: ListView.builder(
                                  itemCount: pushs.length,
                                  itemBuilder: (context, index) {
                                    var push = pushs[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: ListTile(
                                        leading: Icon(
                                          Util.getIcon(
                                              push['PUSH_ICON'] ?? 'null'),
                                          color: push['PUSH_READ'] == 'N'
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                        title: Text(
                                          push['PUSH_TITLE'] ?? '알림 제목',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: push['PUSH_READ'] == 'N'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(
                                          push['PUSH_CONTENTS'] ?? '알림 내용',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: push['PUSH_READ'] == 'N'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: Text(
                                          Util.formatDate(
                                              push['PUSH_SEND_DATE']),
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                        onTap: () async {
                                          await Util.markNotificationAsRead();
                                          await setPushRead(push['PUSH_ID']);
                                          Navigator.pushNamed(
                                            context,
                                            '/notificationDetail',
                                            arguments: push,
                                          ).then((_) {
                                            setState(() {
                                              push['PUSH_READ'] = 'Y';
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
    var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.pushReadEndPoint)
        .toString();
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
}
