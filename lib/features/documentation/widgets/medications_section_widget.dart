import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class MedicationsSectionWidget extends StatefulWidget {
  final String title; // z.B. "Medikamente bei A"
  final Color? bgColor; // Optional, defaults to blue.shade50
  final List<Map<String, dynamic>> medications;
  final VoidCallback onMedicationsChanged; // Callback nach Änderungen
  final Function(int)? onRemove; // Optional: Custom remove handler

  const MedicationsSectionWidget({
    super.key,
    required this.title,
    this.bgColor,
    required this.medications,
    required this.onMedicationsChanged,
    this.onRemove,
  });

  @override
  State<MedicationsSectionWidget> createState() =>
      _MedicationsSectionWidgetState();
}

class _MedicationsSectionWidgetState extends State<MedicationsSectionWidget> {

  Future<void> _addMedication() async {
    // Dialog-Kontext SOFORT cachen bevor async Operationen stattfinden
    final dialogContext = context;
    
    final medications = await DatabaseService.instance.getAllMedications();
    if (medications.isEmpty) {
      if (mounted) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Keine Medikamente verfügbar')),
        );
      }
      return;
    }

    if (!mounted) return;

    final doseController = TextEditingController();
    Map<String, dynamic>? result;

    try {
      result = await showDialog<Map<String, dynamic>>(
        context: dialogContext,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          String? selectedMedId;
          bool kiChecked = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              // Ausgewähltes Medikament finden
              final selectedMed = selectedMedId != null
                  ? medications.where((m) => m.id == selectedMedId).firstOrNull
                  : null;
              final contraindications = selectedMed?.contraindications ?? '';
              final hasContraindications = contraindications.isNotEmpty;

              // Hinzufügen nur möglich wenn Medikament + Dosis + KI-Check (falls vorhanden)
              final canAdd = selectedMedId != null &&
                  doseController.text.isNotEmpty &&
                  (!hasContraindications || kiChecked);

              return AlertDialog(
                title: const Text('Medikament hinzufügen'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        value: selectedMedId,
                        isExpanded: true,
                        hint: const Text('Medikament wählen'),
                        items: medications.map((med) {
                          return DropdownMenuItem(
                            value: med.id,
                            child: Text(med.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedMedId = val;
                            kiChecked = false; // Reset bei Medikamentenwechsel
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: doseController,
                        decoration: const InputDecoration(
                          labelText: 'Dosierung',
                          hintText: 'z.B. 0,5mg',
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),

                      // Kontraindikationen anzeigen wenn Medikament gewählt
                      if (selectedMed != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasContraindications
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasContraindications
                                  ? Colors.red.shade300
                                  : Colors.green.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hasContraindications
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    color: hasContraindications
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kontraindikationen',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: hasContraindications
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasContraindications
                                    ? contraindications
                                    : 'Keine Kontraindikationen hinterlegt',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasContraindications
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checkbox: KI kontrolliert (nur wenn es KI gibt)
                        if (hasContraindications) ...[
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: kiChecked,
                            onChanged: (val) {
                              setDialogState(() => kiChecked = val ?? false);
                            },
                            title: const Text(
                              'Kontraindikationen kontrolliert',
                              style: TextStyle(fontSize: 14),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    onPressed: canAdd
                        ? () {
                            Navigator.pop(context, {
                              'name': selectedMed!.name,
                              'dose': doseController.text,
                              'contraindications': contraindications,
                              'kiChecked': hasContraindications ? true : false,
                            });
                          }
                        : null,
                    child: const Text('Hinzufügen'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Dialog-Fehler: $e');
    } finally {
      doseController.dispose();
    }

    // Nach Dialog: Ergebnis verarbeiten
    if (result != null && mounted) {
      setState(() {
        widget.medications.add(result!);
      });
      widget.onMedicationsChanged();
    }
  }

  void _removeMedication(int index) {
    if (widget.onRemove != null) {
      widget.onRemove!(index);
    } else {
      setState(() {
        widget.medications.removeAt(index);
      });
    }
    widget.onMedicationsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.bgColor ?? Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: _addMedication,
                  tooltip: 'Medikament hinzufügen',
                ),
              ],
            ),
            if (widget.medications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Keine Medikamente hinzugefügt',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.medications.length,
                itemBuilder: (context, idx) {
                  final med = widget.medications[idx];
                  final kiChecked = med['kiChecked'] == true;
                  final hasKI = (med['contraindications'] ?? '').toString().isNotEmpty;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${med['name']} – ${med['dose']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (kiChecked)
                                const Icon(Icons.verified, color: Colors.green, size: 20),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _removeMedication(idx),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          if (hasKI) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  kiChecked ? Icons.check_circle : Icons.warning,
                                  size: 14,
                                  color: kiChecked ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'KI: ${med['contraindications']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
