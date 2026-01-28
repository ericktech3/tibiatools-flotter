import 'package:flutter/material.dart';

class StaminaScreen extends StatefulWidget {
  const StaminaScreen({super.key});

  @override
  State<StaminaScreen> createState() => _StaminaScreenState();
}

class _StaminaScreenState extends State<StaminaScreen> {
  final _staminaCtrl = TextEditingController(text: '38:00');
  final _offlineCtrl = TextEditingController(text: '05:00');

  String? _error;
  String? _result;

  @override
  void dispose() {
    _staminaCtrl.dispose();
    _offlineCtrl.dispose();
    super.dispose();
  }

  int _parseHm(String s) {
    final t = s.trim();
    if (!t.contains(':')) {
      final h = double.tryParse(t) ?? 0;
      return (h * 60).round();
    }
    final parts = t.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  String _fmtHm(int minutes) {
    minutes = minutes.clamp(0, 42 * 60);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void _calc() {
    setState(() {
      _error = null;
      _result = null;
    });

    try {
      final staminaMin = _parseHm(_staminaCtrl.text);
      final offlineMin = _parseHm(_offlineCtrl.text);
      if (staminaMin < 0 || staminaMin > 42 * 60) {
        setState(() => _error = 'Stamina inválida (0:00 até 42:00).');
        return;
      }
      if (offlineMin < 0) {
        setState(() => _error = 'Tempo offline inválido.');
        return;
      }

      final newStam = _applyOfflineRegen(staminaMin, offlineMin);

      final toFullMin = _offlineToFull(staminaMin);

      setState(() {
        _result =
            'Stamina após offline: ${_fmtHm(newStam)}\nOffline p/ encher (42:00): ${_fmtMinutes(toFullMin)} (inclui 10 min iniciais)';
      });
    } catch (e) {
      setState(() => _error = 'Erro: $e');
    }
  }

  int _applyOfflineRegen(int staminaMin, int offlineMin) {
    var stam = staminaMin;
    var off = offlineMin;

    if (stam >= 42 * 60) return 42 * 60;
    if (off <= 10) return stam;

    off -= 10;

    // < 39h: 1 min stamina / 3 min offline
    final cap39 = 39 * 60;
    if (stam < cap39) {
      final need = cap39 - stam;
      final gain = (off ~/ 3).clamp(0, need);
      stam += gain;
      off -= gain * 3;
    }

    // 39h..42h: 1 min stamina / 6 min offline
    final cap42 = 42 * 60;
    if (stam < cap42) {
      final need = cap42 - stam;
      final gain = (off ~/ 6).clamp(0, need);
      stam += gain;
      off -= gain * 6;
    }

    return stam.clamp(0, cap42);
  }

  int _offlineToFull(int staminaMin) {
    if (staminaMin >= 42 * 60) return 0;

    final cap39 = 39 * 60;
    final cap42 = 42 * 60;

    var minutes = 0;
    if (staminaMin < cap39) {
      minutes += (cap39 - staminaMin) * 3;
      minutes += (cap42 - cap39) * 6;
    } else {
      minutes += (cap42 - staminaMin) * 6;
    }

    // +10 min para começar a recuperar
    return minutes + 10;
  }

  String _fmtMinutes(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h <= 0) return '${m}min';
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stamina')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _staminaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stamina atual (HH:MM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _offlineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tempo offline (HH:MM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _calc,
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
          if (_result != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_result!, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
        ],
      ),
    );
  }
}
