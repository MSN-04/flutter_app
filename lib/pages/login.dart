import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/util.dart';
import '../constants/url_constants.dart';
import '../http/http_service.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final FocusNode idFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode otpFocusNode = FocusNode();

  bool isLoading = false;
  String? selectedComp;
  final Map<String, String> comps = {
    'NK': 'NK',
    'KHNT': 'KHNT',
    'ENK': 'ENK',
    'TS': 'The Safety',
    'TECH': 'NK Tech'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004A99),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/img/nk_logo.png',
                height: 100,
              ),
              const SizedBox(height: 40),
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
                    selectedComp = value;
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
                dropdownColor: const Color(
                    0xFF004A99), // Background color for dropdown items
              ),
              const SizedBox(height: 16),
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
              TextField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                focusNode: otpFocusNode,
                decoration: InputDecoration(
                  labelText: 'OTP CODE(6자리)',
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8cc63f),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : onLoginPressed,
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

  Future<void> onLoginPressed() async {
    setState(() => isLoading = true);
    showLoadingDialog();

    bool loginSuccess = await attemptLogin();
    if (loginSuccess) {
      bool tokenSaveSuccess = await sendTokenToServer(idController.text);
      if (mounted) Navigator.pop(context);

      await checkBiometrics();

      if (tokenSaveSuccess && mounted) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? tosAgreeDate = prefs.getString("tosAgreeDate");
        DateTime agreeDate = DateTime.now();
        if (tosAgreeDate != null) {
          agreeDate = DateTime.parse(tosAgreeDate);
        } else {
          // 기본값 설정 또는 예외 처리
          print("No date found in SharedPreferences.");
        }

        var dif = const Duration(days: 365);
        if (DateTime.now().difference(agreeDate) >= dif) {
          Navigator.pushReplacementNamed(context, '/terms');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
        ;
      } else {
        Util.showErrorAlert("Token Failed");
      }
    } else {
      if (mounted) Navigator.pop(context);
      Util.showErrorAlert("Login Failed");
    }

    setState(() => isLoading = false);
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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

  Future<bool> attemptLogin() async {
    var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.login).toString();
    var response = await HttpService.post(url, {
      'id': idController.text,
      'password': passwordController.text,
      'otpCode': otpController.text,
      'comp': selectedComp
    });
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', response.body);
      var data = jsonDecode(response.body);
      if (data['resultState'] == "Y") {
        var unreadNotifications = await fetchUnreadNotifications();
        prefs.setInt('unread_notifications', unreadNotifications);
        updateBadge(unreadNotifications); // 앱 아이콘에 배지 표시

        prefs.setString('comp', selectedComp ?? 'NK');
        return true;
      } else {
        Util.showErrorAlert(data['resultMessage']);
      }
    }
    return false;
  }

  Future<int> fetchUnreadNotifications() async {
    var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.dashboardUnread)
        .toString();
    var response = await HttpService.get('$url/${idController.text}');
    if (response.statusCode == 200) {
      int data = int.tryParse(response.body) ?? 0;
      return data;
    }
    return 0;
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

//테스트
  Future<void> checkBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics;

    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    if (canCheckBiometrics) {
      try {
        availableBiometrics = await auth.getAvailableBiometrics();
        print(availableBiometrics);
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
