import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/favorites_store.dart';
import '../services/foreground_task.dart';
import '../services/monitor_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  List<FavoriteCharacter> _favs = [];
  bool _monitorEnabled = false;
  int _intervalSec = 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await FavoritesStore.loadFavorites();
    final enabled = await FavoritesStore.getMonitorEnabled();
    final interval = await FavoritesStore.getMonitorIntervalSec();

    setState(() {
      _favs = favs;
      _monitorEnabled = enabled;
      _intervalSec = interval;
      _loading = false;
    });
  }

  Future<void> _toggleMonitor(bool v) async {
    setState(() => _monitorEnabled = v);
    await FavoritesStore.setMonitorEnabled(v);

    if (v) {
      await FavoritesStore.setMonitorIntervalSec(_intervalSec);
      await ForegroundTaskManager.start();
    } else {
      await ForegroundTaskManager.stop();
    }
  }

  Future<void> _setInterval(int sec) async {
    setState(() => _intervalSec = sec);
    await FavoritesStore.setMonitorIntervalSec(sec);
    if (_monitorEnabled) {
      await ForegroundTaskManager.start();
    }
  }

  Future<void> _remove(String name) async {
    await FavoritesStore.removeFavorite(name);
    await _load();
  }

  Future<void> _openTibiaCom(String name) async {
    final url = Uri.parse('https://www.tibia.com/community/?name=${Uri.encodeComponent(name)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _monitorEnabled,
                            onChanged: (v) => _toggleMonitor(v),
                            title: const Text('Notificações (monitor em segundo plano)'),
                            subtitle: const Text(
                              'Usa um foreground service no Android (mostra notificação fixa). Para funcionar bem, desative otimizações de bateria para o app.',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Intervalo:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Slider(
                                  value: _intervalSec.toDouble(),
                                  min: 20,
                                  max: 300,
                                  divisions: 14,
                                  label: '${_intervalSec}s',
                                  onChanged: _monitorEnabled ? (v) => _setInterval(v.round()) : null,
                                ),
                              ),
                              Text('${_intervalSec}s'),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 12,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await MonitorService.runOnce();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checagem manual concluída.')));
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Testar agora'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final running = await ForegroundTaskManager.isRunning();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(running ? 'Serviço rodando.' : 'Serviço parado.')));
                                  },
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text('Status'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Personagens (${_favs.length})', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_favs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: Text('Sem favoritos ainda.')),
                    )
                  else
                    ..._favs.map(
                      (f) => Card(
                        child: ListTile(
                          title: Text(f.name),
                          leading: const Icon(Icons.person),
                          onTap: () => _openTibiaCom(f.name),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'open') await _openTibiaCom(f.name);
                              if (v == 'remove') await _remove(f.name);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'open', child: Text('Abrir tibia.com')),
                              PopupMenuItem(value: 'remove', child: Text('Remover')),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
