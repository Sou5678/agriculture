import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  Future<void> initialize() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _updateConnectionStatus(_connectionStatus);
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          print('Connectivity error: $error');
        },
      );
    } catch (e) {
      print('Error initializing connectivity service: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _connectionStatus = result;
    _isConnected = !result.contains(ConnectivityResult.none);
    notifyListeners();
  }

  String getConnectionType() {
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (_connectionStatus.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else {
      return 'No Connection';
    }
  }

  bool get hasStrongConnection {
    return _connectionStatus.contains(ConnectivityResult.wifi) ||
           _connectionStatus.contains(ConnectivityResult.ethernet);
  }

  bool get hasWeakConnection {
    return _connectionStatus.contains(ConnectivityResult.mobile);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}