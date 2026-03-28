// screens/register_screen.dart
 
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';
 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
 
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen> {
 
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confirmCtrl = TextEditingController();
 
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
 
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _register() async {
 
    if (!(_formKey.currentState?.validate() ?? false)) return;
 
    setState(() => _loading = true);
 
    final res = await AuthService.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
      mobile: _mobileCtrl.text.trim(),
    );
 
    setState(() => _loading = false);
 
    if (!mounted) return;
 
    final msg = res["message"] as String? ?? "Something went wrong";
 
    // Both "Registration successful" and "OTP resent" should go to OTP screen
    if (msg.contains("verify your email") ||
        msg.contains("OTP resent") ||
        msg.contains("Registration successful")) {
 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: res["email"] ?? _emailCtrl.text.trim(),
          ),
        ),
      );
 
    } else {
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
      );
 
    }
  }
 
  @override
  Widget build(BuildContext context) {
 
    final isDark = Theme.of(context).brightness == Brightness.dark;
 
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
 
                    // ── Header ───────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Create Account",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Register to get started with Smart MoM",
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
 
                    const SizedBox(height: 28),
 
                    // ── Full Name ────────────────────────────────────────────
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Full name is required" : null,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
 
                    const SizedBox(height: 14),
 
                    // ── Email ────────────────────────────────────────────────
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Email is required";
                        final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                        if (!re.hasMatch(v)) return "Enter a valid email";
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
 
                    const SizedBox(height: 14),
 
                    // ── Mobile Number ────────────────────────────────────────
                    TextFormField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null; // optional
                        final re = RegExp(r'^\+?[0-9]{7,15}$');
                        if (!re.hasMatch(v)) return "Enter a valid mobile number";
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: "Mobile Number (Optional)",
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: "+91XXXXXXXXXX",
                      ),
                    ),
 
                    const SizedBox(height: 14),
 
                    // ── Password ─────────────────────────────────────────────
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Password is required";
                        if (v.length < 6) return "Password must be at least 6 characters";
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                    ),
 
                    const SizedBox(height: 14),
 
                    // ── Confirm Password ─────────────────────────────────────
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Please confirm your password";
                        if (v != _passCtrl.text) return "Passwords do not match";
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
 
                    const SizedBox(height: 26),
 
                    // ── Register Button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text(
                                "Create Account",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
 
                    const SizedBox(height: 18),
 
                    // ── Back to login ────────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                text: "Login",
                                style: TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
 