import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'payment_screen.dart';

class BookingSummaryScreen extends StatefulWidget {
  final LockerLocation location;
  final String lockerSize;
  final int pricePerHour;
  final int lockerCount;
  final int userId;

  const BookingSummaryScreen({
    super.key,
    required this.location,
    required this.lockerSize,
    required this.pricePerHour,
    this.lockerCount = 1,
    this.userId = 0,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  int _durationHours = 1;
  String _selectedPayment = 'visa';

  int get _totalPrice =>
      widget.pricePerHour * _durationHours * widget.lockerCount;

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
        title: const Text('Booking',
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
            // Summary card
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
                  _summaryRow('Lockers', '${widget.lockerCount} lockers',
                      valueColor: const Color(0xFF3B6FE8)),
                  _divider(),
                  _summaryRow('Location', widget.location.name,
                      subtitle: widget.location.subtitle,
                      valueColor: const Color(0xFF3B6FE8)),
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        const Text('Duration Selector',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF8090B0))),
                        const Spacer(),
                        _StepperButton(
                          icon: Icons.remove,
                          onPressed: _durationHours > 1
                              ? () => setState(() => _durationHours--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('$_durationHours h',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E))),
                        ),
                        _StepperButton(
                          icon: Icons.add,
                          onPressed: () => setState(() => _durationHours++),
                        ),
                      ],
                    ),
                  ),
                  _divider(),
                  _summaryRow('Total Price', '$_totalPrice EGP',
                      valueStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E))),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Payment Method',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),

            _PaymentOptionTile(
              id: 'visa',
              label: 'Add Card',
              icon: _VisaIcon(),
              selected: _selectedPayment == 'visa',
              onTap: () => setState(() => _selectedPayment = 'visa'),
            ),
            const SizedBox(height: 10),
            _PaymentOptionTile(
              id: 'apple_pay',
              label: 'Apple Pay',
              icon: const Icon(Icons.apple, color: Color(0xFF1A1A2E), size: 22),
              selected: _selectedPayment == 'apple_pay',
              onTap: () => setState(() => _selectedPayment = 'apple_pay'),
            ),
            const SizedBox(height: 10),
            _PaymentOptionTile(
              id: 'google_pay',
              label: 'Google Pay',
              icon: const Icon(Icons.g_mobiledata_rounded,
                  color: Color(0xFFEA4335), size: 26),
              selected: _selectedPayment == 'google_pay',
              onTap: () => setState(() => _selectedPayment = 'google_pay'),
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
            onPressed: () {
              // Pass all booking details to PaymentScreen.
              // The INSERT into booking happens after successful payment.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    location: widget.location,
                    lockerSize: widget.lockerSize,
                    durationHours: _durationHours,
                    totalPrice: _totalPrice,
                    paymentMethod: _selectedPayment,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B6FE8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Confirm booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {String? subtitle, Color? valueColor, TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: subtitle != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8090B0))),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: valueStyle ??
                      TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: valueColor ?? const Color(0xFF1A1A2E))),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8090B0))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F2FA));
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onPressed != null
              ? const Color(0xFF3B6FE8).withOpacity(0.12)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color:
                onPressed != null ? const Color(0xFF3B6FE8) : Colors.grey[400]),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String id;
  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOptionTile(
      {required this.id,
      required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? const Color(0xFF3B6FE8) : Colors.transparent,
              width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E)))),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF3B6FE8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _VisaIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F71),
          borderRadius: BorderRadius.circular(4)),
      child: const Text('VISA',
          style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }
}
