import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteCharacter {
  final String name;

  const FavoriteCharacter({required this.name});

  Map<String, dynamic> toJson() => {'name': name};

  factory FavoriteCharacter.fromJson(Map<String, dynamic> json) {
    return FavoriteCharacter(name: (json['name'] ?? '').toString());
  }
}

class FavoriteState {
  final bool isOnline;
  final int level;
  final String? latestDeathTime;

  const FavoriteState({required this.isOnline, required this.level, this.latestDeathTime});

  Map<String, dynamic> toJson() => {
        'isOnline': isOnline,
        'level': level,
        'latestDeathTime': latestDeathTime,
      };

  factory FavoriteState.fromJson(Map<String, dynamic> json) {
    return FavoriteState(
      isOnline: (json['isOnline'] ?? false) as bool,
      level: (json['level'] ?? 0) as int,
      latestDeathTime: json['latestDeathTime']?.toString(),
    );
  }
}

class FavoritesStore {
  static const _kFavorites = 'favorites';
  static const _kMonitorEnabled = 'monitor_enabled';
  static const _kMonitorInterval = 'monitor_interval_sec';
  static const _kLastState = 'favorites_last_state';

  static Future<List<FavoriteCharacter>> loadFavorites() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kFavorites);
    if (raw == null || raw.trim().isEmpty) return [];
    final list = (jsonDecode(raw) as List).whereType<Map>().toList();
    return list.map((e) => FavoriteCharacter.fromJson(e.cast<String, dynamic>())).where((e) => e.name.isNotEmpty).toList();
  }

  static Future<void> saveFavorites(List<FavoriteCharacter> favs) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(favs.map((e) => e.toJson()).toList());
    await sp.setString(_kFavorites, raw);
  }

  static Future<void> addFavorite(String name) async {
    final favs = await loadFavorites();
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (favs.any((f) => f.name.toLowerCase() == clean.toLowerCase())) return;
    favs.add(FavoriteCharacter(name: clean));
    favs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await saveFavorites(favs);
  }

  static Future<void> removeFavorite(String name) async {
    final favs = await loadFavorites();
    favs.removeWhere((f) => f.name.toLowerCase() == name.trim().toLowerCase());
    await saveFavorites(favs);
  }

  static Future<bool> getMonitorEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kMonitorEnabled) ?? false;
  }

  static Future<void> setMonitorEnabled(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kMonitorEnabled, v);
  }

  static Future<int> getMonitorIntervalSec() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kMonitorInterval) ?? 60;
  }

  static Future<void> setMonitorIntervalSec(int seconds) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kMonitorInterval, seconds.clamp(20, 3600));
  }

  static Future<Map<String, FavoriteState>> loadLastStates() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kLastState);
    if (raw == null || raw.trim().isEmpty) return {};
    final obj = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final out = <String, FavoriteState>{};
    for (final e in obj.entries) {
      if (e.value is Map) {
        out[e.key] = FavoriteState.fromJson((e.value as Map).cast<String, dynamic>());
      }
    }
    return out;
  }

  static Future<void> saveLastStates(Map<String, FavoriteState> states) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(states.map((k, v) => MapEntry(k, v.toJson())));
    await sp.setString(_kLastState, raw);
  }
}
