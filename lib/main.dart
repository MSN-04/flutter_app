import 'dart:convert'; // JSON 데이터 처리
import 'dart:io'; // 플랫폼 확인

import 'package:firebase_messaging/firebase_messaging.dart'; // FCM 푸시 알림
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Flutter UI
import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화
import 'package:flutter_app_badger/flutter_app_badger.dart'; // 앱 아이콘 배지 관리
import 'package:nk_push_app/Utils/util.dart'; // 유틸리티 클래스
import 'package:nk_push_app/pages/chat.dart';
import 'package:nk_push_app/pages/push_type_list.dart'; // 알림 리스트 화면
import 'package:nk_push_app/pages/push_type.dart'; // 알림 유형 화면
import 'package:nk_push_app/pages/terms_agreement.dart'; // 약관 동의 화면
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소
import 'constants/url_constants.dart'; // URL 상수
import 'firebase_options.dart'; // Firebase 옵션
import 'http/http_service.dart'; // HTTP 요청
import 'pages/login.dart'; // 로그인 화면
import 'pages/dashboard.dart'; // 대시보드 화면
import 'pages/push_type_detail.dart'; // 알림 상세 화면

/// 백그라운드 상태에서 FCM 메시지 처리
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화 확인
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: "nk-push-app-dev",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 로컬 저장소에서 읽지 않은 알림 개수 증가
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int unreadCount = prefs.getInt('unread_notifications') ?? 0;
  unreadCount++;
  prefs.setInt('unread_notifications', unreadCount);

  // 앱 아이콘 배지 업데이트
  FlutterAppBadger.updateBadgeCount(unreadCount);
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// 앱 실행 시작점
void main(List<String>? arguments) async {
  if (!Platform.isWindows) {
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      HttpOverrides.global = MyHttpOverrides();
    }

    // Firebase 초기화
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: "nk-push-app-dev",
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // FCM 토큰 초기화
    await initializeFCMToken();

    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } else {
    if (arguments != null && arguments.isNotEmpty) {
      final comp = arguments[0];
      final userId = arguments[1];
      await handleWindowsArgument(comp, userId);
    }
    print('Received arguments: $arguments');
  }

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// FCM 토큰 초기화 및 저장
Future<void> initializeFCMToken() async {
  // 포그라운드 메시지 수신 시 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int unreadCount = prefs.getInt('unread_notifications') ?? 0;
    unreadCount++;
    prefs.setInt('unread_notifications', unreadCount);

    updateBadge(unreadCount); // 앱 아이콘 배지 업데이트
    handleMessage(message); // 메시지 처리
  });

  // 메시지 클릭 시 대시보드로 이동
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    navigatorKey.currentState?.pushNamed('/dashboard');
  });
}

/// Windows Argument 처리
Future<void> handleWindowsArgument(String comp, String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // 전달받은 ID를 저장
  prefs.setString('erp_user_comp', comp);
  prefs.setString('erp_user_id', userId);
}

/// FCM 메시지 처리
Future<void> handleMessage(RemoteMessage message) async {
  String title = message.notification?.title ?? "";
  String body = message.notification?.body ?? "";

  // 만약 title에 '[채팅]'이 포함되어 있으면 title + body 표시
  String fullMessage = title.contains("[채팅]") ? "$title\n$body" : title;

  bool confirmed = await Util.showConfirmDialog(
    navigatorKey.currentContext!,
    fullMessage,
  );

  // 사용자가 확인을 눌렀을 경우 대시보드로 이동
  if (confirmed) {
    if (title.contains("[채팅]")) {
      navigatorKey.currentState?.pushNamed('/chat', arguments: title);
    } else {
      navigatorKey.currentState?.pushNamed('/dashboard');
    }
    ;
  }
}

/// 앱 아이콘 배지 업데이트
void updateBadge(int unreadCount) {
  if (unreadCount > 0) {
    FlutterAppBadger.updateBadgeCount(unreadCount);
  } else {
    FlutterAppBadger.removeBadge();
  }
}

/// 앱 메인 클래스
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'NK Push App',
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/terms': (context) => const TermsAgreementScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/push_type': (context) => const PushTypeScreen(),
        '/push_type_list': (context) => const PushTypeListScreen(),
        '/push_type_detail': (context) => const PushTypeDetailScreen(),
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}

/// 스플래시 화면: 초기 로딩 및 로그인 상태 확인
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // 로그인 상태 확인
  }

  /// 로그인 상태를 확인하고 적절한 화면으로 이동
  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Windows 플랫폼인 경우 ERP에서 전달받은 사용자 ID 기반으로 로그인 처리
    if (Platform.isWindows &&
        prefs.containsKey('erp_user_comp') &&
        prefs.containsKey('erp_user_id')) {
      String? comp = prefs.getString('erp_user_comp');
      String? userId = prefs.getString('erp_user_id');

      var url =
          Uri.parse(UrlConstants.apiUrl + UrlConstants.getUser).toString();
      var response =
          await HttpService.get('$url/$userId/${getSyactCode(comp!)}');

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', response.body);
        var data = jsonDecode(response.body);
        if (data['resultState'] == "Y") {
          prefs.setString('comp', getSyactCode(comp!) ?? 'NK');
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        } else {
          Util.showErrorAlert(data['resultMessage']);
        }
      }
    } else {
      bool isLoggedIn = prefs.containsKey('user');

      if (isLoggedIn) {
        await updateFCMTokenIfNeeded();
        Future.microtask(() {
          Navigator.pushReplacementNamed(context, '/dashboard'); // 대시보드로 이동
        });
      } else {
        Future.microtask(() {
          Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
        });
      }
    }
  }

  /// FCM 토큰 업데이트가 필요한 경우 서버에 토큰 전송
  Future<void> updateFCMTokenIfNeeded() async {
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? newToken = kReleaseMode
          ? await messaging.getToken()
          : Platform.isAndroid
              ? await messaging.getToken()
              : await messaging.getAPNSToken();

      if (newToken != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? oldToken = prefs.getString('fcm_token');

        if (oldToken == null || oldToken != newToken) {
          await prefs.setString('fcm_token', newToken);
          await sendTokenToServer(newToken); // 서버에 토큰 업데이트
        }
      }
    }
  }

  /// 서버에 FCM 토큰 전송
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
          Util.showErrorAlert(data['resultMessage']); // 오류 메시지 표시
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()), // 로딩 상태 표시
    );
  }

  String getSyactCode(String comp) {
    switch (comp) {
      case '10':
        return 'NK';
      case '11':
        return 'KHNT';
      case '20':
        return 'ENK';
      case '31':
        return 'TS';
      case '40':
        return 'TECH1';
      case '41':
        return 'TECH2';
      case '42':
        return 'TECH3';
      case '43':
        return 'TECH4';
      case '44':
        return 'TECH5';
      case '45':
        return 'TECH6';
      default:
        return 'NK';
    }
  }
}
