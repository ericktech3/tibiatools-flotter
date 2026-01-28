import 'dart:math' as math;

import 'package:flutter/material.dart';

class HuntAnalyzerScreen extends StatefulWidget {
  const HuntAnalyzerScreen({super.key});

  @override
  State<HuntAnalyzerScreen> createState() => _HuntAnalyzerScreenState();
}

class _HuntAnalyzerScreenState extends State<HuntAnalyzerScreen> {
  final _ctrl = TextEditingController();
  String? _error;
  String? _pretty;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _num(String s) {
    return int.parse(s.replaceAll('.', '').replaceAll(',', '').trim());
  }

  void _analyze() {
    setState(() {
      _error = null;
      _pretty = null;
    });

    final txt = _ctrl.text;

    final loot = RegExp(r'Loot:\s*([\d\.,]+)', caseSensitive: false).firstMatch(txt);
    final sup = RegExp(r'Supplies:\s*([\d\.,]+)', caseSensitive: false).firstMatch(txt);
    final bal = RegExp(r'Balance:\s*([-]?\s*[\d\.,]+)', caseSensitive: false).firstMatch(txt);

    final xpGain = RegExp(r'XP Gain:\s*([\d\.,]+)', caseSensitive: false).firstMatch(txt);
    final rawXp = RegExp(r'Raw XP Gain:\s*([\d\.,]+)', caseSensitive: false).firstMatch(txt);

    var sess = RegExp(r'Session\s*Time:\s*(\d{1,2})\s*:\s*(\d{2})\s*h', caseSensitive: false).firstMatch(txt);
    sess ??= RegExp(r'Session\s*(?:duration|time):\s*(\d{1,2})\s*:\s*(\d{2})', caseSensitive: false).firstMatch(txt);

    if (loot == null || sup == null || bal == null) {
      setState(() => _error = 'Texto inválido. Copie o Session Data do Tibia.');
      return;
    }

    final lootV = _num(loot.group(1)!);
    final supV = _num(sup.group(1)!);
    final balV = _num(bal.group(1)!.replaceAll(' ', ''));

    final lines = <String>[
      'Loot: ${_fmt(lootV)} gp',
      'Supplies: ${_fmt(supV)} gp',
      'Balance: ${_fmt(balV)} gp',
    ];

    int? minutes;
    if (sess != null) {
      final h = int.tryParse(sess.group(1)!) ?? 0;
      final m = int.tryParse(sess.group(2)!) ?? 0;
      minutes = math.max(1, h * 60 + m);
      lines.add('Session Time: ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}h');
    }

    String perHour(int val) {
      if (minutes == null) return '';
      final v = (val * 60.0 / minutes!).round();
      return '${_fmt(v)} /h';
    }

    if (minutes != null) {
      lines.add('Profit/h: ${perHour(balV)}');
    }

    if (xpGain != null) {
      try {
        final xp = _num(xpGain.group(1)!);
        lines.add('XP Gain: ${_fmt(xp)}');
        if (minutes != null) lines.add('XP/h: ${perHour(xp)}');
      } catch (_) {}
    }

    if (rawXp != null) {
      try {
        final rxp = _num(rawXp.group(1)!);
        lines.add('Raw XP Gain: ${_fmt(rxp)}');
      } catch (_) {}
    }

    setState(() => _pretty = lines.join('\n'));
  }

  String _fmt(int v) {
    // pt-BR style: dot as thousands separator
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buf.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hunt Analyzer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _ctrl,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Cole aqui o Session Data',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _analyze,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analisar'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_pretty != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(_pretty!),
              ),
            ),
        ],
      ),
    );
  }
}
