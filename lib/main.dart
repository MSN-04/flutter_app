// lib/main.dart
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:nk_app/Utils/util.dart';
import 'package:nk_app/pages/push_type_list.dart';
import 'package:nk_app/pages/push_type.dart';
import 'package:nk_app/pages/terms_agreement.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/url_constants.dart';
import 'firebase_options.dart';

import 'http/http_service.dart';
import 'pages/login.dart';
import 'pages/dashboard.dart';
import 'pages/push_type_detail.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int unreadCount = prefs.getInt('unread_notifications') ?? 0;
  unreadCount++; // 미확인 알림 개수 증가
  prefs.setInt('unread_notifications', unreadCount);

  // 앱 아이콘 배지 업데이트
  FlutterAppBadger.updateBadgeCount(unreadCount);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FCM 초기화 및 토큰 저장
  await initializeFCMToken();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeFCMToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  String? token = await messaging.getToken();
  if (token != null) {
    print("FCM Token: $token");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  } else {
    print("Failed to get FCM Token");
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // 미확인 알림 개수 증가
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int unreadCount = prefs.getInt('unread_notifications') ?? 0;
    unreadCount++;
    prefs.setInt('unread_notifications', unreadCount);

    updateBadge(unreadCount); // 앱 아이콘에 배지 업데이트

    handleMessage(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    navigatorKey.currentState?.pushNamed('/dashboard');
  });
}

Future<void> handleMessage(RemoteMessage message) async {
  bool confirmed = await Util.showConfirmDialog(
    navigatorKey.currentContext!,
    "${message.notification?.title}",
  );

  if (confirmed) {
    navigatorKey.currentState?.pushNamed('/dashboard');
  }
}

void updateBadge(int unreadCount) {
  if (unreadCount > 0) {
    FlutterAppBadger.updateBadgeCount(unreadCount);
  } else {
    FlutterAppBadger.removeBadge();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/terms': (context) => const TermsAgreementScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/push_type': (context) => const PushTypeScreen(),
        '/push_type_list': (context) => const PushTypeListScreen(),
        '/push_type_detail': (context) => const PushTypeDetailScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.containsKey('user');

    if (isLoggedIn) {
      await updateFCMTokenIfNeeded();
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    } else {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  Future<void> updateFCMTokenIfNeeded() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? newToken = await messaging.getToken();

    if (newToken != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? oldToken = prefs.getString('fcm_token');

      // 토큰이 없거나 변경된 경우에만 서버에 업데이트
      if (oldToken == null || oldToken != newToken) {
        await prefs.setString('fcm_token', newToken);

        // 서버에 FCM 토큰 업데이트 로직 추가
        await sendTokenToServer(newToken);
      }
    }
  }

  Future<bool> sendTokenToServer(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('fcm_token');

    if (token != null) {
      var url =
          Uri.parse(UrlConstants.apiUrl + UrlConstants.saveToken).toString();
      var response = await HttpService.post(url, {
        'id': userId,
        'token': token,
      });
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['resultState'] == "Y") {
          return true;
        } else {
          Util.showErrorAlert(data['resultMessage']);
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
