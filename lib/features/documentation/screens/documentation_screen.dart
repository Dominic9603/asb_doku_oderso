import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../export/services/pdf_share_service.dart';
import '../providers/mission_provider.dart';
import '../widgets/patient_data_tab.dart';
import '../widgets/c_abcde_tab.dart';
import '../widgets/measures_tab.dart';
import '../widgets/vital_signs_tab.dart';
import '../../isbar/screens/isbar_screen.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class DocumentationScreen extends StatefulWidget {
  final String missionId;
  
  const DocumentationScreen({
    super.key,
    required this.missionId,
  });

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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Abschließen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      await context.read<MissionProvider>().completeMission();
      if (mounted) {
        Navigator.of(context).pop();
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Einsatz erfolgreich abgeschlossen'),
            backgroundColor: AppColors.success,
          ),
        );
      }
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
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('PDF wird erstellt…'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // PDF-Bytes generieren
      final pdfBytes = await PDFExportService.generatePdfBytes(
        mission: mission,
        patient: provider.currentPatient,
        abcdeAssessments: provider.abcdeAssessments,
        vitalSigns: provider.vitalSigns,
        measures: provider.measures,
        userInfo: userInfo,
      );

      final missionNr = mission.missionNumber ?? mission.id.substring(0, 8);

      // Teilen-Dialog öffnen
      await PdfShareService.sharePdf(
        pdfBytes: pdfBytes,
        missionNumber: missionNr,
      );

      if (mounted) {
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Fehler beim Erstellen der PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;

    if (mission == null) {
      return const Scaffold(
        body: Center(child: Text('Kein Einsatz geladen')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          mission.missionNumber ?? 'Einsatz ${mission.id.substring(0, 8)}',
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.person),
              text: 'Patient',
            ),
            Tab(
              icon: Icon(Icons.monitor_heart),
              text: 'cABCDE',
            ),
            Tab(icon: Icon(Icons.favorite), text: 'Vitalparameter'),
            Tab(
              icon: Icon(Icons.medical_services),
              text: 'Maßnahmen',
            ),
          ],
        ),
        actions: [
          // PDF per Email senden (30-Min-Link)
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'PDF per Email senden',
            onPressed: _sendPdfViaEmail,
          ),
          // ISBAR-Icon
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'ISBAR',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ISBARScreen(missionId: widget.missionId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _completeMission,
            tooltip: 'Einsatz abschließen',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PatientDataTab(),
          CABCDENavTab(),
          VitalSignsTab(), 
          MeasuresTab(),
        ],
      ),
    );
  }
}
