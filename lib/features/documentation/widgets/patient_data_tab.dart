import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../providers/mission_provider.dart';
import '../models/patient.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

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
  
  // SAMPLER
  late TextEditingController _symptomsController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _pastMedicalHistoryController;
  late TextEditingController _lastOralIntakeController;
  late TextEditingController _eventsController;
  late TextEditingController _riskFactorsController;
  
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
    
    _symptomsController = TextEditingController(text: patient?.symptoms);
    _allergiesController = TextEditingController(text: patient?.allergies);
    _medicationsController = TextEditingController(text: patient?.medications);
    _pastMedicalHistoryController = TextEditingController(text: patient?.pastMedicalHistory);
    _lastOralIntakeController = TextEditingController(text: patient?.lastOralIntake);
    _eventsController = TextEditingController(text: patient?.eventsLeadingToIllness);
    _riskFactorsController = TextEditingController(text: patient?.riskFactors);
    
    _selectedDateOfBirth = patient?.dateOfBirth;
    _selectedGender = patient?.gender;
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _insuranceController.dispose();
    _symptomsController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _pastMedicalHistoryController.dispose();
    _lastOralIntakeController.dispose();
    _eventsController.dispose();
    _riskFactorsController.dispose();
    super.dispose();
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
      firstName: _firstNameController.text.isEmpty ? null : _firstNameController.text,
      lastName: _lastNameController.text.isEmpty ? null : _lastNameController.text,
      dateOfBirth: _selectedDateOfBirth,
      gender: _selectedGender,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      insurance: _insuranceController.text.isEmpty ? null : _insuranceController.text,
      symptoms: _symptomsController.text.isEmpty ? null : _symptomsController.text,
      allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
      medications: _medicationsController.text.isEmpty ? null : _medicationsController.text,
      pastMedicalHistory: _pastMedicalHistoryController.text.isEmpty ? null : _pastMedicalHistoryController.text,
      lastOralIntake: _lastOralIntakeController.text.isEmpty ? null : _lastOralIntakeController.text,
      eventsLeadingToIllness: _eventsController.text.isEmpty ? null : _eventsController.text,
      riskFactors: _riskFactorsController.text.isEmpty ? null : _riskFactorsController.text,
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
                  
                  InkWell(
                    onTap: _selectDateOfBirth,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Geburtsdatum',
                        prefixIcon: Icon(Icons.cake),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDateOfBirth != null
                            ? DateFormat('dd.MM.yyyy').format(_selectedDateOfBirth!)
                            : 'Nicht angegeben',
                        style: TextStyle(
                          color: _selectedDateOfBirth != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<Gender>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Geschlecht',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(value: Gender.male, child: Text('Männlich')),
                      DropdownMenuItem(value: Gender.female, child: Text('Weiblich')),
                      DropdownMenuItem(value: Gender.diverse, child: Text('Divers')),
                      DropdownMenuItem(value: Gender.unknown, child: Text('Unbekannt')),
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
          
          // SAMPLER Schema
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SAMPLER Schema',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Anamnese',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSAMPLERField(
                    controller: _symptomsController,
                    label: 'S - Symptoms (Symptome)',
                    hint: 'Hauptbeschwerde, Leitsymptom',
                    icon: Icons.sick,
                    noneText: 'Keine aktuellen Beschwerden',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSAMPLERField(
                    controller: _allergiesController,
                    label: 'A - Allergies (Allergien)',
                    hint: 'Bekannte Allergien',
                    icon: Icons.coronavirus,
                    noneText: 'Keine bekannten Allergien',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSAMPLERField(
                    controller: _medicationsController,
                    label: 'M - Medications (Medikamente)',
                    hint: 'Aktuelle Medikation',
                    icon: Icons.medication,
                    noneText: 'Keine regelmäßige Medikation',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSAMPLERField(
                    controller: _pastMedicalHistoryController,
                    label: 'P - Past Medical History (Vorerkrankungen)',
                    hint: 'Relevante Vorerkrankungen',
                    icon: Icons.history,
                    noneText: 'Keine relevanten Vorerkrankungen bekannt',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSAMPLERField(
                    controller: _lastOralIntakeController,
                    label: 'L - Last Oral Intake (Letzte Nahrungsaufnahme)',
                    hint: 'Zeitpunkt und Art',
                    icon: Icons.restaurant,
                    noneText: 'Nicht erhoben',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSAMPLERField(
                    controller: _eventsController,
                    label: 'E - Events (Ereignisse)',
                    hint: 'Ereignisse die zum aktuellen Zustand führten',
                    icon: Icons.event,
                    noneText: 'Keine besonderen Ereignisse berichtet',
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSAMPLERField(
                    controller: _riskFactorsController,
                    label: 'R - Risk Factors (Risikofaktoren)',
                    hint: 'Weitere Risikofaktoren',
                    icon: Icons.warning_amber,
                    noneText: 'Keine relevanten Risikofaktoren bekannt',
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
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildSAMPLERField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String noneText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
        suffixIcon: TextButton(
          onPressed: () {
            setState(() {
              controller.text = noneText;
            });
          },
          child: const Text('Keine'),
        ),
      ),
      maxLines: 3,
      minLines: 1,
    );
  }
}
