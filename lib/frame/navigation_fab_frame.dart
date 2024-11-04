// lib/components/navigation_fab_frame.dart
import 'package:flutter/material.dart';

class NavigationFABFrame extends StatelessWidget {
  final Widget child;

  const NavigationFABFrame({super.key, required this.child});

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
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('알림목록'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/notifications');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // 여기에 로그아웃 로직 추가 (예: Firebase Auth의 signOut 등)
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
      body: child,
    );
  }
}
