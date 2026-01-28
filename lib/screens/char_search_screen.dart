import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/favorites_store.dart';

class CharSearchScreen extends StatefulWidget {
  const CharSearchScreen({super.key});

  @override
  State<CharSearchScreen> createState() => _CharSearchScreenState();
}

class _CharSearchScreenState extends State<CharSearchScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  CharacterSnapshot? _snap;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _snap = null;
    });

    try {
      final snap = await TibiaApi.fetchCharacter(name);
      setState(() => _snap = snap);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  (int min, int max) _sharedXpRange(int level) {
    // Tibia rule of thumb: min = ceil(2/3*L), max = floor(3/2*L)
    final min = ((2 * level) / 3).ceil();
    final max = ((3 * level) / 2).floor();
    return (min, max);
  }

  Future<void> _openTibiaCom(String name) async {
    final url = Uri.parse('https://www.tibia.com/community/?name=${Uri.encodeComponent(name)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Character')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      labelText: 'Nome do personagem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (snap != null)
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(snap.name, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _chip('World', snap.world),
                                _chip('Level', '${snap.level}'),
                                _chip('Vocation', snap.vocation),
                                _chip('Status', snap.isOnline ? 'Online' : 'Offline'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Builder(builder: (context) {
                              final (min, max) = _sharedXpRange(snap.level);
                              return Text('Shared XP: $min – $max');
                            }),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: () async {
                                    await FavoritesStore.addFavorite(snap.name);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicionado aos favoritos.')));
                                    }
                                  },
                                  icon: const Icon(Icons.star),
                                  label: const Text('Favoritar'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _openTibiaCom(snap.name),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('tibia.com'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (snap.deaths.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Últimas mortes', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              ...snap.deaths.take(5).map((d) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text('• ${d.time} — ${d.reason}'),
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('Busque um personagem para ver detalhes.'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }
}
