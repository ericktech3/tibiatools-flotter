import 'dart:convert';

class CharacterDeath {
  final String time; // ISO string from TibiaData
  final String reason;

  const CharacterDeath({required this.time, required this.reason});

  factory CharacterDeath.fromJson(Map<String, dynamic> json) {
    return CharacterDeath(
      time: (json['time'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

class CharacterSnapshot {
  final String name;
  final String world;
  final String vocation;
  final int level;
  final String status; // "online"/"offline" (TibiaData uses strings)
  final List<CharacterDeath> deaths;

  const CharacterSnapshot({
    required this.name,
    required this.world,
    required this.vocation,
    required this.level,
    required this.status,
    required this.deaths,
  });

  bool get isOnline => status.toLowerCase().contains('online');

  String? get latestDeathTime => deaths.isEmpty ? null : deaths.first.time;

  factory CharacterSnapshot.fromTibiaData(Map<String, dynamic> json) {
    // TibiaData v4:
    // { "character": { "character": { ... , "level": 123, "status": "online" }, "deaths": [ ... ] } }
    final root = (json['character'] as Map?) ?? const {};
    final character = (root['character'] as Map?) ?? const {};
    final deathsJson = (root['deaths'] as List?) ?? const [];

    final deaths = deathsJson
        .whereType<Map>()
        .map((e) => CharacterDeath.fromJson(e.cast<String, dynamic>()))
        .toList();

    return CharacterSnapshot(
      name: (character['name'] ?? '').toString(),
      world: (character['world'] ?? '').toString(),
      vocation: (character['vocation'] ?? '').toString(),
      level: int.tryParse((character['level'] ?? '0').toString()) ?? 0,
      status: (character['status'] ?? 'offline').toString(),
      deaths: deaths,
    );
  }

  @override
  String toString() => jsonEncode({
        'name': name,
        'world': world,
        'vocation': vocation,
        'level': level,
        'status': status,
        'latestDeathTime': latestDeathTime,
      });
}

class BossEntry {
  final String name;
  final String chance; // "Very Low", etc.

  const BossEntry({required this.name, required this.chance});
}

class BoostedInfo {
  final String creature;
  final String creatureImageUrl;
  final String boss;
  final String bossImageUrl;

  const BoostedInfo({
    required this.creature,
    required this.creatureImageUrl,
    required this.boss,
    required this.bossImageUrl,
  });
}

class ImbuementEntry {
  final String name;
  final String type;
  final String effect;
  final List<String> items;

  const ImbuementEntry({
    required this.name,
    required this.type,
    required this.effect,
    required this.items,
  });

  factory ImbuementEntry.fromJson(Map<String, dynamic> json) {
    return ImbuementEntry(
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      effect: (json['effect'] ?? '').toString(),
      items: ((json['items'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
