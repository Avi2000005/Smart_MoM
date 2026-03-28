// screens/login_screen.dart
 
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';
import '../services/auth_service.dart';
 
class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
 
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
 
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
 
  bool _obscure = true;
  bool _loading = false;
 
  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;
 
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _login() async {
 
    if (!(_formKey.currentState?.validate() ?? false)) return;
 
    setState(() => _loading = true);
 
    final res = await AuthService.login(_userCtrl.text.trim(), _passCtrl.text);
 
    setState(() => _loading = false);
 
    if (!mounted) return;
 
    final msg = res["message"] as String? ?? "Something went wrong";
 
    if (msg == "Login successful") {
      widget.onLogin();
      return;
    }
 
    // If email is not verified, redirect to OTP screen
    if (res["requiresVerification"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please verify your email first."),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: res["email"] ?? _userCtrl.text.trim(),
          ),
        ),
      );
      return;
    }
 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }
 
  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }
 
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
                      color: isDark ? AppColors.darkCard : Colors.white,
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
 
                          // ── Logo ─────────────────────────────────────────
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
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
 
                          const SizedBox(height: 22),
 
                          Text(
                            'Smart MoM',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
 
                          const SizedBox(height: 6),
 
                          Text(
                            'Welcome back! Please login to continue.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
 
                          const SizedBox(height: 32),
 
                          // ── Email ─────────────────────────────────────────
                          TextFormField(
                            controller: _userCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
 
                          const SizedBox(height: 16),
 
                          // ── Password ──────────────────────────────────────
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
 
                          const SizedBox(height: 28),
 
                          // ── Login Button ──────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: _loading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ),
 
                          const SizedBox(height: 20),
 
                          // ── Register link ─────────────────────────────────
                          GestureDetector(
                            onTap: _openRegister,
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: const [
                                  TextSpan(
                                    text: 'Register',
                                    style: TextStyle(
                                      color: AppColors.primaryAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}