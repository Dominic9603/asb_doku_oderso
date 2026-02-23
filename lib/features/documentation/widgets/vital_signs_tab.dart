import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/mission_provider.dart';
import '../models/vital_signs.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class VitalSignsTab extends StatefulWidget {
  const VitalSignsTab({super.key});

  @override
  State<VitalSignsTab> createState() => _VitalSignsTabState();
}

class _VitalSignsTabState extends State<VitalSignsTab> {
  final _hfController = TextEditingController();
  final _afController = TextEditingController();
  final _rrSysController = TextEditingController();
  final _rrDiaController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _bzController = TextEditingController();

  bool _hfNotMeasured = false;
  bool _afNotMeasured = false;
  bool _rrNotMeasured = false;
  bool _spo2NotMeasured = false;
  bool _bzNotMeasured = false;

  @override
  void initState() {
    super.initState();
    // bewusst leer: Tab startet immer mit leeren Feldern
  }

  @override
  void dispose() {
    _hfController.dispose();
    _afController.dispose();
    _rrSysController.dispose();
    _rrDiaController.dispose();
    _spo2Controller.dispose();
    _bzController.dispose();
    super.dispose();
  }

  double? _parseSpo2() {
    if (_spo2NotMeasured || _spo2Controller.text.isEmpty) return null;
    final value =
        double.tryParse(_spo2Controller.text.replaceAll(',', '.'));
    if (value == null) return null;
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  Future<void> _save() async {
    final provider = context.read<MissionProvider>();
    final mission = provider.currentMission;
    if (mission == null) return;

    final vital = VitalSigns.create(mission.id).copyWith(
      heartRate: _hfNotMeasured || _hfController.text.isEmpty
          ? null
          : int.parse(_hfController.text),
      systolicBP: _rrNotMeasured || _rrSysController.text.isEmpty
          ? null
          : int.parse(_rrSysController.text),
      diastolicBP: _rrNotMeasured || _rrDiaController.text.isEmpty
          ? null
          : int.parse(_rrDiaController.text),
      respiratoryRate: _afNotMeasured || _afController.text.isEmpty
          ? null
          : int.parse(_afController.text),
      spo2: _parseSpo2(),
      bloodSugar: _bzNotMeasured || _bzController.text.isEmpty
          ? null
          : double.parse(_bzController.text),
    );

    await provider.addVitalSigns(vital);

    if (!mounted) return;

    setState(() {
      _hfController.clear();
      _afController.clear();
      _rrSysController.clear();
      _rrDiaController.clear();
      _spo2Controller.clear();
      _bzController.clear();

      _hfNotMeasured = false;
      _afNotMeasured = false;
      _rrNotMeasured = false;
      _spo2NotMeasured = false;
      _bzNotMeasured = false;
    });

    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Vitalparameter gespeichert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vitalparameter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aktuelle Messwerte, nicht gemessene Werte mit rotem X kennzeichnen.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                _buildVitalRow(
                  label: 'Herzfrequenz',
                  controller: _hfController,
                  unit: '/min',
                  notMeasured: _hfNotMeasured,
                  onToggleNotMeasured: (v) {
                    setState(() {
                      _hfNotMeasured = v;
                      if (v) _hfController.clear();
                    });
                  },
                ),
                const SizedBox(height: 12),

                _buildVitalRow(
                  label: 'Atemfrequenz',
                  controller: _afController,
                  unit: '/min',
                  notMeasured: _afNotMeasured,
                  onToggleNotMeasured: (v) {
                    setState(() {
                      _afNotMeasured = v;
                      if (v) _afController.clear();
                    });
                  },
                ),
                const SizedBox(height: 12),

                _buildBpRow(),
                const SizedBox(height: 12),

                _buildVitalRow(
                  label: 'SpO₂',
                  controller: _spo2Controller,
                  unit: '%',
                  notMeasured: _spo2NotMeasured,
                  onToggleNotMeasured: (v) {
                    setState(() {
                      _spo2NotMeasured = v;
                      if (v) _spo2Controller.clear();
                    });
                  },
                  isSpo2: true,
                ),
                const SizedBox(height: 12),

                _buildVitalRow(
                  label: 'Blutzucker',
                  controller: _bzController,
                  unit: 'mg/dl',
                  notMeasured: _bzNotMeasured,
                  onToggleNotMeasured: (v) {
                    setState(() {
                      _bzNotMeasured = v;
                      if (v) _bzController.clear();
                    });
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Vitalparameter speichern'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalRow({
    required String label,
    required TextEditingController controller,
    required String unit,
    required bool notMeasured,
    required ValueChanged<bool> onToggleNotMeasured,
    bool isSpo2 = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              suffixText: unit,
            ),
            enabled: !notMeasured,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: isSpo2
                ? (value) {
                    final v = double.tryParse(
                      value.replaceAll(',', '.'),
                    );
                    if (v != null && v > 100) {
                      controller.text = '100';
                      controller.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => onToggleNotMeasured(!notMeasured),
          icon: Icon(
            Icons.close,
            color: notMeasured ? Colors.red : Colors.grey,
          ),
          tooltip: 'Nicht gemessen',
        ),
      ],
    );
  }

  Widget _buildBpRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _rrSysController,
            decoration: const InputDecoration(
              labelText: 'RR syst.',
              suffixText: 'mmHg',
            ),
            enabled: !_rrNotMeasured,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _rrDiaController,
            decoration: const InputDecoration(
              labelText: 'RR diast.',
              suffixText: 'mmHg',
            ),
            enabled: !_rrNotMeasured,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            setState(() {
              _rrNotMeasured = !_rrNotMeasured;
              if (_rrNotMeasured) {
                _rrSysController.clear();
                _rrDiaController.clear();
              }
            });
          },
          icon: Icon(
            Icons.close,
            color: _rrNotMeasured ? Colors.red : Colors.grey,
          ),
          tooltip: 'Nicht gemessen',
        ),
      ],
    );
  }
}
