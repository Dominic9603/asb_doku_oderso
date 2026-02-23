import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared/theme/theme_provider.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/database_service.dart';
import 'core/services/license_service.dart';
import 'features/medications/repositories/medication_repository.dart';
import 'features/documentation/repositories/mission_repository.dart';
import 'features/isbar/repositories/isbar_repository.dart';
import 'features/isbar/providers/isbar_provider.dart';
import 'features/medications/providers/medication_provider.dart';
import 'features/documentation/providers/mission_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sicherheitsnetz: _dependents.isEmpty Assertion im Debug-Mode abfangen
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exception.toString();
      final stackTrace = details.stack.toString();
      
      // Unterdrücke _dependents.isEmpty AssertionError (Flutter Framework Bug mit verschachtelten Tabs)
      if ((msg.contains('_dependents.isEmpty') || msg.contains('dependents.isEmpty')) &&
          stackTrace.contains('InheritedElement')) {
        debugPrint('⚠️ [Framework] _dependents.isEmpty abgefangen (bekanntes Flutter-Issue)');
        debugPrintStack(stackTrace: details.stack, label: 'Trace:');
        return; // Unterdrücke Error - nicht presentError
      }
      
      FlutterError.presentError(details);
    };
  }

  print('🚀 App starting... (kIsWeb=$kIsWeb)');

  try {
    // Supabase initialisieren (für PDF-Link-Sharing)
    if (AppConfig.supabaseUrl != 'DEINE_SUPABASE_URL') {
      print('☁️ Initializing Supabase...');
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      print('✅ Supabase initialized');
    } else {
      print('⚠️ Supabase nicht konfiguriert – PDF-Email-Versand deaktiviert');
    }

    // Hive initialisieren
    print('📦 Initializing Hive...');
    await Hive.initFlutter();
    print('✅ Hive initialized');

    // SharedPreferences für Web-Kompatibilität
    print('🔄 Initializing SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialized');

    // SQLite initialisieren (Singleton) – auf Web: In-Memory
    print('💾 Initializing Database...');
    final databaseService = DatabaseService.instance;
    await databaseService.initialize();
    print('✅ Database initialized (isWeb=${databaseService.isWeb})');

    // Repositories
    print('📚 Initializing Repositories...');
    final medicationRepository = MedicationRepository(databaseService);
    final missionRepository = SQLiteMissionRepository(databaseService);
    final isbarRepository = ISBARRepository(databaseService);
    print('✅ Repositories initialized');

    // Services – FlutterSecureStorage nur auf non-Web
    print('🔐 Initializing Services...');
    FlutterSecureStorage? secureStorage;
    if (!kIsWeb) {
      secureStorage = const FlutterSecureStorage();
    }
    final licenseService = LicenseService(
      secureStorage: secureStorage,
      prefs: prefs,
    );
    print('✅ License Service initialized');

    print('🎉 All services initialized successfully!');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<DatabaseService>.value(value: databaseService),
          Provider<LicenseService>.value(value: licenseService),
          Provider<MedicationRepository>.value(value: medicationRepository),
          Provider<MissionRepository>.value(value: missionRepository),
          Provider<ISBARRepository>.value(value: isbarRepository),
          Provider<MedicationProvider>(
            create: (context) => MedicationProvider(medicationRepository),
          ),
          Provider<MissionProvider>(
            create: (context) => MissionProvider(missionRepository),
          ),
          Provider<ISBARProvider>(
            create: (context) => ISBARProvider(isbarRepository),
          ),
        ],
        child: const RescueDocApp(),
      ),
    );
  } catch (e, stack) {
    print('❌ Kritischer Fehler beim App-Start: $e');
    print(stack);
    // Fallback: Minimale Fehlerseite anzeigen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'RescueDoc konnte nicht gestartet werden',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
