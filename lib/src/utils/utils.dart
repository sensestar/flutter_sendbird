import 'package:http/http.dart' as http;
import 'dart:async';
import "dart:convert";

Map<String, String> _HEADER = {
  "Content-Type": "application/json, charset=utf8",
};

final _baseUrl = "https://api.sendbird.com";

Future<http.Response> get(String api, Map<String, dynamic> params) async {
  var baseUrl = _baseUrl;
  var dest = Uri.parse("$baseUrl$api");
  dest = dest.replace(queryParameters: params);
  final url = dest.toString();
  return http.get(url, headers: _HEADER);
}

Future<http.Response> delete(String api, Map<String, dynamic> params) async {
  var baseUrl = _baseUrl;
  var dest = Uri.parse("$baseUrl$api");
  dest = dest.replace(queryParameters: params);
  final url = dest.toString();
  return http.delete(url, headers: _HEADER);
}

Future<http.Response> post(String api, Map<String, dynamic> params) async {
  return http.post("$_baseUrl$api", body: jsonEncode(params), headers: _HEADER);
}

Future<http.Response> patch(String api, Map<String, dynamic> params) async {
  return http.patch("$_baseUrl$api", body: jsonEncode(params), headers: _HEADER);
}

Future<http.Response> put(String api, Map<String, dynamic> params) async {
  return http.put("$_baseUrl$api", body: jsonEncode(params), headers: _HEADER);
}
