import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class ImbuementsScreen extends StatefulWidget {
  const ImbuementsScreen({super.key});

  @override
  State<ImbuementsScreen> createState() => _ImbuementsScreenState();
}

class _ImbuementsScreenState extends State<ImbuementsScreen> {
  bool _loading = true;
  String? _error;

  List<_Imb> _all = [];
  List<_Imb> _filtered = [];

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await rootBundle.loadString('assets/imbuements_seed.json');
      final obj = (jsonDecode(raw) as Map).cast<String, dynamic>();

      final list = <_Imb>[];
      for (final e in obj.entries) {
        if (e.value is Map) {
          final m = (e.value as Map).cast<String, dynamic>();
          final displayName = (m['name'] ?? e.key).toString();
          list.add(_Imb(key: e.key, displayName: displayName, raw: m));
        }
      }
      list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      setState(() {
        _all = list;
        _filtered = list;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    setState(() {
      _filtered = _all.where((i) => i.displayName.toLowerCase().contains(q) || i.key.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imbuements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Buscar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final imb = _filtered[i];
                          return Card(
                            child: ListTile(
                              title: Text(imb.displayName),
                              subtitle: Text(imb.key),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImbuementDetailsScreen(imb: imb))),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _Imb {
  final String key;
  final String displayName;
  final Map<String, dynamic> raw;

  const _Imb({required this.key, required this.displayName, required this.raw});
}

class ImbuementDetailsScreen extends StatelessWidget {
  final _Imb imb;

  const ImbuementDetailsScreen({super.key, required this.imb});

  @override
  Widget build(BuildContext context) {
    final levels = ((imb.raw['level'] as Map?) ?? const {}).cast<String, dynamic>();

    return Scaffold(
      appBar: AppBar(title: Text(imb.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imb.raw['gold_token'] == true)
            const Card(
              child: ListTile(
                leading: Icon(Icons.monetization_on),
                title: Text('Gold Token'),
                subtitle: Text('Este imbuement exige Gold Token no NPC.'),
              ),
            ),
          ...levels.entries.map((e) {
            final lvlName = e.key;
            final obj = (e.value as Map).cast<String, dynamic>();
            final desc = (obj['description'] ?? '').toString();
            final itens = (obj['itens'] as List?) ?? const [];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lvlName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    if (desc.isNotEmpty) Text(desc),
                    const SizedBox(height: 12),
                    Text('Itens', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    ...itens.whereType<Map>().map((it) {
                      final m = it.cast<String, dynamic>();
                      final itemName = (m['name'] ?? '').toString();
                      final qty = (m['quantity'] ?? '').toString();
                      final link = (m['link'] ?? '').toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text('$qty x $itemName'),
                        subtitle: link.isNotEmpty ? Text(link) : null,
                        onTap: link.isNotEmpty
                            ? () async {
                                await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
                              }
                            : null,
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
