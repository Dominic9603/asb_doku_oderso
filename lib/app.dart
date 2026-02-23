import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/services/license_service.dart';
import 'core/utils/scaffold_messenger_key.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_provider.dart';
import 'features/authentication/screens/activation_screen.dart';
import 'features/authentication/screens/setup_screen.dart';
import 'features/documentation/screens/mission_list_screen.dart';
import 'features/documentation/screens/new_mission_screen.dart';
import 'features/medications/screens/medication_list_screen.dart';
import 'features/guidelines/screens/guidelines_screen.dart';


class RescueDocApp extends StatefulWidget {
  const RescueDocApp({super.key});

  @override
  State<RescueDocApp> createState() => _RescueDocAppState();
}

class _RescueDocAppState extends State<RescueDocApp> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'RescueDoc',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.mode,
      
      // Localizations hinzufügen
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'),
        Locale('en', 'US'),
      ],
      locale: const Locale('de', 'DE'),
      
      home: _buildHome(context),
      routes: {
        '/missions': (context) => const MissionListScreen(),
        '/new-mission': (context) => const NewMissionScreen(),
        '/medications': (context) => const MedicationListScreen(),
        '/guidelines': (context) => const GuidelinesScreen(),
      },
    );
  }

  /// Baut den Home-Screen basierend auf Aktivierungs- und Setup-Status auf
  Widget _buildHome(BuildContext context) {
    final licenseService = context.read<LicenseService>();
    
    return FutureBuilder<List<bool>>(
      future: Future.wait([
        licenseService.isActivated(),
        licenseService.isSetupDone(),
      ]),
      builder: (context, snapshot) {
        // Lade-Zustand
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Fehlerbehandlung
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Fehler beim Laden der App: ${snapshot.error}'),
            ),
          );
        }

        final isActivated = snapshot.data?[0] ?? false;
        final isSetupDone = snapshot.data?[1] ?? false;

        // Routing-Logik:
        // 1. Wenn nicht aktiviert → ActivationScreen (Lizenzschlüssel)
        // 2. Wenn aktiviert aber Setup nicht abgeschlossen → SetupScreen (Personalisierung)
        // 3. Wenn beides erledigt → MissionListScreen (Hauptapp)

        if (!isActivated) {
          return ActivationScreen(
            onActivated: () {
              // Nach Aktivierung neu laden → zeigt SetupScreen
              setState(() {});
            },
          );
        }

        if (!isSetupDone) {
          return SetupScreen(
            licenseService: licenseService,
            onSetupComplete: () {
              // Nach erfolgreicher Personalisierung neu laden
              setState(() {});
            },
          );
        }

        return const MissionListScreen();
      },
    );
  }
}
