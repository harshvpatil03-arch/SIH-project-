// lib/presentation/queue/queue_screen.dart
import 'package:flutter/material.dart';
import '../../data/models/inspection_record.dart';
import '../../data/repositories/inspection_repository.dart';
import 'widgets/sync_button.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final InspectionRepository _repository = InspectionRepository();

  List<InspectionRecord> _records = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _syncStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final all = await _repository.getAllRecords();
    if (mounted) {
      setState(() {
        _records = all;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBatchSync() async {
    final pending = _records.where((r) => r.syncStatus == 'PENDING').toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF101318),
          content: Text('No pending offline inspections to sync.', style: TextStyle(fontFamily: 'Manrope')),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncStatusMessage = 'Processing ${pending.length} pending records via Gemini VLM...';
    });

    final result = await _repository.syncAllPendingRecords();

    if (!mounted) return;

    setState(() {
      _isSyncing = false;
      _syncStatusMessage = '';
    });

    await _loadQueue();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101318),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Sharp geometry
          side: const BorderSide(color: Color(0xFF222733)),
        ),
        title: const Row(
          children: [
            Icon(Icons.cloud_done_rounded, color: Color(0xFF00C853), size: 20),
            SizedBox(width: 8),
            Text(
              'Sync Completed',
              style: TextStyle(fontFamily: 'Manrope', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Processed: ${result.totalProcessed}', style: const TextStyle(fontFamily: 'Manrope', color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('• Successfully Synced: ${result.syncedSuccessfully}', style: const TextStyle(fontFamily: 'Manrope', color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('• Discarded / Unreadable: ${result.unreadableDiscarded}', style: const TextStyle(fontFamily: 'Manrope', color: Color(0xFFFFAB00), fontSize: 12, fontWeight: FontWeight.w700)),
            if (result.failed > 0) ...[
              const SizedBox(height: 4),
              Text('• Server unreachable / Failed: ${result.failed}', style: const TextStyle(fontFamily: 'Manrope', color: Color(0xFFD50000), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS', style: TextStyle(fontFamily: 'Manrope', color: Color(0xFF0080FF), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String primaryFont = 'Manrope';
    final pendingCount = _records.where((r) => r.syncStatus == 'PENDING').length;

    return Scaffold(
      backgroundColor: const Color(0xFF08090C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101318),
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF222733), width: 1),
        ),
        title: const Text(
          'OFFLINE INSPECTION QUEUE',
          style: TextStyle(fontFamily: primaryFont, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
        actions: [
          SyncButton(
            isSyncing: _isSyncing,
            onSyncPressed: _handleBatchSync,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0080FF)))
          : Column(
              children: [
                if (_isSyncing)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF0A2540),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0080FF)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _syncStatusMessage,
                            style: const TextStyle(fontFamily: primaryFont, color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: _records.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Color(0xFF333B4F), size: 48),
                              SizedBox(height: 10),
                              Text(
                                'No records in local SQLite database',
                                style: TextStyle(fontFamily: primaryFont, color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            final isPending = record.syncStatus == 'PENDING';
                            final isPass = record.status == 'PASS';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101318),
                                borderRadius: BorderRadius.circular(4), // Sharp geometry
                                border: Border.all(
                                  color: isPending
                                      ? const Color(0xFFFFAB00).withOpacity(0.6)
                                      : (isPass ? const Color(0xFF00C853).withOpacity(0.5) : const Color(0xFFD50000).withOpacity(0.5)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? const Color(0xFF261D00)
                                          : (isPass ? const Color(0xFF092314) : const Color(0xFF280808)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      isPending
                                          ? Icons.schedule
                                          : (isPass ? Icons.check : Icons.close),
                                      color: isPending
                                          ? const Color(0xFFFFAB00)
                                          : (isPass ? const Color(0xFF00C853) : const Color(0xFFD50000)),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              record.id,
                                              style: const TextStyle(
                                                fontFamily: primaryFont,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: isPending ? const Color(0xFF261D00) : const Color(0xFF092314),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: Text(
                                                record.syncStatus,
                                                style: TextStyle(
                                                  fontFamily: primaryFont,
                                                  color: isPending ? const Color(0xFFFFAB00) : const Color(0xFF00C853),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'GPS: ${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
                                          style: const TextStyle(fontFamily: primaryFont, color: Color(0xFF94A3B8), fontSize: 10),
                                        ),
                                        Text(
                                          'Status: ${record.status} • ${record.timestamp}',
                                          style: const TextStyle(fontFamily: primaryFont, color: Color(0xFF64748B), fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Massive "Sync Pending" Action Button (Sharp geometry 4px, flat high-contrast blue)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF101318),
                    border: Border(top: BorderSide(color: Color(0xFF222733))),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pendingCount > 0 ? const Color(0xFF0080FF) : const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharp geometry
                    ),
                    onPressed: (_isSyncing || pendingCount == 0) ? null : _handleBatchSync,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'SYNC PENDING ($pendingCount RECORDS)',
                          style: const TextStyle(
                            fontFamily: primaryFont,
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
