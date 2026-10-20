import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../core/services/database_service.dart';

class MedicationsSectionWidget extends StatefulWidget {
  final String title; // z.B. "Medikamente bei A"
  final String sectionCode;
  final Color? bgColor; // Optional, defaults to blue.shade50
  final List<Map<String, dynamic>> medications;
  final VoidCallback onMedicationsChanged; // Callback nach Änderungen
  final Function(int)? onRemove; // Optional: Custom remove handler

  const MedicationsSectionWidget({
    super.key,
    required this.title,
    required this.sectionCode,
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

  String get _sectionLabel =>
      widget.sectionCode == 'CRITICAL' ? 'c' : widget.sectionCode;

  Future<void> _addMedication({bool includeAllDatabase = false}) async {
    final allMedications = await DatabaseService.instance.getAllMedications();
    final sectionMedications = allMedications
        .where(
          (medication) =>
              medication.isUserConfigured &&
              medication.sectionsCsv?.trim().isNotEmpty == true &&
              medication.appliesToSection(widget.sectionCode),
        )
        .toList();
    final medications = includeAllDatabase
        ? allMedications
        : sectionMedications;

    if (!mounted) return;

    final doseController = TextEditingController();
    final adHocNameController = TextEditingController();
    final adHocDoseController = TextEditingController();
    final adHocContraindicationsController = TextEditingController();
    Map<String, dynamic>? result;

    try {
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          String? selectedMedId;
          bool kiChecked = false;
          bool adHocMode = medications.isEmpty;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              // Ausgewähltes Medikament finden
              final selectedMed = selectedMedId != null
                  ? medications.where((m) => m.id == selectedMedId).firstOrNull
                  : null;
              final contraindications = selectedMed?.contraindications ?? '';
              final hasContraindications = contraindications.isNotEmpty;

              final adHocHasContraindications =
                  adHocContraindicationsController.text.trim().isNotEmpty;

              // Hinzufügen nur möglich wenn Medikament + Dosis + KI-Check (falls vorhanden)
              final canAdd = adHocMode
                  ? adHocNameController.text.trim().isNotEmpty &&
                      adHocDoseController.text.trim().isNotEmpty &&
                      (!adHocHasContraindications || kiChecked)
                  : selectedMedId != null &&
                      doseController.text.isNotEmpty &&
                      (!hasContraindications || kiChecked);

              return AlertDialog(
                title: Text(
                  includeAllDatabase
                      ? 'Einmalig zu $_sectionLabel hinzufügen'
                      : 'Medikament bei $_sectionLabel hinzufügen',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!adHocMode) ...[
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
                              // Standarddosis aus Medikamentenverwaltung vorschlagen
                              final med = medications
                                  .where((m) => m.id == val)
                                  .firstOrNull;
                              doseController.text =
                                  med?.adultDose ?? med?.dosage ?? '';
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
                        if (selectedMed?.childDose != null &&
                            selectedMed!.childDose!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Standarddosis Kind: ${selectedMed.childDose}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
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
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              setDialogState(() => adHocMode = true),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text(
                            'Neues Medikament nur für diesen Einsatz anlegen',
                          ),
                        ),
                      ] else ...[
                        if (medications.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setDialogState(() => adHocMode = false),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Zurück zur Auswahl'),
                            ),
                          ),
                        const Text(
                          'Gilt nur für diesen Einsatz, wird nicht in die '
                          'Medikamenten-Datenbank übernommen.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: adHocNameController,
                          decoration: const InputDecoration(
                            labelText: 'Medikamentenname',
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: adHocDoseController,
                          decoration: const InputDecoration(
                            labelText: 'Dosierung',
                            hintText: 'z.B. 0,5mg',
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: adHocContraindicationsController,
                          decoration: const InputDecoration(
                            labelText: 'Kontraindikationen (optional)',
                          ),
                          onChanged: (_) => setDialogState(() {
                            kiChecked = false;
                          }),
                        ),
                        if (adHocHasContraindications) ...[
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
                            if (adHocMode) {
                              Navigator.pop(context, {
                                'name': adHocNameController.text.trim(),
                                'dose': adHocDoseController.text.trim(),
                                'contraindications':
                                    adHocContraindicationsController.text
                                        .trim(),
                                'kiChecked': adHocHasContraindications,
                              });
                            } else {
                              Navigator.pop(context, {
                                'name': selectedMed!.name,
                                'dose': doseController.text,
                                'contraindications': contraindications,
                                'kiChecked': hasContraindications ? true : false,
                              });
                            }
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
      adHocNameController.dispose();
      adHocDoseController.dispose();
      adHocContraindicationsController.dispose();
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

  /// Passt den fest hinterlegten (pastellfarbenen) Hintergrund für den
  /// Dark-Mode an, damit Text darauf lesbar bleibt.
  Color _resolveBgColor(BuildContext context) {
    final base = widget.bgColor ?? Colors.blue.shade50;
    if (Theme.of(context).brightness != Brightness.dark) return base;
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness(0.20)
        .withSaturation(hsl.saturation.clamp(0.25, 0.6))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : Colors.black87;

    return Card(
      color: _resolveBgColor(context),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: fgColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _addMedication(),
                  tooltip: 'Abschnittsmedikament hinzufügen',
                ),
              ],
            ),
            if (widget.medications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Keine Medikamente hinzugefügt',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: fgColor.withOpacity(0.7),
                  ),
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
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700,
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addMedication(includeAllDatabase: true),
                icon: const Icon(Icons.playlist_add),
                label: Text('Einmalig zu $_sectionLabel hinzufügen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
