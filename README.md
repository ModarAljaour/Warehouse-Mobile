# WarehouseTwin Mobile

Android Flutter client for the warehouse digital twin. The application is an
independent project and does not modify the Unity project or FastAPI backend.

## Production services

- REST API: `https://api.syrian-dev.com`
- WebSocket: `wss://api.syrian-dev.com/ws/sensors`

The app uses REST for login, snapshots, refresh, and control commands. It uses
WebSocket for live telemetry and alerts, with periodic REST refresh as a
fallback when the socket is unavailable.

## Main features

- Arabic right-to-left interface
- Dashboard for machines, AGVs, forklift, sensors, weights, and alerts
- Six environmental sensors with temperature and humidity
- Interactive sensor history with selectable time ranges and metrics
- Per-device start/stop controls
- Global stop, resume, reset, and robot charging commands
- Online, offline, pending-command, and reconnecting states
- Firebase Cloud Messaging notifications through the `warehouse_alerts` topic

## Run and build

```powershell
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --release
```

The release APK is generated at
`build/app/outputs/flutter-apk/app-release.apk`.

## Configuration

The production base URL is defined in `lib/services/api_service.dart`.
Android network access is enabled through the `INTERNET` permission in
`android/app/src/main/AndroidManifest.xml`.

Download the Android Firebase configuration for package
`com.modar.warehouse.warehouse_mobile` and place it locally at
`android/app/google-services.json`. This file is intentionally excluded from
Git.

The mobile app subscribes to `warehouse_alerts`. Firebase Admin service-account
credentials are server-side secrets and must never be stored in this
repository.
