import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  _TermsAgreementScreenState createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool isScrolledToEnd1 = false;
  bool isScrolledToEnd2 = false;
  bool isChecked1 = false;
  bool isChecked2 = false;

  void _submitAgreement() async {
    Navigator.pushReplacementNamed(context, '/dashboard');
    // 동의 내용을 API로 전송 (가상 요청)
    bool success = await _sendAgreementData();
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("동의 저장 실패")));
    }
  }

  Future<bool> _sendAgreementData() async {
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  Future<void> _rejectAgreement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("user");
    prefs.remove("comp");
    // 로그인 데이터 삭제 후 로그인 페이지로 이동
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '약관 동의',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF004A99),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildAgreementSection(
                    "약관 1",
                    "약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다.약관 1 내용입니다. 약관의 내용이 길어질 경우 스크롤이 적용됩니다...",
                    isScrolledToEnd1,
                    (value) {
                      setState(() {
                        isScrolledToEnd1 = value;
                      });
                    },
                    (value) {
                      setState(() {
                        isChecked1 = value!;
                      });
                    },
                    isChecked1,
                  ),
                  SizedBox(height: 16),
                  _buildAgreementSection(
                    "약관 2",
                    "약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다.약관 2 내용입니다. 이곳 역시 스크롤이 적용됩니다...",
                    isScrolledToEnd2,
                    (value) {
                      setState(() {
                        isScrolledToEnd2 = value;
                      });
                    },
                    (value) {
                      setState(() {
                        isChecked2 = value!;
                      });
                    },
                    isChecked2,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (isChecked1 && isChecked2) ? _submitAgreement : null,
                child: const Text(
                  "동의합니다.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _rejectAgreement,
                child: const Text(
                  "동의하지 않습니다.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementSection(
    String title,
    String content,
    bool isScrolledToEnd,
    Function(bool) onScrollEnd,
    Function(bool?) onCheckboxChanged,
    bool isChecked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity, // 화면 너비를 가득 채움
          height: 200, // 고정 높이
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 179, 179, 179)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
                onScrollEnd(true);
              }
              return true;
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(content),
              ),
            ),
          ),
        ),
        if (isScrolledToEnd)
          Row(
            children: [
              Checkbox(
                value: isChecked,
                onChanged: onCheckboxChanged,
              ),
              Text("동의합니다"),
            ],
          ),
      ],
    );
  }
}
