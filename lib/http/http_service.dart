import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  // 공통 헤더 설정
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  static Future<http.Response> get(String url) async {
    try {
      var uri = Uri.parse(url);
      final response = await http.get(uri, headers: headers);
      return response;
    } catch (e) {
      print('GET Request Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> post(
      String url, Map<String, dynamic> body) async {
    try {
      var uri = Uri.parse(url);
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5)); // 필요한 경우 타임아웃 설정
      return response;
    } catch (e) {
      print('POST Request Error: $e');
      rethrow;
    }
  }
}
