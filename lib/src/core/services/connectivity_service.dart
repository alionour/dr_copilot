import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _hasInternet = true;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool get hasInternet => _hasInternet;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _initConnectivity() async {
    List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final isConnected = result.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );

    if (_hasInternet != isConnected) {
      _hasInternet = isConnected;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
