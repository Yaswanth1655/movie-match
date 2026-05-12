import 'package:connectivity_plus/connectivity_plus.dart';

class CheckNetworkConnectivity {
  final Connectivity _connectivity = Connectivity();
  bool isConnectedToInternet = true;

  void onInit(context) {
    _connectivity.onConnectivityChanged
        .listen((event) => updateConnectivityStatus(event, context));
  }

  // check recent connectivity status
  void updateConnectivityStatus(List<ConnectivityResult> results, context) {
    ConnectivityResult result =
        results.isNotEmpty ? results.last : ConnectivityResult.none;
    if (result == ConnectivityResult.none) {
      //do something ...
    } else {
      //do something ...
    }
  }
}
