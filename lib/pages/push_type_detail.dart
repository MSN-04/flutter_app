// lib/notification_detail_screen.dart
import 'dart:convert'; // JSON 변환을 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 구성 요소
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:html/parser.dart';
import 'package:nk_push_app/http/http_service.dart'; // HTTP 요청 처리 클래스
import 'package:flutter_html/flutter_html.dart'; // HTML 렌더링을 위한 패키지
import 'package:url_launcher/url_launcher.dart';

import '../Utils/util.dart'; // 유틸리티 클래스
import '../constants/url_constants.dart'; // URL 상수 모음
import '../frame/navigation_fab_frame.dart'; // 공통 프레임 위젯

class PushTypeDetailScreen extends StatefulWidget {
  const PushTypeDetailScreen({super.key});

  @override
  State<PushTypeDetailScreen> createState() => _PushTypeDetailScreenState();
}

class _PushTypeDetailScreenState extends State<PushTypeDetailScreen> {
  final GlobalKey _htmlKey = GlobalKey();
  final ScrollController _horizontalScrollController = ScrollController();
  double _calculatedWidth = 0.0;
  bool _isHtmlRendered = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _calculateRenderedWidth() async {
    if (_horizontalScrollController.hasClients) {
      final double maxScrollableExtent =
          _horizontalScrollController.position.maxScrollExtent;
      final double screenWidth = MediaQuery.of(context).size.width;

      final RenderBox? renderBox =
          _htmlKey.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null) {
        if (renderBox.size.width + 10 > _calculatedWidth) {
          setState(() {
            _calculatedWidth = maxScrollableExtent > 0
                ? screenWidth + maxScrollableExtent
                : screenWidth;
          });
        }
      }
    }
  }

  Future<void> _handlePushProcessing(BuildContext context, int pushId) async {
    try {
      // 전달된 알림 상세 정보를 가져옴
      final Map<String, dynamic> pushTypeDetail =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      int id = pushTypeDetail['PUSH_ID'];

      // 알림 처리 API 호출
      final url = Uri.parse('${UrlConstants.apiUrl}${UrlConstants.pushcheck}')
          .toString();
      final response = await HttpService.post(url, {'id': id});

      // API 호출 성공 시 처리 결과에 따른 행동 수행
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['resultState'] == "Y") {
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "처리되었습니다.",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF004A99),
            ),
          );
          Navigator.pop(context, true); // 이전 화면으로 처리 상태 전달
        } else {
          // 실패 메시지 표시
          Util.showErrorAlert(data['resultMessage']);
        }
      } else {
        throw Exception("Failed to process notification");
      }
    } catch (e) {
      // 예외 처리
      print("Error processing notification: $e");
      Util.showErrorAlert("처리 중 오류가 발생했습니다.");
    }
  }

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> pushTypeDetail =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // 알림이 처리 가능한 상태인지 확인
    final bool isProcessable = pushTypeDetail['PUSH_CHK'] == false;

    return NavigationFABFrame(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            '알림 상세',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF004A99),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await Future.delayed(Duration(seconds: 2));
                      final RenderBox? renderBox = _htmlKey.currentContext
                          ?.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        final RenderBox? renderBox = _htmlKey.currentContext
                            ?.findRenderObject() as RenderBox?;

                        // print('현재 크기: $_calculatedWidth');
                        // print('renderBox 크기  ${renderBox?.size.width}');
                        // print(
                        //     '추가스크롤 크기  ${_horizontalScrollController.position.maxScrollExtent}');
                        // print(
                        //     'context 크기  ${MediaQuery.of(context).size.width}');
                        // print("가로 스크롤 최대 크기: $_calculatedWidth");

                        // setState(() {});
                      }
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Util.formatDate(
                              pushTypeDetail['PUSH_SEND_DATE'] ?? ''),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pushTypeDetail['PUSH_TITLE'] ?? '알림 제목',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 400, // 최소 너비 조정
                                ),
                                child: Html(
                                  key: _htmlKey,
                                  data: pushTypeDetail['PUSH_CONTENTS'] ?? '',
                                  extensions: const [TableHtmlExtension()],
                                  style: {
                                    "table": Style(
                                      //width: Width(100, Unit.percent),
                                      // border: Border.all(color: Colors.grey),
                                      padding: HtmlPaddings.all(8),
                                      whiteSpace: WhiteSpace.pre,
                                    ),
                                    "th": Style(
                                      border: Border.all(color: Colors.grey),
                                      backgroundColor: Colors.grey[300],
                                      padding: HtmlPaddings.all(8),
                                      whiteSpace: WhiteSpace.pre,
                                    ),
                                    "td": Style(
                                      border: Border.all(color: Colors.grey),
                                      padding: HtmlPaddings.all(8),
                                      whiteSpace: WhiteSpace.pre,
                                    ),
                                    "ul": Style(
                                      padding: HtmlPaddings.all(10),
                                      margin: Margins.all(10),
                                      listStyleType: ListStyleType.disc,
                                      display: Display.block,
                                    ),
                                    "li": Style(
                                        padding: HtmlPaddings.all(5),
                                        fontSize: FontSize.large,
                                        color: Colors.black,
                                        display: Display.block,
                                        whiteSpace:
                                            WhiteSpace.normal, // 자동 줄 바꿈
                                        margin: Margins.only(bottom: 5)),
                                  },
                                  onLinkTap: (url, _, __) {
                                    if (url != null) {
                                      _openLink(url);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isProcessable)
                          SizedBox(
                            width: double.infinity, // 버튼 너비를 화면에 맞춤
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // 버튼 색상
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8), // 버튼 모서리 둥글기
                                ),
                              ),
                              onPressed: () {
                                _handlePushProcessing(context,
                                    pushTypeDetail['PUSH_ID']); // 버튼 클릭 시 알림 처리
                              },
                              child: const Text(
                                "처리 완료",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
