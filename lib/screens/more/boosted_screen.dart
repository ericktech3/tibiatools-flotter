import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';

class BoostedScreen extends StatefulWidget {
  const BoostedScreen({super.key});

  @override
  State<BoostedScreen> createState() => _BoostedScreenState();
}

class _BoostedScreenState extends State<BoostedScreen> {
  bool _loading = true;
  String? _error;
  BoostedInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      final info = await TibiaApi.fetchBoosted();
      setState(() => _info = info);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boosted'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                : info == null
                    ? const Center(child: Text('Sem dados.'))
                    : ListView(
                        children: [
                          _card(
                            context,
                            title: 'Boosted Creature',
                            name: info.creature,
                            imageUrl: info.creatureImageUrl,
                          ),
                          _card(
                            context,
                            title: 'Boosted Boss',
                            name: info.boss,
                            imageUrl: info.bossImageUrl,
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _card(BuildContext context, {required String title, required String name, required String imageUrl}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 64, height: 64, child: Icon(Icons.image_not_supported)),
                ),
              )
            else
              const SizedBox(width: 64, height: 64, child: Icon(Icons.image)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
