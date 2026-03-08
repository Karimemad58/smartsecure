import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'locker_access_screen.dart';

class PaymentScreen extends StatefulWidget {
  final LockerLocation location;
  final String lockerSize;
  final int durationHours;
  final int totalPrice;
  final String paymentMethod;
  final int userId;

  const PaymentScreen({
    super.key,
    required this.location,
    required this.lockerSize,
    required this.durationHours,
    required this.totalPrice,
    required this.paymentMethod,
    required this.userId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _cardSaved = false;       // true after user taps "Add Card"
  bool _showCardForm = false;    // toggles the card form panel
  bool _submitted = false;       // tracks if Pay Now was tapped (for error display)

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateCardNumber(String? v) {
    if (v == null || v.isEmpty) return 'Card number is required';
    final digits = v.replaceAll(RegExp(r'\s'), '');
    if (digits.length != 16) return 'Card number must be 16 digits';
    return null;
  }

  String? _validateExpiry(String? v) {
    if (v == null || v.isEmpty) return 'Expiry date is required';
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) return 'Use MM/YY format';
    final parts = v.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    final fullYear = 2000 + year;
    if (fullYear < now.year ||
        (fullYear == now.year && month < now.month)) {
      return 'Card has expired';
    }
    return null;
  }

  String? _validateCvv(String? v) {
    if (v == null || v.isEmpty) return 'CVV is required';
    if (v.length != 3) return 'CVV must be 3 digits';
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Cardholder name is required';
    if (v.trim().split(' ').length < 2) return 'Enter first and last name';
    return null;
  }

  // ── Add Card ──────────────────────────────────────────────────────────────

  void _addCard() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      setState(() {
        _cardSaved = true;
        _showCardForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Pay ───────────────────────────────────────────────────────────────────

  Future<void> _pay() async {
    setState(() => _submitted = true);

    // If card payment selected, card must be added first
    if (widget.paymentMethod == 'visa' && !_cardSaved) {
      setState(() => _showCardForm = true);
      _showError('Please add your card details first');
      return;
    }

    // Both ID photos required
    if (!_frontUploaded || !_backUploaded) {
      _showError('Please upload both sides of your national ID');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now().toUtc();
      final endTime =
          now.add(Duration(hours: widget.durationHours)).toIso8601String();

      final response = await supabase
          .from('booking')
          .insert({
            'user_id': widget.userId,
            'duration_hours': widget.durationHours,
            'total_amount': widget.totalPrice,
            'payment_method': widget.paymentMethod,
            'start_time': now.toIso8601String(),
            'end_time': endTime,
            'status': 'active',
          })
          .select('id, end_time')
          .single();

      final bookingId = response['id'] as int;
      final endTimeResult =
          DateTime.parse(response['end_time'] as String);
      final remainingMinutes =
          endTimeResult.difference(DateTime.now().toUtc()).inMinutes;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LockerAccessScreen(
            location: widget.location,
            lockerSize: widget.lockerSize,
            bookingId: bookingId,
            durationMinutes: remainingMinutes > 0 ? remainingMinutes : 0,
            endTime: endTimeResult,
            ratePerHalfHour:
                (widget.totalPrice / (widget.durationHours * 2)).round(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showError('Payment failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE53935),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _maskedCard {
    final digits = _cardController.text.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 4) return '**** **** **** ****';
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
        title: const Text('Add Payment',
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
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Card section ──────────────────────────────────────────────
              const Text('Card Details',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),

              // If card is saved: show saved card tile + option to change
              if (_cardSaved && !_showCardForm) ...[
                _SavedCardTile(
                  maskedCard: _maskedCard,
                  expiry: _expiryController.text,
                  onEdit: () => setState(() => _showCardForm = true),
                ),
                const SizedBox(height: 8),
              ],

              // "Add Card" button — shown when no card saved yet
              if (!_cardSaved && !_showCardForm)
                GestureDetector(
                  onTap: () => setState(() => _showCardForm = true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF3B6FE8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Color(0xFF3B6FE8), size: 20),
                        SizedBox(width: 8),
                        Text('Add Card',
                            style: TextStyle(
                                color: Color(0xFF3B6FE8),
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),

              // Card form — shown when adding/editing
              if (_showCardForm) ...[
                _buildCardForm(),
                const SizedBox(height: 12),
                // Add Card / Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B6FE8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      _cardSaved ? 'Save Changes' : 'Add Card',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (_cardSaved) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _showCardForm = false),
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFF8090B0))),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 28),

              // ── National ID ───────────────────────────────────────────────
              Row(
                children: [
                  const Text('National ID Photos',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const Spacer(),
                  // Required badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Required',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload clear photos of both sides of your national ID',
                style: TextStyle(fontSize: 12, color: Color(0xFF8090B0)),
              ),
              const SizedBox(height: 16),

              const Text('ID Front Side',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8090B0),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _IdUploadBox(
                uploaded: _frontUploaded,
                hasError: _submitted && !_frontUploaded,
                onTakePhoto: () =>
                    setState(() => _frontUploaded = true),
                onUpload: () => setState(() => _frontUploaded = true),
              ),

              const SizedBox(height: 16),

              const Text('ID Back Side',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8090B0),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _IdUploadBox(
                uploaded: _backUploaded,
                hasError: _submitted && !_backUploaded,
                onTakePhoto: () =>
                    setState(() => _backUploaded = true),
                onUpload: () => setState(() => _backUploaded = true),
              ),

              // Error message if ID not uploaded
              if (_submitted && (!_frontUploaded || !_backUploaded)) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 14, color: Color(0xFFE53935)),
                    SizedBox(width: 4),
                    Text('Both ID photos are required',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFFE53935))),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // ── OR divider ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 20),

              // Apple Pay
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.phone_iphone, size: 20),
                  label: const Text('Apple Pay',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              // Google Pay
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pay,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.g_mobiledata_rounded,
                      color: Color(0xFFEA4335), size: 26),
                  label: const Text('Google Pay',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        color: Colors.white,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _pay,
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
                : Text(
                    'Pay Now  –  ${widget.totalPrice} EGP',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0D8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cardholder name
          _fieldLabel('Cardholder Name'),
          const SizedBox(height: 8),
          _ValidatedInput(
            controller: _nameController,
            hint: 'Full name on card',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            validator: _validateName,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Card number
          _fieldLabel('Card Number'),
          const SizedBox(height: 8),
          _ValidatedInput(
            controller: _cardController,
            hint: '1234  5678  9012  3456',
            icon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number,
            validator: _validateCardNumber,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            letterSpacing: 2,
          ),
          const SizedBox(height: 16),

          // Expiry + CVV row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Expiry Date'),
                    const SizedBox(height: 8),
                    _ValidatedInput(
                      controller: _expiryController,
                      hint: 'MM/YY',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      validator: _validateExpiry,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryFormatter(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('CVV'),
                    const SizedBox(height: 8),
                    _ValidatedInput(
                      controller: _cvvController,
                      hint: '•••',
                      icon: Icons.lock_outline,
                      obscure: true,
                      keyboardType: TextInputType.number,
                      validator: _validateCvv,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8090B0)));
}

// ─── Saved card tile ──────────────────────────────────────────────────────────

class _SavedCardTile extends StatelessWidget {
  final String maskedCard;
  final String expiry;
  final VoidCallback onEdit;

  const _SavedCardTile({
    required this.maskedCard,
    required this.expiry,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF3B6FE8).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF1A1F71),
                borderRadius: BorderRadius.circular(4)),
            child: const Text('VISA',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(maskedCard,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: 1.5)),
                Text('Expires $expiry',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8090B0))),
              ],
            ),
          ),
          const Icon(Icons.check_circle,
              color: Color(0xFF3B6FE8), size: 20),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: const Text('Edit',
                style: TextStyle(
                    color: Color(0xFF3B6FE8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Validated text input ─────────────────────────────────────────────────────

class _ValidatedInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final double letterSpacing;
  final TextCapitalization textCapitalization;

  const _ValidatedInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.letterSpacing = 0,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1A2E),
          letterSpacing: letterSpacing),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            letterSpacing: letterSpacing),
        prefixIcon:
            Icon(icon, color: const Color(0xFF8090B0), size: 18),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF3B6FE8), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE53935), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFE53935), width: 1.5)),
        errorStyle: const TextStyle(
            color: Color(0xFFE53935),
            fontSize: 11,
            fontWeight: FontWeight.w500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
    );
  }
}

