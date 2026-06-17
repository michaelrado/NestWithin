import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/nest_scope.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// Create an account — name, email, how you heard about us, and a quick rating.
/// Unlocks the full library. (Email confirmation + password reset are handled
/// server-side via Mailgun once the backend is configured.)
class SignupScreen extends StatefulWidget {
  /// Optional context line, e.g. "Create an account to unlock this practice."
  final String? reason;
  const SignupScreen({super.key, this.reason});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String _referral = 'A friend';
  int _rating = 5;
  bool _anonymous = false;
  bool _submitting = false;

  static const _referralOptions = [
    'A friend',
    'The Nest studio',
    'Instagram',
    'TikTok',
    'Search',
    'Podcast',
    'Other',
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await NestScope.read(context).signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        referral: _referral,
        rating: _rating,
        anonymous: _anonymous,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome to the Nest, ${_name.text.trim().split(' ').first}. '
          'Everything is unlocked.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: NestColors.cream,
      appBar: AppBar(title: const Text('Create your account')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Center(
              child: Image.asset('assets/brand/logo_mark_blue.png', width: 72),
            ),
            const SizedBox(height: 16),
            Text(
              widget.reason ?? 'Join the Nest',
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(color: NestColors.blueDeep),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock every practice, save your progress, and earn badges.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: NestColors.inkSoft),
            ),
            const SizedBox(height: 24),
            _field(
              controller: _name,
              label: 'Your name',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please add your name'
                  : null,
            ),
            const SizedBox(height: 14),
            _field(
              controller: _email,
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                final s = v?.trim() ?? '';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                return ok ? null : 'Please enter a valid email';
              },
            ),
            const SizedBox(height: 14),
            _field(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: NestColors.inkSoft,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  (v == null || v.length < 8) ? 'At least 8 characters' : null,
            ),
            const SizedBox(height: 14),
            _dropdown(),
            const SizedBox(height: 22),
            Text(
              'How would you rate The Nest so far?',
              style: text.titleSmall?.copyWith(color: NestColors.ink),
            ),
            const SizedBox(height: 8),
            _stars(),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: NestColors.blue,
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              title: Text(
                'Stay anonymous in community stats',
                style: text.titleSmall?.copyWith(color: NestColors.ink),
              ),
              subtitle: Text(
                'You’ll appear as “Anonymous” on leaderboards.',
                style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 12),
            Text(
              'We’ll send a confirmation email to verify your address. '
              'No spam, ever.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: NestColors.blue),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _referral,
      decoration: InputDecoration(
        labelText: 'How did you hear about us?',
        prefixIcon: const Icon(Icons.campaign_outlined, color: NestColors.blue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        for (final o in _referralOptions)
          DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: (v) => setState(() => _referral = v ?? _referral),
    );
  }

  Widget _stars() {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => setState(() => _rating = i),
            icon: Icon(
              i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: NestColors.clay,
              size: 36,
            ),
          ),
      ],
    );
  }
}
