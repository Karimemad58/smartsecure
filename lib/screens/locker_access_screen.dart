import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'extend_booking_screen.dart';

class LockerAccessScreen extends StatefulWidget {
  final LockerLocation location;
  final String lockerSize;
  final int bookingId;
  final int durationMinutes;   // initial remaining minutes (from end_time - now)
  final DateTime endTime;      // actual end_time from DB, used to keep timer accurate
  final int ratePerHalfHour;   // EGP per 30 min, for extend screen

  const LockerAccessScreen({
    super.key,
    required this.location,
    required this.lockerSize,
    required this.bookingId,
    required this.durationMinutes,
    required this.endTime,
    required this.ratePerHalfHour,
  });

  @override
  State<LockerAccessScreen> createState() => _LockerAccessScreenState();
}

class _LockerAccessScreenState extends State<LockerAccessScreen> {
  late int _remainingMinutes;
  Timer? _timer;
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    // Compute from actual end_time so it stays accurate even if screen rebuilds
    _remainingMinutes =
        widget.endTime.difference(DateTime.now().toUtc()).inMinutes;
    if (_remainingMinutes < 0) _remainingMinutes = 0;

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final remaining =
          widget.endTime.difference(DateTime.now().toUtc()).inMinutes;
      setState(() => _remainingMinutes = remaining > 0 ? remaining : 0);
      if (_remainingMinutes == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Called when ExtendBookingScreen returns with a new end_time
  void _onExtended(DateTime newEndTime) {
    _timer?.cancel();
    final remaining =
        newEndTime.difference(DateTime.now().toUtc()).inMinutes;
    setState(() => _remainingMinutes = remaining > 0 ? remaining : 0);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final r = newEndTime.difference(DateTime.now().toUtc()).inMinutes;
      setState(() => _remainingMinutes = r > 0 ? r : 0);
      if (_remainingMinutes == 0) _timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My locker',
            style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1A1A2E)),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  _infoRow('Locker ID', '#${widget.bookingId}',
                      valueColor: const Color(0xFF3B6FE8)),
                  _divider(),
                  _infoRow('Location', widget.location.name,
                      subtitle: widget.location.subtitle,
                      valueColor: const Color(0xFF3B6FE8),
                      withDirectionButton: true),
                  _divider(),
                  _infoRow('Time Remaining', '$_remainingMinutes min',
                      valueColor: _remainingMinutes < 15
                          ? Colors.red
                          : const Color(0xFF1A1A2E)),
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        const Text('Locker Status',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF8090B0))),
                        const Spacer(),
                        Icon(
                          _isLocked ? Icons.lock : Icons.lock_open,
                          color: _isLocked
                              ? const Color(0xFF3B6FE8)
                              : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isLocked ? 'Locked' : 'Unlocked',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _isLocked
                                ? const Color(0xFF3B6FE8)
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // QR code
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: _QrPainter(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Scan to open your locker',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8090B0))),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _isLocked = !_isLocked);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(_isLocked ? 'Locker locked' : 'Locker opened!'),
                    backgroundColor: _isLocked
                        ? const Color(0xFF3B6FE8)
                        : Colors.green,
                    duration: const Duration(seconds: 2),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6FE8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Open locker',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  // Navigate to ExtendBookingScreen and await a possible new end_time
                  final newEndTime = await Navigator.push<DateTime>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExtendBookingScreen(
                        location: widget.location,
                        bookingId: widget.bookingId,
                        currentEndTime: widget.endTime,
                        ratePerHalfHour: widget.ratePerHalfHour,
                        currentTotalAmount: widget.durationMinutes ~/
                            30 *
                            widget.ratePerHalfHour,
                      ),
                    ),
                  );
                  if (newEndTime != null) _onExtended(newEndTime);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Extend time',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {String? subtitle,
      Color? valueColor,
      bool withDirectionButton = false}) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF8090B0))),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: valueColor ?? const Color(0xFF1A1A2E))),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8090B0))),
              if (withDirectionButton) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Get Direction',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFFF0F2FA));
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1A2E);
    final cell = size.width / 21;

    final pattern = [
      [0, 0],
      [14, 0],
      [0, 14],
    ];
    for (final p in pattern) {
      _drawFinder(canvas, paint, p[0] * cell, p[1] * cell, cell);
    }

    final dataCells = [
      [8,2],[9,2],[11,2],[12,2],[13,2],[8,3],[10,3],[13,3],[9,4],[11,4],[12,4],
      [8,5],[10,5],[13,5],[8,6],[9,6],[11,6],[12,6],
      [2,8],[4,8],[6,8],[8,8],[10,8],[12,8],[14,8],[16,8],[18,8],[20,8],
      [1,9],[3,9],[5,9],[9,9],[11,9],[15,9],[17,9],[19,9],
      [2,10],[4,10],[6,10],[10,10],[12,10],[14,10],[16,10],[20,10],
      [1,11],[5,11],[7,11],[11,11],[13,11],[17,11],[19,11],
      [2,12],[4,12],[6,12],[8,12],[12,12],[14,12],[16,12],[18,12],[20,12],
      [9,13],[11,13],[15,13],[17,13],
      [8,14],[10,14],[12,14],[14,14],[16,14],[18,14],[20,14],
      [1,15],[3,15],[7,15],[9,15],[11,15],[13,15],[17,15],[19,15],
      [2,16],[4,16],[6,16],[8,16],[10,16],[14,16],[16,16],[20,16],
      [1,17],[5,17],[9,17],[11,17],[13,17],[15,17],[17,17],[19,17],
      [2,18],[4,18],[6,18],[8,18],[10,18],[12,18],[14,18],[18,18],[20,18],
      [1,19],[3,19],[7,19],[9,19],[11,19],[13,19],[15,19],
      [2,20],[4,20],[6,20],[8,20],[10,20],[12,20],[16,20],[18,20],[20,20],
    ];
    for (final c in dataCells) {
      canvas.drawRect(
          Rect.fromLTWH(c[0]*cell+1, c[1]*cell+1, cell-1, cell-1), paint);
    }
  }

  void _drawFinder(
      Canvas canvas, Paint paint, double x, double y, double cell) {
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF1A1A2E);
    canvas.drawRect(Rect.fromLTWH(x, y, cell*7, cell*7), paint);
    paint.color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(x+cell, y+cell, cell*5, cell*5), paint);
    paint.color = const Color(0xFF1A1A2E);
    canvas.drawRect(
        Rect.fromLTWH(x+cell*2, y+cell*2, cell*3, cell*3), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
