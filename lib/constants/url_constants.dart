import 'dart:io';

import 'package:flutter/foundation.dart';

class UrlConstants {
  // 기본 URL (Windows 개발 환경)
  static const String _windowsUrl = "https://localhost:7030";
  static const String _windowsApiUrl = "https://localhost:7030/api";

  // 안드로이드용 URL
  static const String _androidUrl = "https://10.0.2.2:7030";
  static const String _androidApiUrl = "https://10.0.2.2:7030/api";

  // 프로덕션 URL
  static const String _prodUrl = "https://pushapp.nkcf.com";
  static const String _prodApiUrl = "https://pushapp.nkcf.com/api";

  // ✅ 현재 실행 중인 환경에 따라 URL 자동 반환
  static String get url {
    if (kDebugMode && Platform.isAndroid) {
      return _androidUrl;
    } else if (kDebugMode && Platform.isWindows) {
      return _windowsUrl; // Windows, iOS 등 기본값
    } else {
      return _prodUrl;
    }
  }

  static String get apiUrl {
    if (kDebugMode && Platform.isAndroid) {
      return _androidApiUrl;
    } else if (kDebugMode && Platform.isWindows) {
      return _windowsApiUrl; // Windows, iOS 등 기본값
    } else {
      return _prodApiUrl;
    }
  }

  static const String login = "/Login";
  static const String saveTos = "/Login/tos";
  static const String getTos = "/Login/tos";
  static const String getUser = "/Login/user";

  static const String saveToken = "/Token";

  static const String menu = "/Menu";

  static const String dashboardList = "/Dashboard";
  static const String dashboardUnread = "/Dashboard/unread";
  static const String dashboardUnckeck = "/Dashboard/uncheck";

  static const String push = "/Push";
  static const String pushDoRead = "/Push/read";
  static const String pushRead = "/Push/read";
  static const String pushcheck = "/Push/check";

  static const int timeoutDuration = 5000; // milliseconds
  static const String pictureUrl = "https://ep.nkspe.com";
}
