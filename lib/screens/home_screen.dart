import 'package:flutter/material.dart';

import '../services/foreground_task.dart';
import 'char_search_screen.dart';
import 'favorites_screen.dart';
import 'more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  final _pages = const [
    CharSearchScreen(),
    FavoritesScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Se o usuário deixou ligado, garante que o serviço esteja rodando.
    ForegroundTaskManager.startIfEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Char'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.apps), label: 'Mais'),
        ],
      ),
    );
  }
}
