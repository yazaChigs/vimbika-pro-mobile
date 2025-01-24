import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'app_exceptions.dart';
import 'auth_http_client.dart';

class BaseHttpClient {
  static const int TIME_OUT_DURATION = 400;
  static const BASE_URL = AppConstants.VIMBIKA_BACKEND_URL;
  //GET
  Future<dynamic> get(String api) async {
    var uri = Uri.parse(BASE_URL + api);
    try {
      var response = await http.get(uri).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
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
      var response = await httpClient.get(uri, headers: {"Company":companyId}).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }
  Future<dynamic> postAuthWithCompanyHeader(String api, dynamic payloadObj, String companyId) async {
    var uri = Uri.parse(BASE_URL + api);
    print(uri);
    // String jsonPayload = jsonEncode(payloadObj);
    var httpClient = AuthenticatedHttpClient();
    try {
      var response = await httpClient.post(uri, body: payloadObj, headers: { "Content-Type": "application/json","Company":companyId}).timeout(Duration(seconds: TIME_OUT_DURATION));
      print(response.body);
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
    print(uri);
    try {
      var response = await http.post(uri, body: payload, headers: {"Content-Type":"application/json"}).timeout(Duration(seconds: TIME_OUT_DURATION));
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet connection', uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException('API not responded in time', uri.toString());
    }
  }

  Future<dynamic> postAuth(String api, dynamic payloadObj) async {
    var uri = Uri.parse(BASE_URL + api);
    print(uri);
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

  //DELETE
  //OTHER

  dynamic _processResponse(http.Response response) {
    print(response.statusCode);
    switch (response.statusCode) {
      case 200:
        var responseJson = utf8.decode(response.bodyBytes);
        return responseJson;
      case 201:
        var responseJson = utf8.decode(response.bodyBytes);
        return responseJson;
        break;
      case 400:
        throw BadRequestException(utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 401:
      case 403:
        print("Unauthorized");
        throw UnAuthorizedException(utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 422:
        throw BadRequestException(utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 500:
      default:
      print("Error URL " + response.request!.url.toString());
        throw FetchDataException('Error occured with code : ${response.statusCode}', response.request!.url.toString());
    }
  }
}