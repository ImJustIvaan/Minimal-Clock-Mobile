import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

enum _Mode { password, magicLink }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  _Mode _mode = _Mode.password;
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = SupabaseService.client.auth;
      if (_isSignUp) {
        await auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        setState(() => _info = 'Account created. You can sign in now.');
      } else {
        await auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitMagicLink() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await SupabaseService.client.auth.signInWithOtp(
        email: _emailCtrl.text.trim(),
        emailRedirectTo: 'minimalclock://login-callback',
      );
      setState(() => _info = 'Check your email for a sign-in link.');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'minimalclock://login-callback',
      );
    } catch (e) {
      setState(() => _error = 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 4,
                    color: color.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 40),
                _Field(
                  controller: _emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_mode == _Mode.password) ...[
                  const SizedBox(height: 16),
                  _Field(
                    controller: _passwordCtrl,
                    hint: 'Password',
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                if (_info != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _info!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: color.withOpacity(0.6), fontSize: 13),
                    ),
                  ),
                _PrimaryButton(
                  label: _loading
                      ? '...'
                      : _mode == _Mode.password
                          ? (_isSignUp ? 'Sign Up' : 'Sign In')
                          : 'Send Magic Link',
                  color: color,
                  onTap: _loading
                      ? null
                      : (_mode == _Mode.password
                          ? _submitPassword
                          : _submitMagicLink),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _mode = _mode == _Mode.password
                          ? _Mode.magicLink
                          : _Mode.password),
                  child: Text(
                    _mode == _Mode.password
                        ? 'Use a magic link instead'
                        : 'Use a password instead',
                    style: TextStyle(color: color.withOpacity(0.5), fontSize: 13),
                  ),
                ),
                if (_mode == _Mode.password)
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : "Don't have an account? Sign up",
                      style: TextStyle(color: color.withOpacity(0.5), fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: color.withOpacity(0.12))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR', style: TextStyle(color: color.withOpacity(0.3), fontSize: 11)),
                    ),
                    Expanded(child: Divider(color: color.withOpacity(0.12))),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Continue with Google', style: TextStyle(color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: color, fontWeight: FontWeight.w300),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: color.withOpacity(0.3)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: color.withOpacity(0.15)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: color.withOpacity(0.6)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null ? color.withOpacity(0.3) : color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
