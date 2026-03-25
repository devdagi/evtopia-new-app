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
    // The API now returns List<ConnectivityResult>
    final List<ConnectivityResult> connectivityResult = await connectivity.checkConnectivity();
    _updateStatus(connectivityResult);

    // Listen for changes
    // The API now returns List<ConnectivityResult>
    _subscription = connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _updateStatus(result);
    });
  }

  void _updateStatus(List<ConnectivityResult> result) {
    // If ANY result in the list is NOT ConnectivityResult.none, we consider the device connected.
    // This handles cases where multiple network interfaces are active (e.g., Wifi + Mobile).
    state = result.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
