import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:stockflow/app/app.dart';
import 'package:stockflow/database/app_database.dart';
import 'package:stockflow/providers/app_providers.dart';
import 'package:stockflow/providers/database_provider.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final memoryDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(memoryDb),
        ],
        child: const StockFlowApp(),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(StockFlowApp), findsOneWidget);
    await memoryDb.close();
  });
}

