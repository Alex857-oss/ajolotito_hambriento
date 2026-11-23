// Configura Android (Ronda 1 del manual) después de `flutter create .`
// Uso:  dart tool/configurar.dart
// Es seguro correrlo varias veces: no duplica nada.
import 'dart:io';

const permisos = '''
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

''';

const receptores = '''

        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
''';

void main() {
  if (!Directory('android').existsSync()) {
    stderr.writeln('No existe la carpeta android/. Corre primero: flutter create .');
    exit(1);
  }

  // 1) AndroidManifest.xml
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  var m = manifest.readAsStringSync();
  if (!m.contains('POST_NOTIFICATIONS')) {
    m = m.replaceFirst('<application', '${permisos.trimLeft()}    <application');
    print('Manifest: permisos agregados');
  }
  if (!m.contains('ScheduledNotificationReceiver')) {
    m = m.replaceFirst('</application>', '$receptores    </application>');
    print('Manifest: receptores agregados');
  }
  manifest.writeAsStringSync(m);

  // 2) build.gradle(.kts) de la app: desugaring
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    var g = kts.readAsStringSync();
    if (!g.contains('isCoreLibraryDesugaringEnabled')) {
      g = g.replaceFirst('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
    }
    if (!g.contains('coreLibraryDesugaring(')) {
      g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n';
    }
    kts.writeAsStringSync(g);
    print('build.gradle.kts: desugaring listo');
  } else if (groovy.existsSync()) {
    var g = groovy.readAsStringSync();
    if (!g.contains('coreLibraryDesugaringEnabled')) {
      g = g.replaceFirst('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true');
    }
    if (!g.contains('coreLibraryDesugaring ')) {
      g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n";
    }
    groovy.writeAsStringSync(g);
    print('build.gradle: desugaring listo');
  } else {
    stderr.writeln('No encontré android/app/build.gradle(.kts)');
    exit(1);
  }

  // 3) flutter create trae una prueba de ejemplo que ya no aplica
  final ejemplo = File('test/widget_test.dart');
  if (ejemplo.existsSync()) {
    ejemplo.deleteSync();
    print('Borré test/widget_test.dart (prueba de ejemplo de flutter create)');
  }

  print('Listo. Siguiente: flutter pub get && flutter test');
}
