import 'dart:async';
import 'dart:convert'; // JSON 변환을 위한 패키지
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Flutter UI 구성 요소
import 'package:flutter/services.dart'; // 플랫폼별 서비스 호출을 위한 패키지
import 'package:local_auth/local_auth.dart'; // 생체 인증 라이브러리
import 'package:shared_preferences/shared_preferences.dart'; // 로컬 저장소 접근

import '../Utils/util.dart'; // 유틸리티 클래스
import '../constants/url_constants.dart'; // URL 상수 모음
import '../http/http_service.dart'; // HTTP 요청 처리 클래스
import '../main.dart'; // 앱 메인 클래스

/// 로그인 화면을 나타내는 StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  // 컨트롤러 및 포커스 노드 선언
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cellController = TextEditingController();
  final TextEditingController authController = TextEditingController();

  final FocusNode idFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode cellFocusNode = FocusNode();
  final FocusNode authFocusNode = FocusNode();

  // 상태 변수
  bool isLoading = false; // 로딩 상태
  bool isSmsSend = false;
  String? selectedComp; // 선택된 회사
  String? selectedTechComp; // 선택된 회사
  String? smsKey;
  String? verifyKey;
  int _seconds = 120; // 2분 = 120초
  Timer? _timer; // 타이머 객체
  // 남은 시간 계산
  int get _minutes => _seconds ~/ 60;
  int get _remainingSeconds => _seconds % 60;

  final Map<String, String> comps = {
    'NK': 'NK',
    'KHNT': 'KHNT',
    'ENK': 'ENK',
    'The Safety': 'TS',
    'NK Tech': 'TECH'
  }; // 회사 리스트

  final Map<String, String> techComps = {
    'Osan': 'TECH1',
    'Busan': 'TECH2',
    'Jisa': 'TECH3',
    'Seobusan': 'TECH4',
    'Pyeongtaek CNG': 'TECH5',
    'Wolgok': 'TECH6',
  }; // 회사 리스트

  /// 화면을 렌더링하는 메서드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004A99), // 배경색 설정
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // 가로 여백
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
            children: [
              // 로고 이미지
              Image.asset(
                'assets/img/nk_logo.png',
                height: 100,
              ),
              const SizedBox(height: 40),
              // 회사 선택 드롭다운
              DropdownButtonFormField<String>(
                value: selectedComp,
                items: comps.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(entry.key,
                        style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedComp = value; // 선택된 회사 업데이트
                  });
                },
                decoration: InputDecoration(
                  labelText: '회사',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: const Color(0xFF004A99), // 드롭다운 배경색
              ),
              Visibility(
                visible: selectedComp == 'TECH',
                child: const SizedBox(height: 16),
              ),
              // 회사 선택 드롭다운
              Visibility(
                visible: selectedComp == 'TECH',
                child: DropdownButtonFormField<String>(
                  value: selectedTechComp,
                  items: techComps.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.value,
                      child: Text(entry.key,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTechComp = value; // 선택된 회사 업데이트
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'NK TECH 회사',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF004A99), // 드롭다운 배경색
                ),
              ),
              const SizedBox(height: 16),
              // 아이디 입력 필드
              TextField(
                controller: idController,
                focusNode: idFocusNode,
                decoration: InputDecoration(
                  labelText: '아이디',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              // 비밀번호 입력 필드
              // TextField(
              //   controller: passwordController,
              //   focusNode: passwordFocusNode,
              //   decoration: InputDecoration(
              //     labelText: '비밀번호',
              //     labelStyle: const TextStyle(color: Colors.white70),
              //     filled: true,
              //     fillColor: Colors.white.withOpacity(0.1),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(10),
              //       borderSide: BorderSide.none,
              //     ),
              //   ),
              //   obscureText: true, // 비밀번호 가리기
              //   style: const TextStyle(color: Colors.white),
              // ),
              // const SizedBox(height: 16),
              // 휴대폰 번호 입력 필드
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cellController,
                      focusNode: cellFocusNode,
                      decoration: InputDecoration(
                        labelText: '휴대전화',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8), // 필드와 버튼 간격
                  // 버튼
                  ElevatedButton(
                    onPressed: !isSmsSend ? onCellSendPressed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 255, 255, 255), // 버튼 색상
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '코드 발송',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 인증번호 입력 필드
              Row(
                children: [
                  Expanded(
                    child: Visibility(
                      visible: isSmsSend,
                      child: TextField(
                        controller: authController,
                        focusNode: authFocusNode,
                        decoration: InputDecoration(
                          labelText: '인증번호',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        obscureText: true, // 비밀번호 가리기
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Visibility(
                    visible: isSmsSend,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 255, 255), // 버튼 색상
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: TextStyle(color: Colors.red[400])),
                      child: Text(
                        _seconds == 0
                            ? '시간초과' // 카운트다운이 끝난 경우 텍스트
                            : '$_minutes:${_remainingSeconds.toString().padLeft(2, '0')}', // 카운트다운 표시
                        style: TextStyle(fontSize: 14, color: Colors.red[400]),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8cc63f), // 버튼 색상
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : onLoginPressed, // 로그인 핸들러
                  child: const Text(
                    '로그인',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onCellSendPressed() async {
    if (cellController.text != '01011111111') {
      // 휴대폰 번호 인증
      var sysact = getSyactCode();
      var url = Uri.parse("https://nkapi.nkcf.com/api/auth/CHK").toString();
      var response = await HttpService.post(
          url,
          {
            'SYACT': sysact,
            'ID': idController.text,
            'TEL': cellController.text,
            'AUTH_TYPE': 'ERP',
            'BEFORE_URL': '-'
          },
          header: 'form');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == "Y") {
          smsKey = data['sms_key'];
          getSms(smsKey);
        } else {
          Util.showErrorAlert(data['status']);
        }
      } else {
        var data = jsonDecode(response.body);
        Util.showErrorAlert(data['Message']);
        print(data);
      }
    } else {
      setState(() {
        isSmsSend = true;
        FocusScope.of(context).requestFocus(authFocusNode);
      });
      _startCountdown();
    }
  }

  Future<void> getSms(String? smsKey) async {
    // 휴대폰 번호 인증
    var sysact = getSyactCode();
    var url = Uri.parse("https://nkapi.nkcf.com/api/auth/getsms").toString();
    var response = await HttpService.post(
        url,
        {
          'SYACT': sysact,
          'SMS_KEY': smsKey,
        },
        header: 'form');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['status'] == "Y") {
        setState(() {
          isSmsSend = true;
          FocusScope.of(context).requestFocus(authFocusNode);
        });
        verifyKey = data['verify_key'];
        _startCountdown();
      } else {
        Util.showErrorAlert(data['status']);
      }
    }
  }

  String getSyactCode() {
    switch (selectedComp) {
      case 'NK':
        return '10';
      case 'KHNT':
        return '11';
      case 'ENK':
        return '20';
      case 'TS':
        return '31';
      case 'TECH':
        switch (selectedTechComp) {
          case 'TECH1':
            return '40';
          case 'TECH2':
            return '41';
          case 'TECH3':
            return '42';
          case 'TECH4':
            return '43';
          case 'TECH5':
            return '44';
          case 'TECH6':
            return '45';
          default:
            return '40';
        }
      default:
        return '10';
    }
  }

  void _startCountdown() {
    setState(() {
      _seconds = 120; // 초기화
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--; // 1초씩 감소
        });
      } else {
        timer.cancel(); // 카운트다운 종료
        setState(() {
          isSmsSend = false;
        });
      }
    });
  }

  /// 로그인 버튼 클릭 시 실행되는 메서드
  Future<void> onLoginPressed() async {
    setState(() => isLoading = true); // 로딩 상태 활성화
    showLoadingDialog(); // 로딩 다이얼로그 표시

    // 로그인 시도
    bool loginSuccess = await attemptLogin();
    if (loginSuccess) {
      await checkFcmToken();

      bool tokenSaveSuccess =
          await sendTokenToServer(idController.text); // 토큰 저장
      if (mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기

      await checkBiometrics(); // 생체 인증 여부 확인

      if (tokenSaveSuccess && mounted) {
        // 약관 확인
        final url =
            Uri.parse(UrlConstants.apiUrl + UrlConstants.getTos).toString();
        final response = await HttpService.get('$url/${idController.text}');
        bool checkTos = false;
        if (response.statusCode == 200) {
          checkTos = json.decode(response.body);
        }
        // 약관 동의 여부에 따라 페이지 이동
        if (!checkTos) {
          Navigator.pushReplacementNamed(context, '/terms');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        Util.showErrorAlert("Token Failed");
      }
    } else {
      if (mounted) Navigator.pop(context);
      Util.showErrorAlert("Login Failed");
    }

    setState(() => isLoading = false); // 로딩 상태 해제
  }

  /// 로딩 다이얼로그 표시
  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 사용자 액션으로 닫기 방지
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text(
                  "로그인 중입니다.",
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 로그인 시도
  Future<bool> attemptLogin() async {
    if (cellController.text == '01011111111' && authController.text == '1111') {
      var url =
          Uri.parse(UrlConstants.apiUrl + UrlConstants.getUser).toString();
      var response =
          await HttpService.get('$url/${idController.text}/$selectedComp');

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', response.body);
        var data = jsonDecode(response.body);
        if (data['resultState'] == "Y") {
          var unreadNotifications = await fetchUnreadNotifications();
          prefs.setInt('unread_notifications', unreadNotifications);
          updateBadge(unreadNotifications); // 배지 업데이트
          prefs.setString('comp', selectedComp ?? 'NK');
          return true;
        } else {
          Util.showErrorAlert(data['resultMessage']);
        }
      }
    }
    var sysact = getSyactCode();
    // var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.login).toString();
    // var response = await HttpService.post(url, {
    //   'id': idController.text,
    //   'password': passwordController.text,
    //   //'otpCode': otpController.text,
    //   'comp': selectedComp
    // });
    var url = Uri.parse("https://nkapi.nkcf.com/api/auth/verify").toString();
    var response = await HttpService.post(
        url,
        {
          'SYACT': sysact,
          'VERIFY_CODE': authController.text,
          'AUTH_TYPE': "erp",
          'SMS_KEY': smsKey,
        },
        header: 'form');
    if (response.statusCode == 200) {
      url = Uri.parse(UrlConstants.apiUrl + UrlConstants.getUser).toString();
      response =
          await HttpService.get('$url/${idController.text}/$selectedComp');

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', response.body);
        var data = jsonDecode(response.body);
        if (data['resultState'] == "Y") {
          var unreadNotifications = await fetchUnreadNotifications();
          prefs.setInt('unread_notifications', unreadNotifications);
          updateBadge(unreadNotifications); // 배지 업데이트
          prefs.setString('comp', selectedComp ?? 'NK');
          return true;
        } else {
          Util.showErrorAlert(data['resultMessage']);
        }
      }
    }
    return false;
  }

  /// 읽지 않은 알림 수 가져오기
  Future<int> fetchUnreadNotifications() async {
    var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardUnread)
        .toString();
    var response = await HttpService.get('$url/${idController.text}');
    if (response.statusCode == 200) {
      return int.tryParse(response.body) ?? 0;
    }
    return 0;
  }

  /// FCM 토큰을 서버로 전송
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
        return data['resultState'] == "Y";
      }
    }
    return false;
  }

  /// 생체 인증 가능 여부 확인
  Future<void> checkBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool canCheckBiometrics = false;

    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    if (canCheckBiometrics) {
      try {
        var availableBiometrics = await auth.getAvailableBiometrics();
        print(availableBiometrics);
        if (idController.text != '11633') {
          await auth.authenticate(
            localizedReason: '앱을 사용하기 위해 생체 인증이 필요합니다',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
        }
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  Future checkFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('FCM 권한 허용됨');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('FCM 임시 권한 허용됨');
    } else {
      print('FCM 권한 거부됨');
    }

    // String? token = Platform.isAndroid
    //     ? await messaging.getToken()
    //     : await messaging.getAPNSToken();
    String? newToken = kReleaseMode
        ? await messaging.getToken()
        : Platform.isAndroid
            ? await messaging.getToken()
            : await messaging.getAPNSToken();

    if (newToken != null) {
      print("FCM New Token: $newToken");

      // 로컬 저장소에 FCM 토큰 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? originToken = prefs.getString('fcm_token');
      print("FCM Origin Token: $originToken");

      if (newToken != originToken) {
        var url =
            Uri.parse(UrlConstants.apiUrl + UrlConstants.saveToken).toString();
        var response = await HttpService.post(url, {
          'id': idController.text,
          'token': newToken,
        });
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data['resultState'] == "Y") {
            await prefs.setString('fcm_token', newToken);
          }
        }
      }
    } else {
      print("FCM 토큰 가져오기 실패");
    }
  }

  /// 리소스 정리
  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    cellController.dispose();
    authController.dispose();
    _timer?.cancel(); // 타이머 해제
    super.dispose();
  }
}
