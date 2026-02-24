import 'package:flutter/material.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _submitted = false;

  bool _emailTouched = false;
  bool _passTouched = false;
  bool _confirmTouched = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!regex.hasMatch(v)) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain at least one number';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _submit() {
    setState(() {
      _submitted = true;
      _emailTouched = true;
      _passTouched = true;
      _confirmTouched = true;
    });

    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;
    if (!_frontUploaded || !_backUploaded) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  bool _fieldHasError(String? Function(String?) validator, TextEditingController c, bool touched) {
    return touched && validator(c.text) != null;
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool hasError,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(
        icon,
        color: hasError ? const Color(0xFFE53935) : Colors.grey[400],
        size: 20,
      ),
      filled: true,
      fillColor: hasError ? const Color(0xFFFFF5F5) : const Color(0xFFF5F7FF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: hasError ? const BorderSide(color: Color(0xFFE53935), width: 1.5) : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFE53935) : const Color(0xFF3B6FE8),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailError = _fieldHasError(_validateEmail, _emailController, _emailTouched);
    final passError = _fieldHasError(_validatePassword, _passwordController, _passTouched);
    final confirmError = _fieldHasError(_validateConfirm, _confirmController, _confirmTouched);
    final frontMissing = _submitted && !_frontUploaded;
    final backMissing = _submitted && !_backUploaded;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create an account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 28),

              // ── Email ──
              _label('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: _emailTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                onChanged: (_) => setState(() => _emailTouched = true),
                decoration: _inputDecoration(hint: 'you@example.com', icon: Icons.email_outlined, hasError: emailError),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),

              // ── Password ──
              _label('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePass,
                autovalidateMode: _passTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                onChanged: (_) => setState(() => _passTouched = true),
                decoration: _inputDecoration(hint: 'Min 8 chars, 1 uppercase, 1 number', icon: Icons.lock_outline, hasError: passError).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[400], size: 20),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              // ── Confirm Password ──
              _label('Confirm password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                autovalidateMode: _confirmTouched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                onChanged: (_) => setState(() => _confirmTouched = true),
                decoration: _inputDecoration(hint: 'Re-enter your password', icon: Icons.lock_outline, hasError: confirmError).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey[400], size: 20),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _validateConfirm,
              ),
              const SizedBox(height: 28),

              // ── ID Upload ──
              const Text(
                'Upload clear photos of your national ID',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 12),
              _label('ID Front Side'),
              const SizedBox(height: 8),
              _uploadBox('Front Side', _frontUploaded, frontMissing, () => setState(() => _frontUploaded = true)),
              const SizedBox(height: 12),
              _label('ID Back Side'),
              const SizedBox(height: 8),
              _uploadBox('Back Side', _backUploaded, backMissing, () => setState(() => _backUploaded = true)),
              const SizedBox(height: 32),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6FE8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Sign up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
      );

  Widget _uploadBox(String label, bool uploaded, bool hasError, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              color: uploaded
                  ? const Color(0xFFEEF2FF)
                  : hasError
                      ? const Color(0xFFFFF5F5)
                      : const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: uploaded
                    ? const Color(0xFF3B6FE8)
                    : hasError
                        ? const Color(0xFFE53935)
                        : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  uploaded ? Icons.check_circle_outline : Icons.camera_alt_outlined,
                  color: uploaded
                      ? const Color(0xFF3B6FE8)
                      : hasError
                          ? const Color(0xFFE53935)
                          : Colors.grey[400],
                  size: 28,
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uploaded ? '$label uploaded ✓' : 'Take Photo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: uploaded
                            ? const Color(0xFF3B6FE8)
                            : hasError
                                ? const Color(0xFFE53935)
                                : const Color(0xFF1A1A2E),
                      ),
                    ),
                    if (!uploaded)
                      Text(
                        'or  Upload',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasError ? const Color(0xFFE53935) : Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Please upload a photo of this side',
              style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
}
