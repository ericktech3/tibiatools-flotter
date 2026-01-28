import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'favorites_store.dart';
import 'monitor_service.dart';

/// Callback (top-level) chamado quando o serviço inicia.
///
/// Importante: precisa ser top-level e ter @pragma('vm:entry-point')
/// conforme documentação do plugin.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MonitorTaskHandler());
}

class ForegroundTaskManager {
  static const int _defaultIntervalMs = 60000; // 60s
  static const int _serviceId = 1001;

  static void init() {
    // Deve ser chamado no main() antes do runApp()
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tibia_tools_monitor',
        channelName: 'Tibia Tools Monitor',
        channelDescription: 'Monitora favoritos em background (foreground service).',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      // No v9+, o intervalo fica dentro de eventAction (ForegroundTaskEventAction.repeat)
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_defaultIntervalMs),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWifiLock: true,
        allowWakeLock: true,
        allowAutoRestart: true,
        stopWithTask: false,
      ),
    );
  }

  static Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  static Future<void> startIfEnabled() async {
    final enabled = await FavoritesStore.getMonitorEnabled();
    if (!enabled) return;
    await start();
  }

  static ForegroundTaskOptions _buildOptions(int intervalMs) {
    return ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(intervalMs),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWifiLock: true,
      allowWakeLock: true,
      allowAutoRestart: true,
      stopWithTask: false,
    );
  }

  static Future<void> start() async {
    final intervalSec = await FavoritesStore.getMonitorIntervalSec();
    final intervalMs = intervalSec * 1000;

    final options = _buildOptions(intervalMs);

    if (await FlutterForegroundTask.isRunningService) {
      // Atualiza o intervalo/params em runtime
      await FlutterForegroundTask.updateService(
        foregroundTaskOptions: options,
        notificationTitle: 'Tibia Tools: monitorando favoritos',
        notificationText: 'Intervalo: ${intervalSec}s',
      );
      return;
    }

    // Define as opções que serão usadas pelo serviço no startService.
    FlutterForegroundTask.foregroundTaskOptions = options;

    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      // Android 14+: declarar o tipo do foreground service (dataSync faz sentido aqui)
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Tibia Tools: monitorando favoritos',
      notificationText: 'Intervalo: ${intervalSec}s',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

class MonitorTaskHandler extends TaskHandler {
  bool _running = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Primeira execução imediata
    await _safeRun();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Chamado de acordo com eventAction em ForegroundTaskOptions
    unawaited(_safeRun());
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
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // nada
  }

  @override
  void onNotificationPressed() {
    // Ao tocar na notificação persistente, abre o app
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationDismissed() {}

  @override
  void onReceiveData(Object data) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('MonitorTaskHandler data: $data');
    }
  }
}
