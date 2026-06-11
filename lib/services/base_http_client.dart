import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../app_constants/app_constants.dart';
import 'app_exceptions.dart';
import 'auth_http_client.dart';

class BaseHttpClient {
  static const int TIME_OUT_DURATION = 800; // Changed from 800 to 30 seconds
  static const BASE_URL = AppConstants.VIMBIKA_BACKEND_URL;

  //GET
  Future<dynamic> get(String api) async {
    var uri = Uri.parse(BASE_URL + api);
    try {
      print(uri.toString());
      var response = await http.get(uri).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<http.Response> getRaw(String api) async {
    var uri = Uri.parse(BASE_URL + api);
    try {
      print(uri.toString());
      var response = await http.get(uri).timeout(Duration(seconds: TIME_OUT_DURATION));
      return response;
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<http.Response> getAuthRaw(String api) async {
    var uri = Uri.parse(BASE_URL + api);
    var httpClient = AuthenticatedHttpClient();
    try {
      var response = await httpClient.get(uri).timeout(Duration(seconds: TIME_OUT_DURATION));
      return response;
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<dynamic> getNoBaseUrl(String api) async {
    var uri = Uri.parse(api);
    try {
      var response = await http.get(uri).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<dynamic> getAuth(String api) async {
    var uri = Uri.parse(BASE_URL + api);
    var httpClient = AuthenticatedHttpClient();
    try {
      var response = await httpClient.get(uri).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<dynamic> getAuthWithCompanyHeader(String api, String companyId) async {
    var uri = Uri.parse(BASE_URL + api);
    var httpClient = AuthenticatedHttpClient();
    try {
      var fullUri = uri.toString();
      if (fullUri.contains('?')) {
        uri = Uri.parse(fullUri);
      }
      print(uri);
      var response = await httpClient.get(uri, headers: {"Company": companyId}).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<dynamic> postAuthWithCompanyHeader(String api, dynamic payloadObj, String companyId, String method) async {
    var uri = Uri.parse(BASE_URL + api);
    var httpClient = AuthenticatedHttpClient();
    print(uri.toString());
    try {
      var response;
      if (method == "POST") {
        response = await httpClient.post(uri, body: payloadObj, headers: {"Content-Type": "application/json", "Company": companyId}).timeout(Duration(seconds: TIME_OUT_DURATION));
      } else {
        response = await httpClient.put(uri, body: payloadObj, headers: {"Content-Type": "application/json", "Company": companyId}).timeout(Duration(seconds: TIME_OUT_DURATION));
      }
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  //POST
  Future<dynamic> post(String api, dynamic payload) async {
    var uri = Uri.parse(BASE_URL + api);
    print(uri.toString());
    try {
      var response = await http.post(uri, body: payload, headers: {"Content-Type": "application/json"}).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<dynamic> postAuth(String api, dynamic payloadObj) async {
    var uri = Uri.parse(BASE_URL + api);
    var httpClient = AuthenticatedHttpClient();
    try {
      var response = await httpClient.post(uri, body: payloadObj).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    print(response.body.toString());
    print(response.statusCode.toString());
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.bodyBytes.isEmpty) {
          return '{}'; // Return an empty JSON object string for empty bodies
        }
        return utf8.decode(response.bodyBytes);
      case 400:
        throw BadRequestException(utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 401:
      case 403:
        throw UnAuthorizedException(utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 422:
        throw BadRequestException(utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 500:
      default:
        throw FetchDataException('Error occurred with code : ${response.statusCode}', response.request!.url.toString());
    }
  }
}
