// lib/screens/register_screen.dart
// REPLACE your existing register_screen.dart with this file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      username: _usernameCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMsg ?? 'Registration failed.')));
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Helper to build a styled text field ───────────────────────────────────
  Widget _field(TextEditingController ctrl,
      {required String hint,
      required IconData icon,
      bool obscure = false,
      String? helper,
      TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const RoleRosterLogo(
                size: 44,
                textColor: AppColors.white,
              ),
              const SizedBox(height: 40),
              _buildCredentials(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 0: Email / Password ───────────────────────────────────────────────
  Widget _buildCredentials(bool isLoading) {
    return AuthCard(
      children: [
        const Text('Register',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _field(_usernameCtrl, hint: 'Username', icon: Icons.person_outline),
        const SizedBox(height: 12),
        _field(_emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(_passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscure: true,
            helper: 'Must contain letters, numbers, and special characters'),
        const SizedBox(height: 12),
        _field(_confirmCtrl,
            hint: 'Confirm password', icon: Icons.lock_outline, obscure: true),
        const SizedBox(height: 20),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : RRButton(
                label: 'Register',
                onTap: _register,
              ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Already have Account?',
              style: TextStyle(color: AppColors.textMid)),
        ),
      ],
    );
  }
}
