import 'dart:convert'; // JSON 변환을 위한 패키지
import 'package:http/http.dart' as http; // HTTP 요청 처리를 위한 패키지

/// HTTP 요청 처리를 위한 공통 서비스 클래스
class HttpService {
  // HTTP 요청에 사용될 공통 헤더 설정
  static const Map<String, String> headers = {
    'Content-Type': 'application/json', // JSON 형식의 요청/응답을 위한 Content-Type 지정
  };

  static const Map<String, String> headersForm = {
    'Content-Type':
        'application/x-www-form-urlencoded', // JSON 형식의 요청/응답을 위한 Content-Type 지정
  };

  /// GET 요청 메서드
  ///
  /// [url] : 요청을 보낼 API의 URL
  ///
  /// 반환값: [http.Response]로 API 응답 반환
  static Future<http.Response> get(String url) async {
    try {
      // URL을 URI 형식으로 변환
      var uri = Uri.parse(url);

      // GET 요청을 보내고 응답을 기다림
      final response = await http.get(uri, headers: headers);

      // 요청 성공 시 응답 반환
      return response;
    } catch (e) {
      // 예외 발생 시 오류 메시지 출력 후 재발생
      print('GET Request Error: $e');
      rethrow;
    }
  }

  /// POST 요청 메서드
  ///
  /// [url] : 요청을 보낼 API의 URL
  /// [body] : 요청에 포함할 데이터 (Map 형식)
  ///
  /// 반환값: [http.Response]로 API 응답 반환
  static Future<http.Response> post(String url, Map<String, dynamic> body,
      {String? header}) async {
    try {
      // URL을 URI 형식으로 변환
      var uri = Uri.parse(url);

      final encodedBody;
      if (header == 'form') {
        encodedBody = body.entries
            .map((entry) =>
                '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
            .join('&');
      } else {
        encodedBody = jsonEncode(body);
      }

      // POST 요청을 보내고 응답을 기다림
      final response = await http
          .post(
            uri, // 요청 URL
            headers: header == 'form' ? headersForm : headers, // 공통 헤더 포함
            body: encodedBody, // 요청 데이터를 JSON 문자열로 변환
          )
          .timeout(const Duration(seconds: 5)); // 요청 제한 시간 설정 (필요 시 사용)

      // 요청 성공 시 응답 반환
      return response;
    } catch (e) {
      // 예외 발생 시 오류 메시지 출력 후 재발생
      print('POST Request Error: $e');
      rethrow;
    }
  }
}
