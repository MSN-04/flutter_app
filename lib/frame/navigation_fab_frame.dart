// lib/components/navigation_fab_frame.dart
import 'package:flutter/material.dart';
import 'package:nk_app/Utils/util.dart';
import 'package:nk_app/constants/url_constants.dart';
import 'dart:convert';

import 'package:nk_app/http/http_service.dart';

class NavigationFABFrame extends StatefulWidget {
  final Widget child;

  const NavigationFABFrame({super.key, required this.child});

  @override
  _NavigationFABFrameState createState() => _NavigationFABFrameState();
}

class _NavigationFABFrameState extends State<NavigationFABFrame> {
  List<Map<String, dynamic>> menus = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingTasks(); // 데이터 가져오기
  }

  Future<void> _fetchPendingTasks() async {
    try {
      final url = Uri.parse(UrlConstants.apiUrl + UrlConstants.menu).toString();
      final response = await HttpService.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          menus =
              decodedData.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        width: 300,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 120,
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF004A99)),
                child: Center(
                  child: Image.asset(
                    'assets/img/nk_logo.png',
                    height: 25,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('대시보드'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ...menus.map((menu) {
              return ListTile(
                leading: Icon(Util.getIcon(menu['TYPE_ICON'] ?? 'null')),
                title: Text(menu['TYPE_NAME']),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/push_type',
                      arguments: {
                        'typeCode': menu['TYPE_CODE'],
                        'typeName': menu['TYPE_NAME'],
                        'typeIcon': menu['TYPE_ICON']
                      });
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (BuildContext context) {
          return FloatingActionButton(
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            child: const Icon(Icons.menu),
            backgroundColor: const Color(0xFF8cc63f),
          );
        },
      ),
      body: widget.child,
    );
  }
}
