import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class ExtendBookingScreen extends StatefulWidget {
  final LockerLocation location;
  final int bookingId;
  final DateTime currentEndTime;
  final int ratePerHalfHour;      // EGP per 30 min
  final int currentTotalAmount;   // current total_amount in DB

  const ExtendBookingScreen({
    super.key,
    required this.location,
    required this.bookingId,
    required this.currentEndTime,
    required this.ratePerHalfHour,
    required this.currentTotalAmount,
  });

  @override
  State<ExtendBookingScreen> createState() => _ExtendBookingScreenState();
}

class _ExtendBookingScreenState extends State<ExtendBookingScreen> {
  int _extraHalfHours = 1; // each unit = 30 min
  bool _isLoading = false;

  int get _additionalMinutes => _extraHalfHours * 30;
  int get _additionalCost => _extraHalfHours * widget.ratePerHalfHour;
  int get _newTotalAmount => widget.currentTotalAmount + _additionalCost;

  DateTime get _newEndTime =>
      widget.currentEndTime.add(Duration(minutes: _additionalMinutes));

  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hour${h > 1 ? 's' : ''}' : '$h h $m min';
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // UPDATE booking: extend end_time and add extra cost to total_amount
      await supabase.from('booking').update({
        'end_time': _newEndTime.toIso8601String(),
        'total_amount': _newTotalAmount,
        'status': 'extended',
      }).eq('id', widget.bookingId);

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Time Extended!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text(
                'Added ${_formatTime(_additionalMinutes)} to your booking.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF8090B0), fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context), // close dialog
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6FE8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );

      // Pop back to LockerAccessScreen and return the new end_time
      // so the countdown timer updates immediately without a DB refetch
      if (mounted) Navigator.pop(context, _newEndTime);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to extend: $e'),
          backgroundColor: const Color(0xFFE53935),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current duration in hours (from now to current end_time)
    final currentRemainingMinutes =
        widget.currentEndTime.difference(DateTime.now().toUtc()).inMinutes;
    final currentHours = (currentRemainingMinutes / 60).ceil();

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
        title: const Text('Extend time',
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
            // Current duration
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ],
              ),
              child: Row(
                children: [
                  const Text('Current Duration',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF8090B0))),
                  const Spacer(),
                  Text(
                    '$currentHours hour${currentHours > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Add more time header
            Row(
              children: const [
                Icon(Icons.access_time,
                    color: Color(0xFF3B6FE8), size: 18),
                SizedBox(width: 8),
                Text('Add More Time',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B6FE8))),
              ],
            ),

            const SizedBox(height: 16),

            // Stepper
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleButton(
                      icon: Icons.remove,
                      color: const Color(0xFFFFB3B3),
                      onPressed: _extraHalfHours > 1
                          ? () => setState(() => _extraHalfHours--)
                          : null,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        _formatTime(_additionalMinutes),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E)),
                      ),
                    ),
                    _CircleButton(
                      icon: Icons.add,
                      color: const Color(0xFFB3FFD1),
                      onPressed: () =>
                          setState(() => _extraHalfHours++),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Price summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _summaryLine(
                      'Additional Time', _formatTime(_additionalMinutes)),
                  const SizedBox(height: 10),
                  _summaryLine('Rate',
                      '${widget.ratePerHalfHour} EGP per 30 min'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFD0D8F0)),
                  ),
                  _summaryLine(
                      'New Total Price', '$_newTotalAmount LE',
                      isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        color: Colors.white,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B6FE8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Confirm',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _summaryLine(String label, String value,
      {bool isBold = false}) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: isBold
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF8090B0),
                fontWeight:
                    isBold ? FontWeight.w700 : FontWeight.normal)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isBold ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  const _CircleButton(
      {required this.icon, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onPressed != null
              ? color
              : Colors.grey.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 20,
            color: onPressed != null
                ? const Color(0xFF1A1A2E)
                : Colors.grey[400]),
      ),
    );
  }
}
