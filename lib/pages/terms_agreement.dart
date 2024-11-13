import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nk_app/Utils/util.dart';
import 'package:nk_app/constants/url_constants.dart';
import 'package:nk_app/http/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  _TermsAgreementScreenState createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  List<bool> isScrolledToEndList = [];
  List<bool> isCheckedList = [];
  List<dynamic> termsList = [];
  List<int> tosIdList = [];
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchTerms();
  }

  Future<void> _fetchTerms() async {
    try {
      var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.getTos);
      var response = await HttpService.get(url.toString());
      if (response.statusCode == 200) {
        termsList = jsonDecode(response.body);
        for (var term in termsList) {
          tosIdList.add(term['TOS_ID']);
        }
        setState(() {
          isScrolledToEndList = List<bool>.filled(termsList.length, false);
          isCheckedList = List<bool>.filled(termsList.length, false);
        });
      } else {
        Util.showErrorAlert("Failed to load terms");
      }
    } catch (e) {
      Util.showErrorAlert("Error loading terms: $e");
    }
  }

  void _submitAgreement() async {
    bool success = await _sendAgreementData();
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("동의 저장 실패")));
      _rejectAgreement();
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');
    return userData != null ? jsonDecode(userData) : {};
  }

  Future<bool> _sendAgreementData() async {
    var url = Uri.parse(UrlConstants.apiUrl + UrlConstants.saveTos).toString();
    userData = await loadUserData();
    var response = await HttpService.post(url, {
      'userId': userData?['PSPSN_NO'],
      'tosId': tosIdList,
      'termYn': isCheckedList.every((isChecked) => isChecked),
    });
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

  Future<void> _rejectAgreement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("user");
    prefs.remove("comp");
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
        child: termsList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: termsList.length,
                      itemBuilder: (context, index) => _buildAgreementSection(
                        termsList[index]['TOS_TITLE'] ?? "약관 ${index + 1}",
                        termsList[index]['TOS_BODY'] ?? "",
                        isScrolledToEndList[index],
                        (value) {
                          setState(() {
                            isScrolledToEndList[index] = value;
                          });
                        },
                        (value) {
                          setState(() {
                            isCheckedList[index] = value!;
                          });
                        },
                        isCheckedList[index],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      onPressed: isCheckedList.every((isChecked) => isChecked)
                          ? _submitAgreement
                          : null,
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
                  const SizedBox(height: 16),
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 179, 179, 179)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use Future.microtask to set the scrolled-to-end status if content is too short
              Future.microtask(() {
                if (content.length < constraints.maxHeight ~/ 20) {
                  // Assume 20 pixels per line as a rough height
                  onScrollEnd(true);
                }
              });

              return NotificationListener<ScrollNotification>(
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
              );
            },
          ),
        ),
        if (isScrolledToEnd)
          Row(
            children: [
              Checkbox(
                value: isChecked,
                onChanged: onCheckboxChanged,
              ),
              const Text("동의합니다"),
            ],
          ),
      ],
    );
  }
}
