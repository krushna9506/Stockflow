import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with ProviderScope override');
});

/// Active business ID – -1 means not set
final activeBusinessIdProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt(AppConstants.keyBusinessId) ?? -1;
});

/// Persistent theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier(this._prefs)
      : super(_prefs.getBool(AppConstants.keyThemeMode) ?? false);

  final SharedPreferences _prefs;

  void toggle() {
    state = !state;
    _prefs.setBool(AppConstants.keyThemeMode, state);
  }

  void setDark(bool dark) {
    state = dark;
    _prefs.setBool(AppConstants.keyThemeMode, dark);
  }
}
