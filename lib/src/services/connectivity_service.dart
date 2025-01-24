import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:vimbika_pos_app/src/constants/app_constants.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  Future<bool> checkServerConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
    // try {
    //   // Set a timeout for the server reachability check
    //   final response = await http
    //       .get(Uri.parse(AppConstants.VIMBIKA_BACKEND_URL + '/app/ping/check'))
    //       .timeout(const Duration(seconds: 5)); // Timeout after 5 seconds
    //
    //   // If the response status is 200, the server is reachable
    //   return response.statusCode == 200;
    // } catch (e) {
    //   // If an error occurs (e.g., server is unreachable or timeout), return false
    //   return false;
    // }
  }
}