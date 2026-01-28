import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'favorites_store.dart';
import 'monitor_service.dart';

/// Callback (top-level) chamado quando o serviço inicia.
///
/// Importante: precisa ser top-level e ter @pragma('vm:entry-point')
/// conforme documentação/exemplo do plugin.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MonitorTaskHandler());
}

class ForegroundTaskManager {
  static Future<void> init() async {
    // Deve ser chamado no main() antes do runApp()
    FlutterForegroundTask.initCommunicationPort();

    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tibia_tools_monitor',
        channelName: 'Tibia Tools Monitor',
        channelDescription: 'Monitora favoritos em background (foreground service).',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 60000, // 60s (será sobrescrito ao iniciar)
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWifiLock: true,
        allowWakeLock: true,
      ),
    );
  }

  static Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  static Future<void> startIfEnabled() async {
    final enabled = await FavoritesStore.getMonitorEnabled();
    if (!enabled) return;
    await start();
  }

  static Future<void> start() async {
    final intervalSec = await FavoritesStore.getMonitorIntervalSec();
    final intervalMs = intervalSec * 1000;

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Tibia Tools: monitorando favoritos',
        notificationText: 'Intervalo: ${intervalSec}s',
      );
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Tibia Tools: monitorando favoritos',
      notificationText: 'Intervalo: ${intervalSec}s',
      callback: startCallback,
      // Intervalo efetivo depende do plugin e do SO; este é o solicitado.
      // Algumas ROMs podem otimizar/agrupar.
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: intervalMs,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWifiLock: true,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

class MonitorTaskHandler extends TaskHandler {
  Timer? _timer;
  bool _running = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Primeira execução imediata
    await _safeRun();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Chamado no intervalo configurado no serviço
    await _safeRun();
  }

  Future<void> _safeRun() async {
    if (_running) return;
    _running = true;
    try {
      await MonitorService.runOnce();
    } catch (_) {
      // ignora
    } finally {
      _running = false;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void onNotificationPressed() {
    // Ao tocar na notificação persistente, abre o app
    FlutterForegroundTask.launchApp();
  }

  @override
  void onButtonPressed(String id) {}

  @override
  void onReceiveData(Object data) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('MonitorTaskHandler data: $data');
    }
  }
}
