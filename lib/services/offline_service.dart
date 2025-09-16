import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/offline_queue.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  Database? _database;
  static const String _tableName = 'offline_queue';

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'offline_queue.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            processed_at INTEGER,
            status TEXT NOT NULL,
            error_message TEXT,
            retry_count INTEGER NOT NULL DEFAULT 0,
            max_retries INTEGER NOT NULL DEFAULT 3
          )
        ''');
      },
    );
  }

  // Add item to offline queue
  Future<void> addToQueue(OfflineQueueItem item) async {
    final db = await database;
    await db.insert(
      _tableName,
      {
        'id': item.id,
        'type': item.type,
        'data': jsonEncode(item.data),
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'processed_at': item.processedAt?.millisecondsSinceEpoch,
        'status': item.status.name,
        'error_message': item.errorMessage,
        'retry_count': item.retryCount,
        'max_retries': item.maxRetries,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all pending items
  Future<List<OfflineQueueItem>> getPendingItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [QueueItemStatus.pending.name],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return OfflineQueueItem(
        id: maps[i]['id'],
        type: maps[i]['type'],
        data: jsonDecode(maps[i]['data']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
        processedAt: maps[i]['processed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(maps[i]['processed_at'])
            : null,
        status: QueueItemStatus.values.firstWhere(
          (e) => e.name == maps[i]['status'],
        ),
        errorMessage: maps[i]['error_message'],
        retryCount: maps[i]['retry_count'],
        maxRetries: maps[i]['max_retries'],
      );
    });
  }

  // Get all items
  Future<List<OfflineQueueItem>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return OfflineQueueItem(
        id: maps[i]['id'],
        type: maps[i]['type'],
        data: jsonDecode(maps[i]['data']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
        processedAt: maps[i]['processed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(maps[i]['processed_at'])
            : null,
        status: QueueItemStatus.values.firstWhere(
          (e) => e.name == maps[i]['status'],
        ),
        errorMessage: maps[i]['error_message'],
        retryCount: maps[i]['retry_count'],
        maxRetries: maps[i]['max_retries'],
      );
    });
  }

  // Update item status
  Future<void> updateItemStatus(
    String id,
    QueueItemStatus status, {
    String? errorMessage,
    DateTime? processedAt,
  }) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'status': status.name,
        'error_message': errorMessage,
        'processed_at': processedAt?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Increment retry count
  Future<void> incrementRetryCount(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $_tableName SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // Remove completed items older than specified days
  Future<void> cleanupOldItems({int daysOld = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    await db.delete(
      _tableName,
      where: 'status = ? AND processed_at < ?',
      whereArgs: [
        QueueItemStatus.completed.name,
        cutoffDate.millisecondsSinceEpoch,
      ],
    );
  }

  // Clear all items
  Future<void> clearAllItems() async {
    final db = await database;
    await db.delete(_tableName);
  }

  // Get queue statistics
  Future<Map<String, int>> getQueueStats() async {
    final db = await database;
    final stats = <String, int>{};

    for (final status in QueueItemStatus.values) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE status = ?',
        [status.name],
      );
      stats[status.name] = result.first['count'] as int;
    }

    return stats;
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // Process offline queue when online
  Future<void> processQueue() async {
    if (!await isOnline()) {
      return;
    }

    final pendingItems = await getPendingItems();
    
    for (final item in pendingItems) {
      try {
        // Mark as processing
        await updateItemStatus(item.id, QueueItemStatus.processing);

        // Process based on type
        bool success = false;
        String? errorMessage;

        switch (item.type) {
          case 'attendance':
            success = await _processAttendanceSubmission(item.data);
            break;
          case 'login':
            success = await _processLogin(item.data);
            break;
          default:
            errorMessage = 'Unknown item type: ${item.type}';
        }

        if (success) {
          await updateItemStatus(
            item.id,
            QueueItemStatus.completed,
            processedAt: DateTime.now(),
          );
        } else {
          final newRetryCount = item.retryCount + 1;
          if (newRetryCount >= item.maxRetries) {
            await updateItemStatus(
              item.id,
              QueueItemStatus.failed,
              errorMessage: errorMessage ?? 'Max retries exceeded',
              processedAt: DateTime.now(),
            );
          } else {
            await updateItemStatus(item.id, QueueItemStatus.pending);
            await incrementRetryCount(item.id);
          }
        }
      } catch (e) {
        await updateItemStatus(
          item.id,
          QueueItemStatus.failed,
          errorMessage: e.toString(),
          processedAt: DateTime.now(),
        );
      }
    }
  }

  // Process attendance submission
  Future<bool> _processAttendanceSubmission(Map<String, dynamic> data) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      final payload = <String, dynamic>{
        'qrData': data['qrCodeData'] ?? data['qrData'],
        'location': data['latitude'] != null && data['longitude'] != null
            ? {
                'latitude': data['latitude'],
                'longitude': data['longitude'],
                'accuracy': data['accuracy']
              }
            : null,
        'wifiSSID': data['wifiSSID'],
        'deviceInfo': data['deviceInfo'],
      }..removeWhere((key, value) => value == null);

      final resp = await dio.post('/qr/validate', data: payload);
      return resp.statusCode == 200 && (resp.data['success'] == true);
    } catch (_) {
      return false;
    }
  }

  // Process login
  Future<bool> _processLogin(Map<String, dynamic> data) async {
    // This would typically make an API call to login
    // For now, we'll simulate success
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // Add attendance submission to queue
  Future<void> queueAttendanceSubmission(Map<String, dynamic> attendanceData) async {
    final item = OfflineQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'attendance',
      data: attendanceData,
      createdAt: DateTime.now(),
    );

    await addToQueue(item);
  }

  // Add login to queue
  Future<void> queueLogin(Map<String, dynamic> loginData) async {
    final item = OfflineQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'login',
      data: loginData,
      createdAt: DateTime.now(),
    );

    await addToQueue(item);
  }
}
