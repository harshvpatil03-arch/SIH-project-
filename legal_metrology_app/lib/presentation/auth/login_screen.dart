// lib/presentation/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../core/network/network_info.dart';
import '../../core/services/gps_service.dart';
import '../../data/models/inspection_record.dart';
import '../../data/repositories/inspection_repository.dart';
import '../camera/camera_screen.dart';
import '../queue/queue_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
  final GpsService _gpsService = GpsService();
  final InspectionRepository _repository = InspectionRepository();

  // Hardcoded LMO Officer Profile
  final String officerId = 'LMO-884920';
  final String officerName = 'Officer R. Sharma';
  final String jurisdiction = 'Delhi NCR • Circle 04';

  bool _isVerifying = true;
  bool _isOnline = false;
  GpsResult? _gpsResult;
  List<InspectionRecord> _allRecords = [];
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshEdgeStatus();
  }

  Future<void> _refreshEdgeStatus() async {
    setState(() => _isVerifying = true);
    final online = await _networkInfo.isConnected();
    final gps = await _gpsService.captureLocation();
    final records = await _repository.getAllRecords();

    if (mounted) {
      setState(() {
        _isOnline = online;
        _gpsResult = gps;
        _allRecords = records;
        _isVerifying = false;
      });
    }
  }

  void _openCameraScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          officerId: officerId,
          officerName: officerName,
          gpsResult: _gpsResult ??
              GpsResult(
                latitude: 28.5355,
                longitude: 77.3910,
                accuracyMode: 'GPS_LOCK_DEFAULT',
                timestamp: DateTime.now().toUtc(),
              ),
        ),
      ),
    );
    _refreshEdgeStatus();
  }

  @override
  Widget build(BuildContext context) {
    const String primaryFont = 'Manrope';
    final pendingCount = _allRecords.where((r) => r.syncStatus == 'PENDING').length;
    final passCount = _allRecords.where((r) => r.status == 'PASS').length;
    final failCount = _allRecords.where((r) => r.status == 'FAIL').length;

    return Scaffold(
      backgroundColor: const Color(0xFF08090C), // Deep Void Charcoal
      // PhonePe Header Bar
      appBar: AppBar(
        backgroundColor: const Color(0xFF101318),
        elevation: 0,
        toolbarHeight: 68,
        titleSpacing: 16,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF222733), width: 1),
        ),
        title: Row(
          children: [
            // Officer Avatar with Status Dot
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A202C),
                    borderRadius: BorderRadius.circular(4), // Sharp geometry
                    border: Border.all(color: const Color(0xFF333B4F), width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'RS',
                      style: TextStyle(
                        fontFamily: primaryFont,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _isOnline ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF101318), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        officerName,
                        style: const TextStyle(
                          fontFamily: primaryFont,
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2433),
                          borderRadius: BorderRadius.circular(2), // Sharp 2px
                          border: Border.all(color: const Color(0xFF2A364F)),
                        ),
                        child: Text(
                          officerId,
                          style: const TextStyle(
                            fontFamily: primaryFont,
                            color: Color(0xFF60A5FA),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF64748B), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        jurisdiction,
                        style: const TextStyle(
                          fontFamily: primaryFont,
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Hardware Sync Diagnostics Button
            IconButton(
              icon: Icon(
                _isVerifying ? Icons.hourglass_top : Icons.refresh_rounded,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: _refreshEdgeStatus,
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PhonePe-style Quick Telemetry Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101318),
                borderRadius: BorderRadius.circular(4), // Sharp geometry
                border: Border.all(color: const Color(0xFF222733), width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COMMODITY SURVEILLANCE ACTIVE',
                          style: TextStyle(
                            fontFamily: primaryFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _isOnline ? 'ONLINE: PATH A' : 'OFFLINE: PATH B',
                              style: TextStyle(
                                fontFamily: primaryFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _isOnline ? const Color(0xFF00C853) : const Color(0xFFFFAB00),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _gpsResult == null
                                  ? '• GPS: Acquiring...'
                                  : (_gpsResult!.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                                      ? '• GPS: ${_gpsResult?.latitude.toStringAsFixed(2)}, ${_gpsResult?.longitude.toStringAsFixed(2)} [COARSE FALLBACK]'
                                      : '• GPS: ${_gpsResult?.latitude.toStringAsFixed(2)}, ${_gpsResult?.longitude.toStringAsFixed(2)} [SAT LOCK]',
                              style: TextStyle(
                                fontFamily: primaryFont,
                                fontSize: 11,
                                color: (_gpsResult?.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                                    ? const Color(0xFFFFAB00)
                                    : const Color(0xFF94A3B8),
                                fontWeight: (_gpsResult?.accuracyMode == 'NETWORK_COARSE_FALLBACK')
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Demo offline toggle switch
                  Row(
                    children: [
                      const Text(
                        'SIM OFFLINE',
                        style: TextStyle(
                          fontFamily: primaryFont,
                          color: Color(0xFF64748B),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Switch(
                        value: _networkInfo.isMockOffline,
                        activeColor: const Color(0xFFFFAB00),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() {
                            _networkInfo.isMockOffline = val;
                            _refreshEdgeStatus();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. PhonePe Quick 4-Grid Action Tiles
            Row(
              children: [
                _buildPhonePeQuickTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'New Scan',
                  subtitle: 'Start Camera',
                  badgeText: 'F1',
                  onTap: _openCameraScanner,
                ),
                const SizedBox(width: 10),
                _buildPhonePeQuickTile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Offline Queue',
                  subtitle: '$pendingCount Pending',
                  badgeColor: pendingCount > 0 ? const Color(0xFFFFAB00) : const Color(0xFF64748B),
                  badgeText: '$pendingCount',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QueueScreen()),
                    );
                    _refreshEdgeStatus();
                  },
                ),
                const SizedBox(width: 10),
                _buildPhonePeQuickTile(
                  icon: Icons.gavel_rounded,
                  title: 'Rules 2011',
                  subtitle: '7 Declarations',
                  onTap: () => _showRulesDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Inspection Ledger KPI summary row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF101318),
                borderRadius: BorderRadius.circular(4), // Sharp geometry
                border: Border.all(color: const Color(0xFF222733), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('TOTAL SCANS', '${_allRecords.length}', const Color(0xFFFFFFFF)),
                  Container(width: 1, height: 28, color: const Color(0xFF222733)),
                  _buildStatColumn('COMPLIANT', '$passCount', const Color(0xFF00C853)),
                  Container(width: 1, height: 28, color: const Color(0xFF222733)),
                  _buildStatColumn('VIOLATIONS', '$failCount', const Color(0xFFD50000)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Recent Inspection Stream Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT FIELD INSPECTIONS',
                  style: TextStyle(
                    fontFamily: primaryFont,
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QueueScreen()),
                    );
                  },
                  child: const Text(
                    'VIEW ALL',
                    style: TextStyle(
                      fontFamily: primaryFont,
                      color: Color(0xFF0080FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            if (_allRecords.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF101318),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF222733)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Color(0xFF475569), size: 40),
                    SizedBox(height: 10),
                    Text(
                      'No label inspections yet today',
                      style: TextStyle(
                        fontFamily: primaryFont,
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap the center SCAN button below to inspect a packaged commodity.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: primaryFont,
                        color: Color(0xFF475569),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._allRecords.take(5).map((r) => _buildInspectionRow(r)),
          ],
        ),
      ),

      // 5. PhonePe Bottom Navigation Bar with Middle-Down Scanning Option
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF101318),
          border: Border(
            top: BorderSide(color: Color(0xFF222733), width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Nav Item 1: Home
                _buildBottomNavItem(
                  icon: Icons.home_filled,
                  label: 'Home',
                  isSelected: _currentTabIndex == 0,
                  onTap: () => setState(() => _currentTabIndex = 0),
                ),

                // Nav Item 2: Records
                _buildBottomNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'History',
                  isSelected: _currentTabIndex == 1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QueueScreen()),
                    );
                  },
                ),

                // CENTER PHONEPE SCANNING BUTTON (MIDDLE DOWN)
                GestureDetector(
                  onTap: _openCameraScanner,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0080FF), // Flat high-contrast Cobalt Cyan
                            borderRadius: BorderRadius.circular(6), // Sharp modern geometry (no oversized circle)
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0080FF).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'SCAN',
                          style: TextStyle(
                            fontFamily: primaryFont,
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nav Item 3: Offline Queue
                _buildBottomNavItem(
                  icon: Icons.cloud_queue_rounded,
                  label: 'Queue',
                  badgeCount: pendingCount,
                  isSelected: _currentTabIndex == 2,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QueueScreen()),
                    );
                  },
                ),

                // Nav Item 4: LMO Profile / Diagnostics
                _buildBottomNavItem(
                  icon: Icons.shield_outlined,
                  label: 'LMO ID',
                  isSelected: _currentTabIndex == 3,
                  onTap: _refreshEdgeStatus,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    const String primaryFont = 'Manrope';
    final color = isSelected ? const Color(0xFF0080FF) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 22),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFAB00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontFamily: primaryFont,
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: primaryFont,
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonePeQuickTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
    Color badgeColor = const Color(0xFF0080FF),
  }) {
    const String primaryFont = 'Manrope';
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF101318),
            borderRadius: BorderRadius.circular(4), // Sharp geometry
            border: Border.all(color: const Color(0xFF222733), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: const Color(0xFF0080FF), size: 20),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: badgeColor, width: 0.8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontFamily: primaryFont,
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: primaryFont,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: primaryFont,
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    const String primaryFont = 'Manrope';
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: primaryFont,
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: primaryFont,
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInspectionRow(InspectionRecord r) {
    const String primaryFont = 'Manrope';
    final isPass = r.status == 'PASS';
    final isPending = r.syncStatus == 'PENDING';
    final commodity = r.extractedData['generic_name'] ?? r.extractedData['commodity_name'] ?? 'Packaged Item';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101318),
        borderRadius: BorderRadius.circular(4), // Sharp geometry
        border: Border.all(color: const Color(0xFF222733)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFF261D00)
                  : (isPass ? const Color(0xFF002911) : const Color(0xFF2B0000)),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isPending
                    ? const Color(0xFFFFAB00)
                    : (isPass ? const Color(0xFF00C853) : const Color(0xFFD50000)),
              ),
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
                Text(
                  commodity,
                  style: const TextStyle(
                    fontFamily: primaryFont,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${r.id} • ${r.timestamp.split("T").first}',
                  style: const TextStyle(
                    fontFamily: primaryFont,
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A202C),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              r.status,
              style: TextStyle(
                fontFamily: primaryFont,
                color: isPass ? const Color(0xFF00C853) : const Color(0xFFD50000),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    const String primaryFont = 'Manrope';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101318),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFF222733)),
        ),
        title: const Text(
          'Legal Metrology Rules 2011',
          style: TextStyle(fontFamily: primaryFont, color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Manufacturer/Packer Name & Address', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text('2. Country of Origin (Imported)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text('3. Generic Commodity Name', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text('4. Net Quantity (Std Metric Units)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text('5. Month & Year of Mfg/Packing', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text('6. Maximum Retail Price (Incl. of taxes)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text('7. Consumer Care Details', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS', style: TextStyle(color: Color(0xFF0080FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
