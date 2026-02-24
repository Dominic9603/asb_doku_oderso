import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/theme_provider.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/update_dialog.dart';
import '../../../core/services/update_service.dart';
import '../providers/mission_provider.dart';
import '../models/mission.dart';
import 'documentation_screen.dart'; 

class MissionListScreen extends StatefulWidget {
  const MissionListScreen({super.key});

  @override
  State<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends State<MissionListScreen> {
  @override
  void initState() {
    super.initState();
    // Daten beim Öffnen des Screens laden
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MissionProvider>().refresh();
      if (mounted) setState(() {});
      // Update-Check im Hintergrund (nur Android)
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    try {
      final service = UpdateService();
      final info = await service.checkForUpdate();
      if (info != null && mounted) {
        await UpdateDialog.show(context, info, service);
      }
    } catch (_) {
      // Fehler beim Update-Check still ignorieren
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MissionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RescueDoc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            tooltip: 'Nachtmodus',
            onPressed: () {
              context.read<ThemeProvider>().toggle();
            },
          ),
          IconButton(
            icon: const Icon(Icons.medical_information),
            onPressed: () {
              Navigator.pushNamed(context, '/medications');
            },
            tooltip: 'Medikamente',
          ),
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () {
              Navigator.pushNamed(context, '/guidelines');
            },
            tooltip: 'Richtlinien',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Benutzerdaten',
          ),
        ],
      ),
      body: _buildBody(context, provider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/new-mission');
          // Nach Rückkehr von new-mission aktualisieren
          if (mounted) {
            await provider.refresh();
            if (mounted) setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Neuer Einsatz'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MissionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Einsätze vorhanden',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Starten Sie einen neuen Einsatz',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refresh();
        if (mounted) setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.missions.length,
        itemBuilder: (context, index) {
          final mission = provider.missions[index];
          return _MissionCard(
            mission: mission,
            onReturn: () async {
              // Nach Rückkehr von Documentation aktualisieren
              await provider.refresh();
              if (mounted) setState(() {});
            },
          );
        },
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback? onReturn;
  
  const _MissionCard({required this.mission, this.onReturn});
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
         await Navigator.push(
           context,
           MaterialPageRoute(
               builder: (context) => DocumentationScreen(missionId: mission.id),
           ),
         );
         onReturn?.call();
        },
  borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(mission.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getStatusColor(mission.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusText(mission.status),
                      style: TextStyle(
                        color: _getStatusColor(mission.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (mission.missionNumber != null)
                    Text(
                      'Nr. ${mission.missionNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ${dateFormat.format(mission.startTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (mission.endTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Ende: ${dateFormat.format(mission.endTime!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.active:
        return AppColors.success;
      case MissionStatus.completed:
        return AppColors.info;
      case MissionStatus.archived:
        return AppColors.textSecondaryLight;
    }
  }
  
  String _getStatusText(MissionStatus status) {
    switch (status) {
      case MissionStatus.active:
        return 'AKTIV';
      case MissionStatus.completed:
        return 'ABGESCHLOSSEN';
      case MissionStatus.archived:
        return 'ARCHIVIERT';
    }
  }
}
