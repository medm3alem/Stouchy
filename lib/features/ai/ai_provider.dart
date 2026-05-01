import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final aiApiKeyProvider = StateNotifierProvider<AiApiKeyNotifier, String?>((ref) {
  return AiApiKeyNotifier();
});

class AiApiKeyNotifier extends StateNotifier<String?> {
  AiApiKeyNotifier() : super(null) {
    _loadKey();
  }

  static const _key = 'gemini_api_key';

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove(_key);
      state = null;
    } else {
      await prefs.setString(_key, key);
      state = key;
    }
  }
}
