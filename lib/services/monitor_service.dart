import 'dart:math';

import '../models/models.dart';
import 'api_service.dart';
import 'favorites_store.dart';
import 'notification_service.dart';

class MonitorService {
  /// Faz 1 rodada de checagem e dispara notificações quando detecta mudanças.
  static Future<void> runOnce() async {
    final favs = await FavoritesStore.loadFavorites();
    if (favs.isEmpty) return;

    final lastStates = await FavoritesStore.loadLastStates();
    final updatedStates = Map<String, FavoriteState>.from(lastStates);

    for (final fav in favs) {
      final name = fav.name.trim();
      if (name.isEmpty) continue;

      try {
        final snap = await TibiaApi.fetchCharacter(name);

        final prev = lastStates[name.toLowerCase()];
        final now = FavoriteState(
          isOnline: snap.isOnline,
          level: snap.level,
          latestDeathTime: snap.latestDeathTime,
        );

        // Notificação: online/offline
        if (prev != null && prev.isOnline != now.isOnline) {
          await NotificationService.show(
            id: _notifId(name, now.isOnline ? 'online' : 'offline'),
            title: now.isOnline ? '✅ $name ficou online' : '⛔ $name ficou offline',
            body: 'World: ${snap.world} • Level: ${snap.level}',
          );
        }

        // Notificação: level up
        if (prev != null && now.level > prev.level) {
          await NotificationService.show(
            id: _notifId(name, 'levelup'),
            title: '🎉 $name upou!',
            body: 'Level ${prev.level} → ${now.level} (${snap.vocation})',
          );
        }

        // Notificação: morte (compara última death time)
        final prevDeath = prev?.latestDeathTime;
        final nowDeath = now.latestDeathTime;
        if (prev != null && nowDeath != null && nowDeath.isNotEmpty && nowDeath != prevDeath) {
          await NotificationService.show(
            id: _notifId(name, 'death'),
            title: '💀 $name morreu',
            body: 'Registro novo de morte detectado.',
          );
        }

        updatedStates[name.toLowerCase()] = now;
      } catch (_) {
        // Silencioso: personagem pode estar inválido / sem internet / etc.
      }
    }

    await FavoritesStore.saveLastStates(updatedStates);
  }

  static int _notifId(String name, String kind) {
    // Mantém ID estável e dentro de 32-bit signed
    final seed = (name.toLowerCase() + '|' + kind).codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return max(1, seed);
  }
}
