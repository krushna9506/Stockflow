import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/update_service.dart';
import 'app_button.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.updateInfo});
  final UpdateInfo updateInfo;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startUpdate() async {
    final url = widget.updateInfo.downloadUrl;
    if (url == null || url.isEmpty) return;

    if (url.endsWith('.apk')) {
      setState(() {
        _isDownloading = true;
        _progress = 0.0;
        _statusText = 'Downloading update... 0%';
      });

      try {
        final dir = await getTemporaryDirectory();
        final savePath = '${dir.path}/StockFlow_update.apk';
        final file = File(savePath);
        if (await file.exists()) {
          await file.delete();
        }

        final dio = Dio();
        await dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final pct = (received / total);
              if (mounted) {
                setState(() {
                  _progress = pct;
                  _statusText = 'Downloading update... ${(pct * 100).toInt()}%';
                });
              }
            }
          },
        );

        if (mounted) {
          setState(() {
            _statusText = 'Opening package installer...';
          });
        }

        final result = await OpenFile.open(savePath);
        if (mounted && result.type != ResultType.done) {
          setState(() {
            _isDownloading = false;
            _statusText = 'Could not open package installer. Opening link...';
          });
          _openBrowser(url);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _statusText = 'Download failed. Opening in browser...';
          });
        }
        _openBrowser(url);
      }
    } else {
      _openBrowser(url);
    }
  }

  Future<void> _openBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.updateInfo.isMandatory && !_isDownloading,
      child: AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.system_update, color: Colors.blue),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A new version (${widget.updateInfo.latestVersion}) is available.'),
            if (widget.updateInfo.releaseNotes != null) ...[
              const SizedBox(height: 12),
              const Text('What\'s new:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.updateInfo.releaseNotes!),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 8),
              Text(_statusText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ] else if (_statusText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_statusText, style: const TextStyle(fontSize: 12, color: Colors.orange)),
            ],
            if (widget.updateInfo.isMandatory) ...[
              const SizedBox(height: 16),
              const Text(
                'This is a required update. You must update to continue using the app.',
                style: TextStyle(color: Colors.red),
              ),
            ]
          ],
        ),
        actions: [
          if (!widget.updateInfo.isMandatory && !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          if (!_isDownloading)
            AppButton(
              label: 'Update Now',
              onPressed: _startUpdate,
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
