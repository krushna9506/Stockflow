import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
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

  /// Export products to human-readable CSV/Excel format
  Future<String?> exportToCsv(int businessId) async {
    try {
      final products = await (_db.select(_db.products)
            ..where((t) => t.businessId.equals(businessId)))
          .get();

      final csvBuffer = StringBuffer();
      // CSV Header
      csvBuffer.writeln('Name,SKU,SellingPrice,PurchasePrice,CurrentQuantity,MinimumStock');

      for (final p in products) {
        final name = '"${p.name.replaceAll('"', '""')}"';
        final sku = '"${(p.sku ?? '').replaceAll('"', '""')}"';
        csvBuffer.writeln('$name,$sku,${p.sellingPrice},${p.purchasePrice},${p.currentQuantity},${p.minimumStock}');
      }

      final csvData = csvBuffer.toString();

      if (kIsWeb) {
        LoggerService.i('CSV export generated for web', tag: 'BACKUP');
        return csvData;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final filePath = p.join(directory.path, 'stockflow_inventory_$timestamp.csv');

      final file = File(filePath);
      await file.writeAsString(csvData, encoding: utf8);

      LoggerService.i('CSV inventory backup saved at $filePath', tag: 'BACKUP');
      return filePath;
    } catch (e) {
      LoggerService.e('Failed to export CSV inventory', error: e, tag: 'BACKUP');
      return null;
    }
  }

  /// Import products from CSV content
  Future<int> importFromCsv(String csvContent, int businessId) async {
    try {
      final lines = const LineSplitter().convert(csvContent);
      if (lines.length <= 1) return 0;

      int importedCount = 0;
      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Simple CSV parser for standard values
        final parts = _parseCsvLine(line);
        if (parts.isEmpty) continue;

        final name = parts.isNotEmpty ? parts[0] : 'Imported Item $i';
        final sku = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
        final sellingPrice = parts.length > 2 ? double.tryParse(parts[2]) ?? 0.0 : 0.0;
        final purchasePrice = parts.length > 3 ? double.tryParse(parts[3]) ?? 0.0 : 0.0;
        final currentQuantity = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
        final minimumStock = parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0;

        await _db.into(_db.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            name: name,
            businessId: businessId,
            sellingPrice: Value(sellingPrice),
            purchasePrice: Value(purchasePrice),
            currentQuantity: Value(currentQuantity),
            minimumStock: Value(minimumStock),
            sku: Value(sku),
            updatedAt: Value(DateTime.now()),
          ),
        );
        importedCount++;
      }

      LoggerService.i('Imported $importedCount items from CSV', tag: 'BACKUP');
      return importedCount;
    } catch (e) {
      LoggerService.e('Failed to import CSV inventory', error: e, tag: 'BACKUP');
      return 0;
    }
  }

  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool insideQuotes = false;
    final StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  Future<String?> createBackup() async {
    return exportToCsv(1);
  }

  Future<bool> restoreBackup(String backupFilePath) async {
    if (!kIsWeb) {
      final file = File(backupFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final count = await importFromCsv(content, 1);
        return count > 0;
      }
    }
    return false;
  }
}
