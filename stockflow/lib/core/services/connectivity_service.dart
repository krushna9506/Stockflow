import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'logger_service.dart';

enum ConnectivityStatus { online, offline, syncing }

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.online) {
    _init();
  }

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late final StreamSubscription<InternetStatus> _internetSubscription;
  
  bool _isConnectedToNetwork = true;
  bool _hasInternetAccess = true;

  void _init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      _isConnectedToNetwork = hasConnection;
      _updateStatus();
    });

    _internetSubscription = InternetConnection().onStatusChange.listen((status) {
      _hasInternetAccess = status == InternetStatus.connected;
      _updateStatus();
    });
  }

  void _updateStatus() {
    final isOnline = _isConnectedToNetwork && _hasInternetAccess;
    final newStatus = isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline;
    
    if (state != newStatus && state != ConnectivityStatus.syncing) {
      LoggerService.i('Connectivity changed to: ${newStatus.name}', tag: 'CONNECTIVITY');
      state = newStatus;
    }
  }

  void setSyncing(bool isSyncing) {
    if (isSyncing) {
      state = ConnectivityStatus.syncing;
    } else {
      _updateStatus();
    }
  }

  bool get isOnline => state == ConnectivityStatus.online || state == ConnectivityStatus.syncing;

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _internetSubscription.cancel();
    super.dispose();
  }
}
