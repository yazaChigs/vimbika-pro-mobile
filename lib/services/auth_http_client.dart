import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_constants/app_constants.dart';


class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient();

  // Use a memory cache to avoid local storage access in each call
  var _inMemoryToken = '';


  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // intercept each call and add the Authorization header if token is available
    _inMemoryToken = await _loadTokenFromSharedPreference();
    if (_inMemoryToken.isNotEmpty) {
      request.headers['Content-Type'] = "application/json";
      request.headers.putIfAbsent('Authorization', () => "Bearer " + _inMemoryToken);
    }

    return request.send();
  }

  Future<String> _loadTokenFromSharedPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var accessToken = '';
    // If user is already authenticated, we can load his token from cache
    final String? value =  prefs.getString(AppConstants.CACHED_ACCESS_TOKEN);
    if(value != null){
      accessToken = value;
    }
    return accessToken;
  }

  // Don't forget to reset the cache when logging out the user
  void reset() {
    _inMemoryToken = '';
  }
}