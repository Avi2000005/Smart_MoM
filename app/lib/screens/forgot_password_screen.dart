// screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const ForgotPasswordScreen({super.key, required this.onLogin});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────────────────────
  final _emailCtrl   = TextEditingController();
  final _otpCtrl     = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  int    _step        = 1; // 1=email, 2=otp, 3=newPassword
  bool   _loading     = false;
  bool   _obscure     = true;
  bool   _obscureConf = true;
  String _resetToken  = "";
  String _error       = "";

  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Animate step transition ────────────────────────────────────────────────
  void _goToStep(int step) {
    _animCtrl.reset();
    setState(() { _step = step; _error = ""; });
    _animCtrl.forward();
  }

  // ── STEP 1: Send OTP ───────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      return setState(() => _error = "Please enter your email.");
    }
    setState(() { _loading = true; _error = ""; });
    try {
      await AuthService.forgotPassword(_emailCtrl.text.trim());
      _goToStep(2);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── STEP 2: Verify OTP ─────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      return setState(() => _error = "Please enter the 6-digit OTP.");
    }
    setState(() { _loading = true; _error = ""; });
    try {
      final token = await AuthService.verifyResetOtp(
        _emailCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );
      _resetToken = token;
      _goToStep(3);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── STEP 3: Reset Password ─────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (_passCtrl.text.length < 6) {
      return setState(() => _error = "Password must be at least 6 characters.");
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      return setState(() => _error = "Passwords do not match.");
    }
    setState(() { _loading = true; _error = ""; });
    try {
      await AuthService.resetPassword(
        _emailCtrl.text.trim(),
        _resetToken,
        _passCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset successful! Please log in."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // back to login
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Step titles & subtitles ────────────────────────────────────────────────
  String get _title => switch (_step) {
    1 => "Forgot Password?",
    2 => "Check your email",
    _ => "Set New Password",
  };

  String get _subtitle => switch (_step) {
    1 => "Enter your email and we'll send you a 6-digit OTP.",
    2 => "Enter the OTP sent to ${_emailCtrl.text.trim()}.",
    _ => "Choose a strong password for your account.",
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.6,
                  colors: [Color(0xFF1E0A40), AppColors.darkBg],
                )
              : const LinearGradient(
                  colors: [Color(0xFFF0EBFF), Color(0xFFEAE4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // ── Back button ───────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    if (_step > 1) {
                      _goToStep(_step - 1);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.18),
                                  blurRadius: 40,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                // ── Icon ───────────────────────────────────
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.5),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _step == 1
                                        ? Icons.lock_reset_rounded
                                        : _step == 2
                                            ? Icons.mark_email_read_outlined
                                            : Icons.lock_outline_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // ── Step indicator dots ─────────────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (i) {
                                    final active = i + 1 <= _step;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width:  active ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppColors.primary
                                            : AppColors.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),

                                const SizedBox(height: 20),

                                // ── Title ───────────────────────────────────
                                Text(
                                  _title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  _subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 32),

                                // ── Step 1: Email ───────────────────────────
                                if (_step == 1)
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _sendOtp(),
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(
                                          Icons.email_outlined),
                                    ),
                                  ),

                                // ── Step 2: OTP ─────────────────────────────
                                if (_step == 2) ...[
                                  TextFormField(
                                    controller: _otpCtrl,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    maxLength: 6,
                                    onFieldSubmitted: (_) => _verifyOtp(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      letterSpacing: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      labelText: 'Enter OTP',
                                      counterText: "",
                                      prefixIcon: Icon(
                                          Icons.lock_clock_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _loading ? null : () {
                                      _otpCtrl.clear();
                                      _goToStep(1);
                                    },
                                    child: const Text(
                                      "Didn't receive OTP? Resend",
                                      style: TextStyle(
                                        color: AppColors.primaryAccent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],

                                // ── Step 3: New Password ────────────────────
                                if (_step == 3) ...[
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'New Password',
                                      prefixIcon: const Icon(
                                          Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined),
                                        onPressed: () => setState(
                                            () => _obscure = !_obscure),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmCtrl,
                                    obscureText: _obscureConf,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _resetPassword(),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      prefixIcon: const Icon(
                                          Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureConf
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined),
                                        onPressed: () => setState(
                                            () => _obscureConf = !_obscureConf),
                                      ),
                                    ),
                                  ),
                                ],

                                // ── Error box ───────────────────────────────
                                if (_error.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: Colors.red, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error,
                                            style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 28),

                                // ── Action button ───────────────────────────
                                SizedBox(
                                  width: double.infinity,
                                  child: _loading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: _step == 1
                                              ? _sendOtp
                                              : _step == 2
                                                  ? _verifyOtp
                                                  : _resetPassword,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                          ),
                                          child: Text(
                                            _step == 1
                                                ? "Send OTP"
                                                : _step == 2
                                                    ? "Verify OTP"
                                                    : "Reset Password",
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}