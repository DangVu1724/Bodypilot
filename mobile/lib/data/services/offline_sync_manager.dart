import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/data/services/token_service.dart';

final _logger = Logger();

class OfflineSyncManager {
  static const String _boxName = 'pending_sync_box';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box get _box => Hive.box(_boxName);

  /// Queue an action to be synchronized when network is reconnected
  static Future<void> addPendingAction({
    required String actionType, // e.g. 'ADD_MEAL', 'TOGGLE_WORKOUT', 'UPDATE_NOTE'
    required String endpoint,
    required String httpMethod, // 'POST', 'PUT', 'DELETE'
    required Map<String, dynamic> payload,
  }) async {
    try {
      await init();
      final userId = TokenService.getUserId() ?? 'anonymous';
      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'actionType': actionType,
        'endpoint': endpoint,
        'httpMethod': httpMethod,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _box.add(item);
      _logger.i('[OfflineSyncManager] Action queued offline: $actionType -> $endpoint');
    } catch (e) {
      _logger.e('Error queuing offline action: $e');
    }
  }

  /// Process all pending queued actions upon network reconnection
  static Future<int> processPendingQueue() async {
    try {
      await init();
      if (_box.isEmpty) return 0;

      final userId = TokenService.getUserId() ?? 'anonymous';
      final keysToDelete = <dynamic>[];
      int processedCount = 0;

      for (int i = 0; i < _box.length; i++) {
        final key = _box.keyAt(i);
        final rawData = _box.get(key);
        if (rawData is Map) {
          final item = Map<String, dynamic>.from(rawData);
          if (item['userId'] == userId) {
            final method = item['httpMethod']?.toString().toUpperCase() ?? 'POST';
            final endpoint = item['endpoint']?.toString() ?? '';
            final payload = Map<String, dynamic>.from(item['payload'] ?? {});

            try {
              if (method == 'POST') {
                await apiClient.post(endpoint, data: payload);
              } else if (method == 'PUT') {
                await apiClient.put(endpoint, data: payload);
              } else if (method == 'DELETE') {
                await apiClient.delete(endpoint, queryParameters: payload);
              }
              keysToDelete.add(key);
              processedCount++;
              _logger.i('✅ [OfflineSyncManager] Synced action ${item['actionType']} to $endpoint');
            } catch (e) {
              _logger.w('Failed syncing action ${item['actionType']}, will retry next sync: $e');
            }
          }
        }
      }

      for (var key in keysToDelete) {
        await _box.delete(key);
      }

      return processedCount;
    } catch (e) {
      _logger.e('Error processing offline queue: $e');
      return 0;
    }
  }

  static int getPendingCount() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return 0;
      return _box.length;
    } catch (_) {
      return 0;
    }
  }
}
