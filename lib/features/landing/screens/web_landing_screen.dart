import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_theme.dart';

class WebLandingScreen extends StatefulWidget {
  /// Callback zum Starten der eigentlichen App
  final VoidCallback onEnterApp;

  const WebLandingScreen({super.key, required this.onEnterApp});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  // null = Auswahl, 'ios' = iOS-Anleitung, 'android' = Android-Info
  String? _selected;

  static const _apkUrl =
      'https://github.com/Dominic9603/asb_doku_oderso/releases/latest/download/RescueDoc.apk';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Titel
                const Icon(Icons.local_hospital,
                    size: 72, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'RescueDoc',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'Einsatzdokumentation für Notfallsanitäter',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (_selected == null) ...[
                  const Text(
                    'Welches Gerät verwendest du?',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  _PlatformCard(
                    icon: Icons.phone_iphone,
                    title: 'iPhone / iPad',
                    subtitle: 'Web-App zum Home-Bildschirm hinzufügen',
                    onTap: () => setState(() => _selected = 'ios'),
                  ),
                  const SizedBox(height: 12),
                  _PlatformCard(
                    icon: Icons.android,
                    title: 'Android',
                    subtitle: 'App direkt als APK installieren',
                    onTap: () => setState(() => _selected = 'android'),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: widget.onEnterApp,
                    child: const Text(
                      'Direkt zur App →',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],

                if (_selected == 'ios') ...[
                  _InstructionCard(
                    icon: Icons.phone_iphone,
                    title: 'iPhone / iPad – Installation',
                    steps: const [
                      _Step(
                        icon: Icons.open_in_browser,
                        text:
                            'Diese Seite muss in Safari geöffnet sein (nicht Chrome)',
                      ),
                      _Step(
                        icon: Icons.ios_share,
                        text:
                            'Unten auf das Teilen-Symbol tippen\n(Quadrat mit Pfeil nach oben)',
                      ),
                      _Step(
                        icon: Icons.add_box_outlined,
                        text: '„Zum Home-Bildschirm" auswählen',
                      ),
                      _Step(
                        icon: Icons.check_circle_outline,
                        text: 'Mit „Hinzufügen" bestätigen',
                      ),
                    ],
                    hint:
                        'Die App erscheint danach als Icon auf dem Startbildschirm und läuft wie eine native App.',
                    actionLabel: 'Zur App',
                    onAction: widget.onEnterApp,
                    onBack: () => setState(() => _selected = null),
                  ),
                ],

                if (_selected == 'android') ...[
                  _InstructionCard(
                    icon: Icons.android,
                    title: 'Android – APK installieren',
                    steps: const [
                      _Step(
                        icon: Icons.download,
                        text: 'APK über den Button unten herunterladen',
                      ),
                      _Step(
                        icon: Icons.folder_open,
                        text:
                            'Heruntergeladene Datei im Download-Ordner öffnen',
                      ),
                      _Step(
                        icon: Icons.security,
                        text:
                            'Falls gefragt: „Installation aus unbekannten Quellen" einmalig erlauben',
                      ),
                      _Step(
                        icon: Icons.check_circle_outline,
                        text: 'Installieren tippen – fertig!',
                      ),
                    ],
                    hint:
                        'Nach der Installation findest du RescueDoc im App-Drawer. Du bekommst keine automatischen Updates – schau gelegentlich hier nach neuen Versionen.',
                    actionLabel: 'APK herunterladen',
                    actionIcon: Icons.download,
                    onAction: () async {
                      final uri = Uri.parse(_apkUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    secondaryLabel: 'Trotzdem zur Web-App',
                    onSecondary: widget.onEnterApp,
                    onBack: () => setState(() => _selected = null),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hilfwidgets ─────────────────────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String text;
  const _Step({required this.icon, required this.text});
}

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_Step> steps;
  final String hint;
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback onBack;

  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.steps,
    required this.hint,
    required this.actionLabel,
    this.actionIcon,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(e.value.icon,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.value.text,
                                    style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(hint,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.blueGrey))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(actionIcon ?? Icons.check),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onAction,
              ),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(secondaryLabel!),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Zurück'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
