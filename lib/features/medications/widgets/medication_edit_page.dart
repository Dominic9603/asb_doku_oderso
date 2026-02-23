import 'package:flutter/material.dart';
import 'package:rescue_doc/core/services/database_service.dart';
import 'package:rescue_doc/features/medications/models/medication.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class MedicationEditPage extends StatefulWidget {
  final Medication? initial; // null = neu, sonst bearbeiten

  const MedicationEditPage({super.key, this.initial});

  @override
  State<MedicationEditPage> createState() => _MedicationEditPageState();
}

class _MedicationEditPageState extends State<MedicationEditPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tradeNameController;
  late final TextEditingController _activeIngredientController;
  late final TextEditingController _indicationsController;
  late final TextEditingController _contraindicationsController;
  late final TextEditingController _dosageController;
  late final TextEditingController _adultDoseController;
  late final TextEditingController _childDoseController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;

  bool _forSectionCritical = false; // c - Critical Bleeding
  bool _forSectionB = true;
  bool _forSectionC = true;
  bool _forSectionD = false;
  bool _forSectionE = false;
  bool _forSectionA = false; // Airway
  bool _forSectionCPR = false; // CPR

  // Applikationsformen als Auswahl statt Freitext
  final List<String> _routes = [
    'i.v.',
    'i.o.',
    'i.m.',
    'nasal',
    'oral',
    'inhalativ',
    'bukkal',
  ];
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    final med = widget.initial;

    _tradeNameController = TextEditingController(text: med?.name ?? '');
    _activeIngredientController =
        TextEditingController(text: med?.activeIngredient ?? '');
    _indicationsController =
        TextEditingController(text: med?.indications ?? '');
    _contraindicationsController =
        TextEditingController(text: med?.contraindications ?? '');
    _dosageController = TextEditingController(text: med?.dosage ?? '');
    _adultDoseController = TextEditingController(text: med?.adultDose ?? '');
    _childDoseController = TextEditingController(text: med?.childDose ?? '');
    _categoryController = TextEditingController(text: med?.category ?? '');
    _notesController = TextEditingController(text: med?.notes ?? '');

    _selectedRoute = med?.applicationRoute;

    final sections =
        (med?.sectionsCsv ?? '').split(',').map((e) => e.trim().toUpperCase()).toSet();
    if (sections.isNotEmpty) {
      _forSectionCritical = sections.contains('CRITICAL');
      _forSectionA = sections.contains('A');
      _forSectionB = sections.contains('B');
      _forSectionC = sections.contains('C');
      _forSectionD = sections.contains('D');
      _forSectionE = sections.contains('E');
      _forSectionCPR = sections.contains('CPR');
    }
  }

  @override
  void dispose() {
    _tradeNameController.dispose();
    _activeIngredientController.dispose();
    _indicationsController.dispose();
    _contraindicationsController.dispose();
    _dosageController.dispose();
    _adultDoseController.dispose();
    _childDoseController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sections = <String>[];
    if (_forSectionCritical) sections.add('critical');
    if (_forSectionA) sections.add('A');
    if (_forSectionB) sections.add('B');
    if (_forSectionC) sections.add('C');
    if (_forSectionD) sections.add('D');
    if (_forSectionE) sections.add('E');
    if (_forSectionCPR) sections.add('CPR');

    final id = widget.initial?.id ?? const Uuid().v4();

    final med = Medication(
      id: id,
      name: _tradeNameController.text.trim(),
      activeIngredient: _activeIngredientController.text.trim().isEmpty
          ? _tradeNameController.text.trim()
          : _activeIngredientController.text.trim(),
      adultDose: _adultDoseController.text.trim().isEmpty
          ? null
          : _adultDoseController.text.trim(),
      childDose: _childDoseController.text.trim().isEmpty
          ? null
          : _childDoseController.text.trim(),
      indications: _indicationsController.text.trim().isEmpty
          ? null
          : _indicationsController.text.trim(),
      contraindications: _contraindicationsController.text.trim().isEmpty
          ? null
          : _contraindicationsController.text.trim(),
      applicationRoute: _selectedRoute,
      dosage: _dosageController.text.trim().isEmpty
          ? null
          : _dosageController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      sectionsCsv: sections.isEmpty ? null : sections.join(','),
    );
    try {
      await DatabaseService.instance.insertMedication(med);

      if (!mounted) return;
      Navigator.of(context).pop(med);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditing ? 'Medikament bearbeiten' : 'Medikament hinzufügen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _tradeNameController,
                decoration: const InputDecoration(
                  labelText: 'Handelsname',
                  hintText: 'z.B. Dormicum',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte Handelsnamen eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _activeIngredientController,
                decoration: const InputDecoration(
                  labelText: 'Wirkstoff',
                  hintText: 'z.B. Midazolam',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _indicationsController,
                decoration: const InputDecoration(
                  labelText: 'Indikationen',
                  hintText: 'z.B. Krampfanfall, Sedierung...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contraindicationsController,
                decoration: const InputDecoration(
                  labelText: 'Kontraindikationen',
                  hintText: 'z.B. Allergie gegen Benzodiazepine...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Applikationsform als Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRoute,
                decoration: const InputDecoration(
                  labelText: 'Applikation',
                  prefixIcon: Icon(Icons.route),
                ),
                items: _routes
                    .map(
                      (r) => DropdownMenuItem<String>(
                        value: r,
                        child: Text(r),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoute = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosierung',
                  hintText: 'z.B. 0,1 mg/kg i.v. langsam...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adultDoseController,
                decoration: const InputDecoration(
                  labelText: 'Standarddosis Erwachsener (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _childDoseController,
                decoration: const InputDecoration(
                  labelText: 'Standarddosis Kind (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  hintText: 'z.B. Analgetikum, Sedativum, Reanimation...',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notizen / Hinweise',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text('Verwendung in Abschnitten:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSectionToggle('c', _forSectionCritical, (v) => setState(() => _forSectionCritical = v)),
                  _buildSectionToggle('A', _forSectionA, (v) => setState(() => _forSectionA = v)),
                  _buildSectionToggle('B', _forSectionB, (v) => setState(() => _forSectionB = v)),
                  _buildSectionToggle('C', _forSectionC, (v) => setState(() => _forSectionC = v)),
                  _buildSectionToggle('D', _forSectionD, (v) => setState(() => _forSectionD = v)),
                  _buildSectionToggle('E', _forSectionE, (v) => setState(() => _forSectionE = v)),
                  _buildSectionToggle('CPR', _forSectionCPR, (v) => setState(() => _forSectionCPR = v)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionToggle(String label, bool selected, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.orange.shade700 : Colors.grey.shade200,
          border: Border.all(
            color: selected ? Colors.orange.shade900 : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
