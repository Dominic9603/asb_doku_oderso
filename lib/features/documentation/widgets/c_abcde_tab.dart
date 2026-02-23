import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mission_provider.dart';
import '../models/abcde_assessment.dart';
import 'c_tab.dart';
import 'a_tab.dart';
import 'b_tab.dart';
import 'c2_tab.dart';
import 'd_tab.dart';
import 'e_tab.dart';
import 'cpr_tab.dart';

class CABCDENavTab extends StatefulWidget {
  const CABCDENavTab({super.key});

  @override
  State<CABCDENavTab> createState() => _CABCDENavTabState();
}

class _CABCDENavTabState extends State<CABCDENavTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  
  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 7, vsync: this);
  }
  
  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }
  
    bool _isCDone(ABCDEAssessment? a) {
    if (a == null) return false;
    final hasBleeding =
        a.externalBleeding ||
        (a.bleedingLocation != null && a.bleedingLocation!.isNotEmpty) ||
        (a.bleedingControl != null && a.bleedingControl!.isNotEmpty);

    final ci = a.circulationIntervention ?? '';
    final hasCIntervention =
        ci.contains('Zugang (c)') || ci.contains('Medikament c:');

    return hasBleeding || hasCIntervention;
  }

  bool _isADone(ABCDEAssessment? a) {
    if (a == null) return false;
    // Nur das neue Flag aus dem Modell
    return a.aDocumented;
  }

  bool _isBDone(ABCDEAssessment? a) {
    if (a == null) return false;
    final hasValues =
        a.respiratoryRate != null ||
        a.spo2 != null ||
        (a.breathingSounds != null && a.breathingSounds!.isNotEmpty) ||
        (a.breathingIssue != null && a.breathingIssue!.isNotEmpty);

    final bi = a.breathingIntervention ?? '';
    final hasIntervention =
        bi.contains('O2') || bi.contains('Medikament B:');

    return hasValues || hasIntervention;
  }

  bool _isC2Done(ABCDEAssessment? a) {
    if (a == null) return false;
    final hasValues =
        a.heartRate != null ||
        a.systolicBP != null ||
        a.diastolicBP != null ||
        (a.pulseQuality != null && a.pulseQuality!.isNotEmpty) ||
        (a.skinColor != null && a.skinColor!.isNotEmpty) ||
        (a.capillaryRefill != null && a.capillaryRefill!.isNotEmpty) ||
        (a.circulationIssue != null && a.circulationIssue!.isNotEmpty);

    final ci = a.circulationIntervention ?? '';
    final hasIntervention =
        (ci.contains('Zugang:') && !ci.contains('Zugang (c)')) ||
        ci.contains('Medikament C:');

    return hasValues || hasIntervention;
  }

  bool _isDDone(ABCDEAssessment? a) {
    if (a == null) return false;
    return a.gcsEye != null ||
        a.gcsVerbal != null ||
        a.gcsMotor != null ||
        (a.pupilLeft != null && a.pupilLeft!.isNotEmpty) ||
        (a.pupilRight != null && a.pupilRight!.isNotEmpty) ||
        a.bloodSugar != null ||
        (a.disabilityIssue != null && a.disabilityIssue!.isNotEmpty) ||
        (a.disabilityIntervention != null && a.disabilityIntervention!.isNotEmpty);
  }

  bool _isEDone(ABCDEAssessment? a) {
    if (a == null) return false;
    return a.temperature != null ||
        (a.injuries != null && a.injuries!.isNotEmpty) ||
        (a.environmentalFactors != null && a.environmentalFactors!.isNotEmpty) ||
        (a.exposureIssue != null && a.exposureIssue!.isNotEmpty) ||
        (a.exposureIntervention != null && a.exposureIntervention!.isNotEmpty);
  }

  bool _isCPRDone(ABCDEAssessment? a) {
    if (a == null) return false;
    return (a.cprTubusTypes != null && a.cprTubusTypes!.isNotEmpty) ||
        a.cprShocks != null ||
        a.cprROSC == true ||
        (a.cprMedications != null && a.cprMedications!.isNotEmpty);
  }

  
  @override
  Widget build(BuildContext context) {
    final abcde = context.read<MissionProvider>().latestABCDE;
    
    Text _tabLabel(String text, bool done) {
      return Text(
        text,
        style: TextStyle(
          color: done ? Colors.green : null,
          fontWeight: done ? FontWeight.bold : null,
        ),
      );
    }
    
    return Column(
      children: [
        Material(
          color: Theme.of(context).cardColor,
          elevation: 2,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            tabs: [
              Tab(child: _tabLabel('c', _isCDone(abcde))),
              Tab(child: _tabLabel('A', _isADone(abcde))),
              Tab(child: _tabLabel('B', _isBDone(abcde))),
              Tab(child: _tabLabel('C', _isC2Done(abcde))),
              Tab(child: _tabLabel('D', _isDDone(abcde))),
              Tab(child: _tabLabel('E', _isEDone(abcde))),
              Tab(child: _tabLabel('CPR', _isCPRDone(abcde))),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: const [
              CTab(),
              ATab(),
              BTab(),
              C2Tab(),
              DTab(),
              ETab(),
              CPRTab(),
            ],
          ),
        ),
      ],
    );
  }
}
