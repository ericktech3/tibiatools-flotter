# Tibia Tools — migração para Flutter (pack)

Este ZIP **não é um projeto Flutter completo** (porque o template do Flutter/Gradle varia por versão).  
Ele é um “pack” com o **código Flutter (lib/)**, **assets/**, `pubspec.yaml` e um workflow do GitHub Actions.

## Como testar rápido (local)
1. Instale Flutter **stable** (recomendado Flutter 3.22+ / Dart 3.4+).  
2. Crie um projeto Flutter novo:
   ```bash
   flutter create tibia_tools_flutter
   cd tibia_tools_flutter
   ```
3. Copie **tudo** deste pack para dentro do projeto criado (sobrescrevendo):
   - `lib/`
   - `assets/`
   - `pubspec.yaml`
   - `analysis_options.yaml`
   - `.github/workflows/android_flutter.yml` (opcional)

4. Rode:
   ```bash
   flutter pub get
   flutter run
   ```

## AndroidManifest.xml (importante p/ notificações e monitor)
O plugin `flutter_foreground_task` exige permissões e uma declaração de serviço no `AndroidManifest.xml`.  
O README do plugin mostra, por exemplo, `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` e a tag `<service ... ForegroundService ... foregroundServiceType="dataSync|remoteMessaging" .../>`.  
Além disso, no Android 13+ você precisa pedir permissão de notificações para exibir a notificação do foreground service.

### Exemplo (ajuste no seu manifest)
Abra: `android/app/src/main/AndroidManifest.xml`

**Fora da tag `<application>`**, garanta permissões:
- `android.permission.INTERNET`
- `android.permission.POST_NOTIFICATIONS` (Android 13+)
- `android.permission.FOREGROUND_SERVICE`
- `android.permission.FOREGROUND_SERVICE_DATA_SYNC`
- `android.permission.WAKE_LOCK`

**Dentro da tag `<application>`**, adicione o service do plugin (não mude o nome):
```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:exported="false"
    android:foregroundServiceType="dataSync|remoteMessaging" />
```

> Observação: o plugin também comenta que no Android 14+ é obrigatório declarar `android:foregroundServiceType`.  

## O que já está migrado
- **Buscar character** (TibiaData v4) + shared XP range
- **Favoritos**
- **Notificações** (online/offline, death, level up) via **foreground service** (Android)
- **Bosses (ExevoPan)** + dropdown “sem estourar” a tela
- **Boosted** (TibiaData)
- **Stamina**, **Hunt Analyzer**, **Exercise Training**, **Imbuements** (offline, JSON)

## Notas importantes (sobre “notificações não chegando”)
No Flutter eu resolvi usando **foreground service** (o Android mantém o processo vivo, mas mostra uma notificação fixa).  
Isso costuma ser o jeito mais confiável para “monitorar em tempo quase real” (sem depender do mínimo de 15 min de jobs/WorkManager).

No app:
- Vá em **Favoritos** → ligue **“Notificações (monitor em segundo plano)”**
- Ajuste o intervalo (padrão 60s) e use **“Testar agora”** para validar.

Se ainda falhar em alguns aparelhos, quase sempre é **otimização agressiva de bateria** do fabricante.

