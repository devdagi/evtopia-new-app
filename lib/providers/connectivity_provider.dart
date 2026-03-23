import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  StreamSubscription? _subscription;

  Future<void> _init() async {
    final connectivity = Connectivity();
    
    // Initial check
    final connectivityResult = await connectivity.checkConnectivity();
    _updateStatus(connectivityResult);

    // Listen for changes
    _subscription = connectivity.onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });
  }

  void _updateStatus(ConnectivityResult result) {
    // We consider it "connected" if it's wifi or mobile.
    // This avoids the false negatives of socket pinging on mobile data.
    state = result != ConnectivityResult.none;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
