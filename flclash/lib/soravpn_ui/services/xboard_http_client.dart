import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/xboard_config.dart';

/// Xboard API 响应结构
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic)? fromJsonT, {
    bool useRawData = false,
  }) {
    // Xboard API 响应格式可能有两种:
    // 1. { status: "success/fail", message: "...", data: {...} }
    // 2. { data: [...] } (直接返回数据，没有 status 字段)
    final status = json['status'];

    // 如果没有 status 字段，但有 data 字段，认为是成功
    final bool success;
    if (status == null) {
      // 没有 status 字段，检查是否有 data
      success = json.containsKey('data');
    } else {
      success = status == 'success';
    }
    
    dynamic dataToParse;
    if (useRawData) {
      dataToParse = json;
    } else {
      dataToParse = json['data'];
    }

    return ApiResponse(
      success: success,
      message: json['message'] as String?,
      data: fromJsonT != null && dataToParse != null
          ? fromJsonT(dataToParse)
          : dataToParse as T?,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Xboard HTTP 客户端
/// 处理所有与 Xboard 后端的 HTTP 通信
class XboardHttpClient {
  static final XboardHttpClient _instance = XboardHttpClient._internal();
  factory XboardHttpClient() => _instance;
  XboardHttpClient._internal();

  String? _token;

  /// 获取当前 Token
  String? get token => _token;

  /// 设置 Token
  set token(String? value) => _token = value;

  /// 从本地存储加载 Token
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(XboardConfig.tokenKey);
    print('[XboardHttpClient] Token loaded: ${_token != null ? 'Yes' : 'No'}');
  }

  /// 保存 Token 到本地存储
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(XboardConfig.tokenKey, token);
    print('[XboardHttpClient] Token saved');
  }

  /// 清除 Token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(XboardConfig.tokenKey);
    print('[XboardHttpClient] Token cleared');
  }

  /// 获取请求头
  Map<String, String> _getHeaders({bool requiresAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    };

    if (requiresAuth && _token != null) {
      headers['Authorization'] = _token!;
    }

    return headers;
  }

  /// 将 Map 转换为 URL 编码的字符串
  String _encodeFormData(Map<String, dynamic> data) {
    return data.entries
        .where((e) => e.value != null)
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  /// 发送 GET 请求
  Future<ApiResponse<T>> get<T>(
    String url, {
    Map<String, dynamic>? params,
    bool requiresAuth = true,
    T? Function(dynamic)? fromJson,
    bool useRawData = false,
  }) async {
    try {
      // 构建 URL 带参数
      var uri = Uri.parse(url);
      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: params.map((k, v) => MapEntry(k, v?.toString() ?? '')));
      }

      print('[XboardHttpClient] GET $uri');

      final response = await http.get(
        uri,
        headers: _getHeaders(requiresAuth: requiresAuth),
      ).timeout(Duration(milliseconds: XboardConfig.requestTimeout));

      return _handleResponse(response, fromJson, useRawData: useRawData);
    } catch (e) {
      print('[XboardHttpClient] GET Error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// 发送 POST 请求
  Future<ApiResponse<T>> post<T>(
    String url, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
    T? Function(dynamic)? fromJson,
    bool useRawData = false,
  }) async {
    try {
      print('[XboardHttpClient] POST $url');
      print('[XboardHttpClient] Data: $data');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: data != null ? _encodeFormData(data) : null,
      ).timeout(Duration(milliseconds: XboardConfig.requestTimeout));

      return _handleResponse(response, fromJson, useRawData: useRawData);
    } catch (e) {
      print('[XboardHttpClient] POST Error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  /// 处理响应
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T? Function(dynamic)? fromJson, {
    bool useRawData = false,
  }) {
    print('[XboardHttpClient] Response status: ${response.statusCode}');
    print('[XboardHttpClient] Response body: ${response.body}');

    try {
      final json = jsonDecode(response.body);

      // 检查 HTTP 状态码
      if (response.statusCode == 401) {
        // Token 过期或无效
        clearToken();
        return ApiResponse.error('Unauthorized, please login again', statusCode: 401);
      }

      if (response.statusCode == 403) {
        return ApiResponse.error('Permission denied', statusCode: 403);
      }

      if (response.statusCode >= 500) {
        return ApiResponse.error('Server error', statusCode: response.statusCode);
      }

      // 解析 Xboard API 响应
      return ApiResponse.fromJson(json, fromJson, useRawData: useRawData);
    } catch (e) {
      print('[XboardHttpClient] Parse error: $e');
      return ApiResponse.error('Failed to parse response: $e', statusCode: response.statusCode);
    }
  }
}

/// 全局 HTTP 客户端实例
final xboardClient = XboardHttpClient();
