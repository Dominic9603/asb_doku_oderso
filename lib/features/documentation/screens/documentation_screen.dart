import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../export/services/pdf_share_service.dart';
import '../models/mission.dart';
import '../providers/mission_provider.dart';
import '../widgets/patient_data_tab.dart';
import '../widgets/c_abcde_tab.dart';
import '../widgets/measures_tab.dart';
import '../widgets/vital_signs_tab.dart';
import '../../isbar/screens/isbar_screen.dart';
import '../../isbar/providers/isbar_provider.dart';
import '../../../core/utils/top_notification.dart';

class DocumentationScreen extends StatefulWidget {
  final String missionId;

  const DocumentationScreen({super.key, required this.missionId});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MissionProvider>().loadMission(widget.missionId);
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _completeMission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Einsatz abschließen'),
        content: const Text(
          'Möchten Sie diesen Einsatz wirklich abschließen?\n\n'
          'Der Einsatz kann danach nicht mehr bearbeitet werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Abschließen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<MissionProvider>().completeMission();
      if (mounted) {
        Navigator.of(context).pop();
        TopNotification.show(
          'Einsatz erfolgreich abgeschlossen',
          backgroundColor: AppColors.success,
        );
      }
    }
  }

  Future<void> _editMissionNumber(Mission mission) async {
    final controller = TextEditingController(text: mission.missionNumber ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einsatznummer bearbeiten'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Einsatznummer',
            hintText: 'z.B. 2026-001',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await context.read<MissionProvider>().updateMissionNumber(
            result.isEmpty ? null : result,
          );
      setState(() {});
      TopNotification.show(
        'Einsatznummer aktualisiert',
        backgroundColor: AppColors.success,
      );
    }
  }

  /// PDF generieren und nativen Teilen-Dialog öffnen
  Future<void> _sendPdfViaEmail() async {
    try {
      final provider = context.read<MissionProvider>();
      final mission = provider.currentMission;
      if (mission == null) return;

      // Lade UserInfo
      final licenseService = context.read<LicenseService>();
      final userInfo = await licenseService.getUserInfo();

      // Ladeindikator
      if (mounted) {
        TopNotification.show(
          'PDF wird erstellt…',
          leading: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black87,
          duration: null,
        );
      }

      // PDF-Bytes generieren (mit automatisch generierter Passwort-PIN
      // verschlüsselt, damit die Datei nicht ungeschützt verschickt wird)
      final isbarProvider = context.read<ISBARProvider>();
      await isbarProvider.loadForMission(mission.id);
      final pdfPassword = PDFExportService.generatePassword();
      final pdfBytes = await PDFExportService.generatePdfBytes(
        mission: mission,
        patient: provider.currentPatient,
        abcdeAssessments: provider.abcdeAssessments,
        vitalSigns: provider.vitalSigns,
        measures: provider.measures,
        userInfo: userInfo,
        isbar: isbarProvider.current,
        password: pdfPassword,
      );

      if (mounted) {
        TopNotification.hide();
      }

      if (!mounted) return;
      final shouldContinue = await _showPdfPasswordDialog(pdfPassword);
      if (shouldContinue != true) return;

      final missionNr = mission.missionNumber ?? mission.id.substring(0, 8);

      // Teilen-Dialog öffnen
      await PdfShareService.sharePdf(
        pdfBytes: pdfBytes,
        missionNumber: missionNr,
      );
    } catch (e) {
      if (mounted) {
        TopNotification.hide();
        TopNotification.show(
          'Fehler beim Erstellen der PDF: $e',
          backgroundColor: AppColors.critical,
          duration: const Duration(milliseconds: 2400),
        );
      }
    }
  }

  /// Zeigt die automatisch generierte PDF-Passwort-PIN an, bevor die Datei
  /// geteilt wird. Der Code soll getrennt vom PDF (z.B. telefonisch) an den
  /// Empfänger weitergegeben werden, damit die Datei geöffnet werden kann.
  Future<bool?> _showPdfPasswordDialog(String password) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PDF ist passwortgeschützt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dieses Einsatzbericht-PDF ist mit folgendem Code '
              'verschlüsselt. Teile ihn auf einem anderen Weg '
              '(z.B. telefonisch) mit dem Empfänger – nicht zusammen mit '
              'der Datei selbst:',
            ),
            const SizedBox(height: 16),
            Center(
              child: SelectableText(
                password,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              TopNotification.show('Code kopiert');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Kopieren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Weiter zum Teilen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;

    if (mission == null) {
      return const Scaffold(body: Center(child: Text('Kein Einsatz geladen')));
    }

    final isCompleted = mission.status == MissionStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: isCompleted ? null : () => _editMissionNumber(mission),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mission.missionNumber ??
                    'Einsatz ${mission.id.substring(0, 8)}',
              ),
              if (!isCompleted) ...[
                const SizedBox(width: 6),
                const Icon(Icons.edit, size: 16, color: Colors.white70),
              ],
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Patient'),
            Tab(icon: Icon(Icons.monitor_heart), text: 'cABCDE'),
            Tab(icon: Icon(Icons.favorite), text: 'Vitalparameter'),
            Tab(icon: Icon(Icons.medical_services), text: 'Maßnahmen'),
          ],
        ),
        actions: [
          // PDF teilen (passwortgeschützt, PIN wird vor dem Teilen angezeigt)
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'PDF teilen (passwortgeschützt)',
            onPressed: _sendPdfViaEmail,
          ),
          // ISBAR-Icon
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'ISBAR',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ISBARScreen(missionId: widget.missionId),
                ),
              );
            },
          ),
          if (!isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _completeMission,
              tooltip: 'Einsatz abschließen',
            ),
        ],
      ),
      body: Column(
        children: [
          if (isCompleted)
            Container(
              width: double.infinity,
              color: AppColors.success.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Einsatz abgeschlossen – nur Ansicht. Es ist nur noch das Versenden des Einsatzberichtes möglich.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: AbsorbPointer(
              absorbing: isCompleted,
              child: TabBarView(
                controller: _tabController,
                // Nicht wischbar: verhindert Gesten-Konflikt mit der inneren
                // cABCDE-TabBarView, die per Wischen navigierbar sein soll.
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  PatientDataTab(),
                  CABCDENavTab(),
                  VitalSignsTab(),
                  MeasuresTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
