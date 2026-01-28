import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';

class BossesScreen extends StatefulWidget {
  const BossesScreen({super.key});

  @override
  State<BossesScreen> createState() => _BossesScreenState();
}

class _BossesScreenState extends State<BossesScreen> {
  bool _loadingWorlds = true;
  List<String> _worlds = [];
  String? _world;

  bool _loadingBosses = false;
  String? _error;
  List<BossEntry> _bosses = [];

  @override
  void initState() {
    super.initState();
    _loadWorlds();
  }

  Future<void> _loadWorlds() async {
    setState(() {
      _loadingWorlds = true;
      _error = null;
    });
    try {
      final worlds = await TibiaApi.fetchWorlds();
      setState(() {
        _worlds = worlds;
        _world = worlds.isNotEmpty ? worlds.first : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingWorlds = false);
    }
  }

  Future<void> _loadBosses() async {
    final world = _world;
    if (world == null) return;

    setState(() {
      _loadingBosses = true;
      _error = null;
      _bosses = [];
    });

    try {
      final bosses = await BossesApi.fetchBosses(world);
      setState(() => _bosses = bosses);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingBosses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bosses')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _loadingWorlds
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _world,
                              decoration: const InputDecoration(
                                labelText: 'World',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: _worlds
                                  .map((w) => DropdownMenuItem(
                                        value: w,
                                        child: Text(w, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _world = v),
                            ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _loadingBosses || _loadingWorlds ? null : _loadBosses,
                      child: _loadingBosses
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Buscar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _bosses.isEmpty
                  ? Center(
                      child: Text(_loadingBosses ? 'Carregando...' : 'Selecione um world e toque em Buscar.'),
                    )
                  : ListView.builder(
                      itemCount: _bosses.length,
                      itemBuilder: (_, i) {
                        final b = _bosses[i];
                        return Card(
                          child: ListTile(
                            title: Text(b.name),
                            subtitle: Text('Chance: ${b.chance}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
