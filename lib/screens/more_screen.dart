import 'package:flutter/material.dart';

import 'more/bosses_screen.dart';
import 'more/boosted_screen.dart';
import 'more/imbuements_screen.dart';
import 'more/stamina_screen.dart';
import 'more/hunt_analyzer_screen.dart';
import 'more/training_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _item(
            context,
            icon: Icons.shield,
            title: 'Bosses (ExevoPan)',
            subtitle: 'Lista de bosses e chances por mundo',
            screen: const BossesScreen(),
          ),
          _item(
            context,
            icon: Icons.flash_on,
            title: 'Boosted (TibiaData)',
            subtitle: 'Boosted creature e boosted boss do dia',
            screen: const BoostedScreen(),
          ),
          _item(
            context,
            icon: Icons.fitness_center,
            title: 'Exercise Training',
            subtitle: 'Calculadora simples de treino (dummies)',
            screen: const TrainingScreen(),
          ),
          _item(
            context,
            icon: Icons.timer,
            title: 'Stamina',
            subtitle: 'Calculadora de regeneração de stamina offline',
            screen: const StaminaScreen(),
          ),
          _item(
            context,
            icon: Icons.track_changes,
            title: 'Hunt Analyzer',
            subtitle: 'Cole o Session Data e veja profit/h e xp/h',
            screen: const HuntAnalyzerScreen(),
          ),
          _item(
            context,
            icon: Icons.auto_awesome,
            title: 'Imbuements',
            subtitle: 'Lista e busca (offline, baseado no JSON do seu app)',
            screen: const ImbuementsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