// ─── ID upload box ────────────────────────────────────────────────────────────

class _IdUploadBox extends StatelessWidget {
  final bool uploaded;
  final bool hasError;
  final VoidCallback onTakePhoto;
  final VoidCallback onUpload;

  const _IdUploadBox({
    required this.uploaded,
    required this.onTakePhoto,
    required this.onUpload,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.transparent;
    if (uploaded) borderColor = const Color(0xFF3B6FE8);
    if (hasError) borderColor = const Color(0xFFE53935);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFFF5F5)
            : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            uploaded
                ? Icons.check_circle
                : hasError
                    ? Icons.error_outline
                    : Icons.camera_alt_outlined,
            size: 32,
            color: uploaded
                ? const Color(0xFF3B6FE8)
                : hasError
                    ? const Color(0xFFE53935)
                    : const Color(0xFF8090B0),
          ),
          const SizedBox(height: 8),
          Text(
            uploaded
                ? 'Uploaded'
                : hasError
                    ? 'Photo required'
                    : 'Take photo or upload',
            style: TextStyle(
                fontSize: 13,
                color: uploaded
                    ? const Color(0xFF3B6FE8)
                    : hasError
                        ? const Color(0xFFE53935)
                        : const Color(0xFF8090B0)),
          ),
          if (!uploaded) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UploadBtn(label: 'Take Photo', onPressed: onTakePhoto),
                const SizedBox(width: 12),
                _UploadBtn(label: 'Upload', onPressed: onUpload),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _UploadBtn({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B6FE8),
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

// ─── Formatters ───────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\s'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
        text: formatted,
        selection:
            TextSelection.collapsed(offset: formatted.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
        text: formatted,
        selection:
            TextSelection.collapsed(offset: formatted.length));
  }
}
