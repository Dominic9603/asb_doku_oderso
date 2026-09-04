import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../providers/mission_provider.dart';
import '../models/patient.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

/// Fügt beim Tippen automatisch Punkte im Format TT.MM.JJJJ ein.
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll('.', '');
    if (digitsOnly.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if (i == 1 || i == 3) {
        if (i != digitsOnly.length - 1) buffer.write('.');
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class PatientDataTab extends StatefulWidget {
  const PatientDataTab({super.key});

  @override
  State<PatientDataTab> createState() => _PatientDataTabState();
}

class _PatientDataTabState extends State<PatientDataTab> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _addressController;
  late TextEditingController _insuranceController;
  late TextEditingController _dobController;

  DateTime? _selectedDateOfBirth;
  Gender? _selectedGender;

  @override
  void initState() {
    super.initState();

    final patient = context.read<MissionProvider>().currentPatient;

    _firstNameController = TextEditingController(text: patient?.firstName);
    _lastNameController = TextEditingController(text: patient?.lastName);
    _addressController = TextEditingController(text: patient?.address);
    _insuranceController = TextEditingController(text: patient?.insurance);

    _selectedDateOfBirth = patient?.dateOfBirth;
    _dobController = TextEditingController(
      text: _selectedDateOfBirth != null
          ? DateFormat('dd.MM.yyyy').format(_selectedDateOfBirth!)
          : '',
    );
    _selectedGender = patient?.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _insuranceController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onDobTextChanged(String value) {
    if (value.length != 10) {
      _selectedDateOfBirth = null;
      return;
    }
    try {
      _selectedDateOfBirth = DateFormat('dd.MM.yyyy').parseStrict(value);
    } catch (_) {
      _selectedDateOfBirth = null;
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MissionProvider>();
    final currentPatient = provider.currentPatient;

    if (currentPatient == null) {
      return;
    }

    final updatedPatient = currentPatient.copyWith(
      firstName:
          _firstNameController.text.isEmpty ? null : _firstNameController.text,
      lastName:
          _lastNameController.text.isEmpty ? null : _lastNameController.text,
      dateOfBirth: _selectedDateOfBirth,
      gender: _selectedGender,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      insurance:
          _insuranceController.text.isEmpty ? null : _insuranceController.text,
    );

    await provider.updatePatient(updatedPatient);

    if (mounted) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Patientendaten gespeichert'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Persönliche Daten
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Persönliche Daten',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Vorname',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nachname',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dobController,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Geburtsdatum',
                      hintText: 'TT.MM.JJJJ',
                      prefixIcon: const Icon(Icons.cake),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDateOfBirth,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(10),
                      _DateInputFormatter(),
                    ],
                    onChanged: _onDobTextChanged,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Gender>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Geschlecht',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: Gender.male,
                        child: Text('Männlich'),
                      ),
                      DropdownMenuItem(
                        value: Gender.female,
                        child: Text('Weiblich'),
                      ),
                      DropdownMenuItem(
                        value: Gender.diverse,
                        child: Text('Divers'),
                      ),
                      DropdownMenuItem(
                        value: Gender.unknown,
                        child: Text('Unbekannt'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      prefixIcon: Icon(Icons.home),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _insuranceController,
                    decoration: const InputDecoration(
                      labelText: 'Krankenkasse',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Hinweis: SAMPLER Schema wurde zu E (Exposure/Environment) verschoben
          Card(
            color: AppColors.info.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Das SAMPLER-Schema (Anamnese) wird jetzt im Tab "cABCDE" unter "E" erfasst.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save Button
          ElevatedButton.icon(
            onPressed: _savePatient,
            icon: const Icon(Icons.save),
            label: const Text('Patientendaten speichern'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
