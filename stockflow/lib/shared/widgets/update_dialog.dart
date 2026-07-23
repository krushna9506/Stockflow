import 'package:flutter/material.dart';
import '../../core/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_button.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.updateInfo});
  
  final UpdateInfo updateInfo;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.isMandatory,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A new version (${updateInfo.latestVersion}) is available.'),
            if (updateInfo.releaseNotes != null) ...[
              const SizedBox(height: 12),
              const Text('What\'s new:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(updateInfo.releaseNotes!),
            ],
            if (updateInfo.isMandatory) ...[
              const SizedBox(height: 16),
              const Text(
                'This is a required update. You must update to continue using the app.',
                style: TextStyle(color: Colors.red),
              ),
            ]
          ],
        ),
        actions: [
          if (!updateInfo.isMandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          AppButton(
            label: 'Update Now',
            onPressed: () async {
              if (updateInfo.downloadUrl != null) {
                final uri = Uri.parse(updateInfo.downloadUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<void> showUpdateDialogIfAvailable(BuildContext context, UpdateInfo info) async {
  if (info.isUpdateAvailable) {
    await showDialog(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (context) => UpdateDialog(updateInfo: info),
    );
  }
}
