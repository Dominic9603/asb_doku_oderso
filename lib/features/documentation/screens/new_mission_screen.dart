import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mission_provider.dart';
import '../../../core/utils/scaffold_messenger_key.dart';

class NewMissionScreen extends StatefulWidget {
  const NewMissionScreen({super.key});

  @override
  State<NewMissionScreen> createState() => _NewMissionScreenState();
}

class _NewMissionScreenState extends State<NewMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _missionNumberController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _missionNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _createMission() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final provider = context.read<MissionProvider>();
    await provider.createNewMission(
      missionNumber: _missionNumberController.text.isEmpty 
          ? null 
          : _missionNumberController.text,
    );
    
    if (mounted) {
      Navigator.of(context).pop();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Einsatz erfolgreich erstellt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuer Einsatz'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Einsatzdaten',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _missionNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Einsatznummer (optional)',
                        hintText: 'z.B. 2026-001',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createMission,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Einsatz starten'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Die Startzeit wird automatisch beim Erstellen des Einsatzes erfasst. '
                      'Die Einsatznummer ist optional und kann zur besseren Organisation genutzt werden.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
