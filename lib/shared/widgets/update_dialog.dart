import 'package:flutter/material.dart';
import '../../core/services/update_service.dart';

/// Zeigt einen Update-Dialog mit Fortschrittsbalken während des Downloads.
/// Verwendung: await UpdateDialog.show(context, info, service);
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final UpdateService service;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.service,
  });

  /// Öffnet den Update-Dialog modal.
  static Future<void> show(
    BuildContext context,
    UpdateInfo info,
    UpdateService service,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: info, service: service),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _Phase { idle, downloading, done, error }

class _UpdateDialogState extends State<UpdateDialog> {
  _Phase _phase = _Phase.idle;
  double _progress = 0.0;
  String? _apkPath;
  String? _errorMsg;

  Future<void> _startDownload() async {
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0.0;
    });

    try {
      final path = await widget.service.downloadApk(
        widget.info.downloadUrl,
        (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) {
        setState(() {
          _phase = _Phase.done;
          _apkPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _install() async {
    if (_apkPath == null) return;
    await widget.service.installApk(_apkPath!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Colors.orange),
          SizedBox(width: 8),
          Text('Update verfügbar'),
        ],
      ),
      content: _buildContent(context),
      actions: _buildActions(),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_phase) {
      case _Phase.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eine neue Version von RescueDoc ist verfügbar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Aktuell: ',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  'v${widget.info.currentVersion}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward,
                    size: 16, color: Colors.grey),
                const Spacer(),
                Text(
                  'v${widget.info.latestVersion}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 Das Update wird heruntergeladen und der Paketinstaller öffnet sich automatisch.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );

      case _Phase.downloading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wird heruntergeladen…'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
            ),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? '${(_progress * 100).toStringAsFixed(0)} %'
                  : 'Verbindung wird hergestellt…',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );

      case _Phase.done:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            SizedBox(height: 12),
            Text(
              'Download abgeschlossen!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Tippen Sie auf „Installieren" – der Android-Paketinstaller öffnet sich.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _Phase.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Download fehlgeschlagen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMsg ?? 'Unbekannter Fehler',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_phase) {
      case _Phase.idle:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Später'),
          ),
          ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Aktualisieren'),
          ),
        ];

      case _Phase.downloading:
        return [
          const TextButton(
            onPressed: null,
            child: Text('Bitte warten…'),
          ),
        ];

      case _Phase.done:
        return [
          ElevatedButton.icon(
            onPressed: _install,
            icon: const Icon(Icons.install_mobile, size: 18),
            label: const Text('Installieren'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ];

      case _Phase.error:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text('Erneut versuchen'),
          ),
        ];
    }
  }
}
