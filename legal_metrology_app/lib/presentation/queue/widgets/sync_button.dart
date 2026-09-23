// lib/presentation/queue/widgets/sync_button.dart
import 'package:flutter/material.dart';

class SyncButton extends StatelessWidget {
  final VoidCallback onSyncPressed;
  final bool isSyncing;

  const SyncButton({
    super.key,
    required this.onSyncPressed,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    return isSyncing
        ? const Padding(
            padding: EdgeInsets.all(14.0),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0080FF)),
            ),
          )
        : IconButton(
            tooltip: 'Sync Offline Queue',
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF0080FF)),
            onPressed: onSyncPressed,
          );
  }
}
