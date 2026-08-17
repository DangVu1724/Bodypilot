import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _statusController.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void init() {
    _checkInitialConnection();

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _updateStatus(false);
      } else {
        final canReachInternet = await _pingInternet();
        _updateStatus(canReachInternet);
      }
    });
  }

  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _updateStatus(false);
      } else {
        final canReachInternet = await _pingInternet();
        _updateStatus(canReachInternet);
      }
    } catch (e) {
      _logger.w('Initial connectivity check failed: $e');
      _updateStatus(false);
    }
  }

  Future<bool> _pingInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _updateStatus(bool isConnected) {
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      _logger.i('🌐 [NetworkConnectivityService] Status changed: isOnline = $isConnected');
      _statusController.add(isConnected);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

final networkConnectivityService = NetworkConnectivityService();
