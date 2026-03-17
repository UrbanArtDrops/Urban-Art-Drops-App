import "package:shared_preferences/shared_preferences.dart";

abstract class AuthSessionStorage {
  Future<String?> read();

  Future<void> write(String serializedSession);

  Future<void> clear();
}

class InMemoryAuthSessionStorage implements AuthSessionStorage {
  String? _serializedSession;

  @override
  Future<void> clear() async {
    _serializedSession = null;
  }

  @override
  Future<String?> read() async => _serializedSession;

  @override
  Future<void> write(String serializedSession) async {
    _serializedSession = serializedSession;
  }
}

class SharedPreferencesAuthSessionStorage implements AuthSessionStorage {
  static const _storageKey = "auth.session";

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  @override
  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_storageKey);
  }

  @override
  Future<void> write(String serializedSession) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, serializedSession);
  }
}
