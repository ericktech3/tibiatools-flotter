import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  static const weapons = <String, Map<String, int>>{
    'Standard (500)': {'charges': 500, 'price': 347222},
    'Enhanced (1800)': {'charges': 1800, 'price': 1250000},
    'Lasting (14400)': {'charges': 14400, 'price': 10000000},
  };

  static const skillConstants = <String, (double, int)>{
    'magic': (1600.0, 0),
    'melee': (50.0, 10),
    'distance': (25.0, 10),
    'shielding': (100.0, 10),
    'fishing': (20.0, 10),
  };

  static const vocationConstants = <String, Map<String, double>>{
    'none': {'magic': 4.0, 'melee': 2.0, 'fist': 1.5, 'distance': 2.0, 'shielding': 1.5},
    'knight': {'magic': 3.0, 'melee': 1.1, 'fist': 1.1, 'distance': 1.4, 'shielding': 1.1},
    'paladin': {'magic': 1.4, 'melee': 1.2, 'fist': 1.2, 'distance': 1.1, 'shielding': 1.1},
    'sorcerer': {'magic': 1.1, 'melee': 2.0, 'fist': 1.5, 'distance': 2.0, 'shielding': 1.5},
    'druid': {'magic': 1.1, 'melee': 1.8, 'fist': 1.5, 'distance': 1.8, 'shielding': 1.5},
    'monk': {'magic': 1.25, 'melee': 1.4, 'fist': 1.1, 'distance': 1.5, 'shielding': 1.15},
  };

  static const pointsPerCharge = <String, double>{
    'melee': 7.2,
    'fist': 7.2,
    'distance': 4.32,
    'shielding': 14.4,
    'magic': 600.0,
  };

  static const skillMap = <String, (String skillConstType, String vocAttr)>{
    'Sword': ('melee', 'melee'),
    'Axe': ('melee', 'melee'),
    'Club': ('melee', 'melee'),
    'Fist Fighting': ('melee', 'fist'),
    'Distance': ('distance', 'distance'),
    'Shielding': ('shielding', 'shielding'),
    'Magic Level': ('magic', 'magic'),
  };

  static const vocUiMap = <String, String>{
    'None': 'none',
    'Knight': 'knight',
    'Paladin': 'paladin',
    'Sorcerer': 'sorcerer',
    'Druid': 'druid',
    'Monk': 'monk',
  };

  String _skillUi = 'Sword';
  String _vocationUi = 'Knight';
  String _weaponKind = 'Standard (500)';

  final _fromCtrl = TextEditingController(text: '100');
  final _toCtrl = TextEditingController(text: '110');
  final _pctCtrl = TextEditingController(text: '100');
  final _loyaltyCtrl = TextEditingController(text: '0');

  bool _privateDummy = false;
  bool _doubleEvent = false;

  String? _error;
  TrainingPlan? _plan;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _pctCtrl.dispose();
    _loyaltyCtrl.dispose();
    super.dispose();
  }

  void _compute() {
    setState(() {
      _error = null;
      _plan = null;
    });

    final from = int.tryParse(_fromCtrl.text.trim()) ?? 0;
    final to = int.tryParse(_toCtrl.text.trim()) ?? 0;
    final pct = double.tryParse(_pctCtrl.text.trim()) ?? 0;
    final loyalty = double.tryParse(_loyaltyCtrl.text.trim()) ?? 0;

    final (skillConstType, vocAttr) = skillMap[_skillUi]!;
    final vocKey = vocUiMap[_vocationUi] ?? 'knight';

    if (to <= from) {
      setState(() => _error = 'O nível final deve ser maior que o inicial.');
      return;
    }

    final minLevel = skillConstType == 'magic' ? 0 : 10;
    if (from < minLevel || to < minLevel) {
      setState(() => _error = 'Para $_skillUi, use valores >= $minLevel.');
      return;
    }

    if (pct <= 0 || pct > 100) {
      setState(() => _error = 'O % restante deve estar entre 1 e 100.');
      return;
    }

    final weapon = weapons[_weaponKind] ?? weapons['Standard (500)']!;
    final chargesPerWeapon = weapon['charges']!;
    final price = weapon['price']!;

    var mult = 1.0;
    mult *= (1.0 + math.max(0.0, loyalty) / 100.0);
    if (_privateDummy) mult *= 1.10;
    if (_doubleEvent) mult *= 2.0;

    final pointsKey = vocAttr == 'fist' ? 'fist' : skillConstType;
    final ppc = pointsPerCharge[pointsKey] ?? 7.2;

    final totalPoints = _totalPointsNeeded(
      skillConstType: skillConstType,
      vocAttr: vocAttr,
      vocKey: vocKey,
      fromLevel: from,
      toLevel: to,
      percentLeft: pct,
    );

    if (totalPoints <= 0) {
      setState(() => _error = 'Nada para calcular.');
      return;
    }

    final chargesNeeded = (totalPoints / (ppc * mult)).ceil();
    final weaponsNeeded = (chargesNeeded / chargesPerWeapon).ceil();

    final hours = (chargesNeeded * 2) / 3600.0;
    final cost = weaponsNeeded * price;

    setState(() => _plan = TrainingPlan(
          totalCharges: chargesNeeded,
          weapons: weaponsNeeded,
          hours: hours,
          totalCostGp: cost,
        ));
  }

  double _pointsToAdvance({
    required String skillConstType,
    required String vocAttr,
    required String vocKey,
    required int level,
  }) {
    final (base, offset) = skillConstants[skillConstType]!;
    final vconst = vocationConstants[vocKey]![vocAttr]!;
    return base * math.pow(vconst, (level - offset)).toDouble();
  }

  double _totalPointsNeeded({
    required String skillConstType,
    required String vocAttr,
    required String vocKey,
    required int fromLevel,
    required int toLevel,
    required double percentLeft,
  }) {
    final pct = percentLeft.clamp(0.0, 100.0);
    var total = (pct / 100.0) * _pointsToAdvance(
      skillConstType: skillConstType,
      vocAttr: vocAttr,
      vocKey: vocKey,
      level: fromLevel,
    );
    for (var lvl = fromLevel + 1; lvl < toLevel; lvl++) {
      total += _pointsToAdvance(skillConstType: skillConstType, vocAttr: vocAttr, vocKey: vocKey, level: lvl);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Training')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _skillUi,
                    decoration: const InputDecoration(labelText: 'Skill', border: OutlineInputBorder()),
                    items: skillMap.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setState(() => _skillUi = v ?? _skillUi),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _vocationUi,
                    decoration: const InputDecoration(labelText: 'Vocation', border: OutlineInputBorder()),
                    items: vocUiMap.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setState(() => _vocationUi = v ?? _vocationUi),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _weaponKind,
                    decoration: const InputDecoration(labelText: 'Exercise weapon', border: OutlineInputBorder()),
                    items: weapons.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setState(() => _weaponKind = v ?? _weaponKind),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'From', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _toCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'To', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pctCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '% restante (1..100)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _loyaltyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Loyalty %', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _privateDummy,
                    onChanged: (v) => setState(() => _privateDummy = v ?? false),
                    title: const Text('Private Dummy (+10%)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _doubleEvent,
                    onChanged: (v) => setState(() => _doubleEvent = v ?? false),
                    title: const Text('Double skill event (x2)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _compute,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calcular'),
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
          if (_plan != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resultado', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Charges: ${fmt.format(_plan!.totalCharges)}'),
                    Text('Weapons: ${fmt.format(_plan!.weapons)}'),
                    Text('Tempo: ${_plan!.hours.toStringAsFixed(2)} h'),
                    Text('Custo: ${fmt.format(_plan!.totalCostGp)} gp'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TrainingPlan {
  final int totalCharges;
  final int weapons;
  final double hours;
  final int totalCostGp;

  const TrainingPlan({
    required this.totalCharges,
    required this.weapons,
    required this.hours,
    required this.totalCostGp,
  });
}
