// screens/otp_verification_screen.dart
 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
 
class OtpVerificationScreen extends StatefulWidget {
 
  final String email;
 
  const OtpVerificationScreen({super.key, required this.email});
 
  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}
 
class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
 
  // 6 individual OTP digit controllers + focus nodes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());
 
  bool _loading      = false;
  bool _resending    = false;
  int  _resendCooldown = 0;     // seconds remaining before resend is allowed
 
  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }
 
  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }
 
  // ── Cooldown timer ─────────────────────────────────────────────────────────
 
  void _startResendCooldown([int seconds = 60]) {
    setState(() => _resendCooldown = seconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }
 
  // ── Collect OTP string from all boxes ────────────────────────────────────
 
  String get _otp => _controllers.map((c) => c.text).join();
 
  // ── Verify ────────────────────────────────────────────────────────────────
 
  Future<void> _verify() async {
 
    final otp = _otp;
 
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete 6-digit OTP")),
      );
      return;
    }
 
    setState(() => _loading = true);
 
    final res = await AuthService.verifyEmail(widget.email, otp);
 
    setState(() => _loading = false);
 
    if (!mounted) return;
 
    final msg = res["message"] as String? ?? "Something went wrong";
 
    if (msg.contains("verified successfully")) {
      // Pop all the way back to root; main.dart / app navigator will detect the
      // token in SharedPreferences and route to the home screen.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
      );
    }
  }
 
  // ── Resend OTP ────────────────────────────────────────────────────────────
 
  Future<void> _resend() async {
 
    if (_resendCooldown > 0 || _resending) return;
 
    setState(() => _resending = true);
 
    final res = await AuthService.resendOTP(widget.email);
 
    setState(() => _resending = false);
 
    if (!mounted) return;
 
    final msg = res["message"] as String? ?? "Something went wrong";
 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains("resent") ? Colors.green.shade700 : Colors.red.shade600,
      ),
    );
 
    if (msg.contains("resent")) _startResendCooldown();
  }
 
  // ── OTP box widget ────────────────────────────────────────────────────────
 
  Widget _otpBox(int index) {
 
    return SizedBox(
      width: 46,
      height: 54,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto-submit when last digit entered
          if (index == 5 && val.isNotEmpty) _verify();
        },
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
 
    final isDark = Theme.of(context).brightness == Brightness.dark;
 
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
 
                  // Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
 
                  const SizedBox(height: 20),
 
                  Text(
                    "Check Your Email",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
 
                  const SizedBox(height: 10),
 
                  Text(
                    "We sent a 6-digit verification code to",
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
 
                  const SizedBox(height: 4),
 
                  Text(
                    widget.email,
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
 
                  const SizedBox(height: 32),
 
                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, _otpBox),
                  ),
 
                  const SizedBox(height: 30),
 
                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _verify,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              "Verify Email",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
 
                  const SizedBox(height: 20),
 
                  // Resend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      _resendCooldown > 0
                          ? Text(
                              "Resend in ${_resendCooldown}s",
                              style: TextStyle(
                                color: AppColors.primary.withOpacity(0.5),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : GestureDetector(
                              onTap: _resend,
                              child: _resending
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      "Resend",
                                      style: TextStyle(
                                        color: AppColors.primaryAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}