import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/util.dart';
import '../constants/url_constants.dart';
import '../frame/navigation_fab_frame.dart';
import '../http/http_service.dart';

class PushTypeListScreen extends StatefulWidget {
  const PushTypeListScreen({super.key});

  @override
  PushTypeListScreenState createState() => PushTypeListScreenState();
}

class PushTypeListScreenState extends State<PushTypeListScreen> {
  final List<Map<String, dynamic>> _pushTypeList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isRefreshing = false;
  int _page = 1;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? pushTypeData;

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    userData = await loadUserData();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    pushTypeData = args;
    await _fetchPushTypeList();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchPushTypeList() async {
    String? typeCode = pushTypeData?['TYPE_CODE_M'];
    String? typeSubCode = pushTypeData?['TYPE_CODE_D'];
    if (userData == null || typeCode == null || typeSubCode == null) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          '${UrlConstants.apiUrl}${UrlConstants.push}/$typeCode/$typeSubCode/${userData?['PSPSN_NO']}/$_page');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> newPushTypeList = jsonDecode(response.body);
        setState(() {
          _pushTypeList.addAll(newPushTypeList.cast<Map<String, dynamic>>());
          _page++;
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

  Future<void> _refreshPushTypeList() async {
    if (_isLoading) return;

    setState(() {
      _isRefreshing = true;
      _pushTypeList.clear();
      _page = 1;
    });
    await _fetchPushTypeList();
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
      _fetchPushTypeList();
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    return userData != null ? jsonDecode(userData) : {};
  }

  List<Map<String, dynamic>> _applyFilter() {
    if (_selectedFilter == 'Unread') {
      return _pushTypeList.where((item) => item['PUSH_READ'] == false).toList();
    } else if (_selectedFilter == 'Unchecked') {
      return _pushTypeList.where((item) => item['PUSH_CHK'] == false).toList();
    } else {
      return _pushTypeList;
    }
  }

  @override
  Widget build(BuildContext context) {
    String typeName = pushTypeData?['TYPE_NAME_D'] ?? '알림 목록';

    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                typeName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              // 추가: 오른쪽 정렬을 위해 Align을 사용하여 DropdownButton을 감쌈
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF004A99),
                    underline: Container(),
                    value: _selectedFilter,
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
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF004A99),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshPushTypeList,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            _applyFilter().length + (_isRefreshing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _applyFilter().length && _isRefreshing) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
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
                              subtitle: Text(
                                push['PUSH_CONTENTS'] ?? '알림 내용',
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
                              trailing: Text(
                                Util.formatDate(push['PUSH_SEND_DATE']),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: push['PUSH_CHK'] == false
                                      ? FontWeight.bold
                                      : push['PUSH_READ'] == false
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              onTap: () async {
                                await Util.markNotificationAsRead();
                                await setPushRead(push['PUSH_ID']);
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
}
