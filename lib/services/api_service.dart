import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

import '../models/models.dart';

class TibiaApi {
  static const _base = 'https://api.tibiadata.com/v4';

  static Future<List<String>> fetchWorlds() async {
    final uri = Uri.parse('$_base/worlds');
    final res = await http.get(uri, headers: {'User-Agent': 'TibiaToolsFlutter'});
    if (res.statusCode != 200) {
      throw Exception('Falha ao buscar worlds (${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final worlds = (json['worlds'] as Map?)?['regular_worlds'] as List?;
    return (worlds ?? const [])
        .whereType<Map>()
        .map((e) => (e['name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList()
      ..sort();
  }

  static Future<CharacterSnapshot> fetchCharacter(String name) async {
    final encoded = Uri.encodeComponent(name.trim());
    final uri = Uri.parse('$_base/character/$encoded');
    final res = await http.get(uri, headers: {'User-Agent': 'TibiaToolsFlutter'});
    if (res.statusCode != 200) {
      throw Exception('Personagem não encontrado (HTTP ${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return CharacterSnapshot.fromTibiaData(json);
  }

  static Future<BoostedInfo> fetchBoosted() async {
    final cUri = Uri.parse('$_base/creatures');
    final bUri = Uri.parse('$_base/boostablebosses');

    final cRes = await http.get(cUri, headers: {'User-Agent': 'TibiaToolsFlutter'});
    final bRes = await http.get(bUri, headers: {'User-Agent': 'TibiaToolsFlutter'});

    if (cRes.statusCode != 200 || bRes.statusCode != 200) {
      throw Exception('Falha ao buscar boosted.');
    }

    final cJson = jsonDecode(cRes.body) as Map<String, dynamic>;
    final bJson = jsonDecode(bRes.body) as Map<String, dynamic>;

    final cBoosted = ((cJson['creatures'] as Map?)?['boosted'] as Map?) ?? const {};
    final bBoosted = ((bJson['boostable_bosses'] as Map?)?['boosted'] as Map?) ?? const {};

    return BoostedInfo(
      creature: (cBoosted['name'] ?? 'N/A').toString(),
      creatureImageUrl: (cBoosted['image_url'] ?? '').toString(),
      boss: (bBoosted['name'] ?? 'N/A').toString(),
      bossImageUrl: (bBoosted['image_url'] ?? '').toString(),
    );
  }
}

class BossesApi {
  static final _unescape = HtmlUnescape();

  static const _urls = <String>[
    'https://www.exevopan.com/bosses/{world}',
    'https://www.exevopan.com/pt/bosses/{world}',
  ];

  // Chance pode vir como % ou texto.
  static final _bossNearChance = RegExp(
    r"(?P<boss>[A-Z][A-Za-z0-9'’\-\.\(\) ]{2,80}?)\s+(?P<chance>\d{1,3}(?:[.,]\d{1,2})?%|No chance|Unknown|Low chance|Medium chance|High chance|Sem chance|Desconhecido)",
    caseSensitive: false,
  );

  static const _forbiddenPrefixes = <String>{
    'char bazaar',
    'calculators',
    'advertise',
    'boss tracker',
    'recently appeared',
    'updated',
    'bosses',
    'statistics',
    'blog',
    'hunting groups',
    'hunting group',
    'listar bosses por',
    'servidor selecionado',
  };

  static bool _looksLikeNavItem(String name) {
    final b = name.trim().toLowerCase();
    if (b.isEmpty) return true;
    if (b.contains('#')) return true;
    for (final pref in _forbiddenPrefixes) {
      if (b.startsWith(pref)) return true;
    }
    return false;
  }

  static String _cleanBossName(String s) {
    var name = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    // remove "day " prefix that sometimes leaks
    name = name.replaceFirst(
      RegExp(r'^(?:\d+\s*)?(?:day|days|dia|dias|hour|hours|hora|horas|minute|minutes|minuto|minutos)\s+', caseSensitive: false),
      '',
    );
    return name.trim();
  }

  static String _normalizeChance(String s) {
    final low = s.trim().toLowerCase();
    if (low == 'sem chance') return 'No chance';
    if (low == 'desconhecido') return 'Unknown';
    if (s.contains('%')) return s.replaceAll(',', '.').trim();
    return s.trim();
  }

  static String _htmlToText(String html) {
    var cleaned = html.replaceAll(RegExp(r'<script\b[^>]*>.*?</script>', caseSensitive: false, dotAll: true), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'<style\b[^>]*>.*?</style>', caseSensitive: false, dotAll: true), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), ' ');
    cleaned = cleaned.replaceAll('\r', ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  static Future<List<BossEntry>> fetchBosses(String world) async {
    final w = Uri.encodeComponent(world.trim());
    String? lastErr;

    for (final tpl in _urls) {
      final uri = Uri.parse(tpl.replaceFirst('{world}', w));
      final res = await http.get(uri, headers: {'User-Agent': 'TibiaToolsFlutter'});
      if (res.statusCode != 200) {
        lastErr = 'HTTP ${res.statusCode}';
        continue;
      }

      final text = _unescape.convert(_htmlToText(res.body));
      final out = <BossEntry>[];
      final seen = <String>{};

      for (final m in _bossNearChance.allMatches(text)) {
        final boss = _cleanBossName((m.namedGroup('boss') ?? '').toString());
        final chance = _normalizeChance((m.namedGroup('chance') ?? '').toString());
        if (boss.isEmpty || chance.isEmpty) continue;
        if (_looksLikeNavItem(boss)) continue;

        final key = '${boss.toLowerCase()}|$chance';
        if (seen.contains(key)) continue;
        seen.add(key);

        out.add(BossEntry(name: boss, chance: chance));
      }

      // ordena: mais prováveis primeiro (High > Medium > Low > No chance/Unknown > % desc)
      int rank(String c) {
        final low = c.toLowerCase();
        if (low.contains('%')) {
          final v = double.tryParse(low.replaceAll('%', '')) ?? 0;
          // Invert: higher percentage higher rank
          return (v * 1000).round();
        }
        if (low.contains('high')) return 900000;
        if (low.contains('medium')) return 800000;
        if (low.contains('low')) return 700000;
        if (low.contains('unknown')) return 100;
        if (low.contains('no chance')) return 0;
        return 50;
      }

      out.sort((a, b) => rank(b.chance).compareTo(rank(a.chance)));
      return out;
    }

    throw Exception('Falha ao carregar bosses ($lastErr).');
  }
}
