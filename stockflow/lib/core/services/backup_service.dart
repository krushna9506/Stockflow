import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import 'logger_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  Future<String?> createBackup() async {
    if (kIsWeb) {
      LoggerService.e('Database backup is not supported on Flutter Web.', tag: 'BACKUP');
      return null;
    }
    try {
      final dbPath = await _db.getDatabasePath();
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final backupPath = p.join(directory.path, 'stockflow_backup_$timestamp.sqlite');
      
      // Copy to new backup path
      await dbFile.copy(backupPath);
      LoggerService.i('Backup created successfully at $backupPath', tag: 'BACKUP');
      return backupPath;
    } catch (e) {
      LoggerService.e('Failed to create backup', error: e, tag: 'BACKUP');
      return null;
    }
  }

  Future<bool> restoreBackup(String backupFilePath) async {
    if (kIsWeb) {
      LoggerService.e('Database restore is not supported on Flutter Web.', tag: 'BACKUP');
      return false;
    }
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found at $backupFilePath');
      }

      final dbPath = await _db.getDatabasePath();
      
      // In a real app we'd need to close the DB connection first.
      // For Drift, closing is recommended before replacing the file.
      await _db.close();

      // Replace
      await backupFile.copy(dbPath);
      LoggerService.i('Backup restored successfully from $backupFilePath', tag: 'BACKUP');
      return true;
    } catch (e) {
      LoggerService.e('Failed to restore backup', error: e, tag: 'BACKUP');
      return false;
    }
  }
}
