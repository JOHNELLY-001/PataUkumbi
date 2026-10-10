import 'package:e_venues/services/api_client.dart';
import 'package:e_venues/theme/tokens.dart';
import 'package:e_venues/ui/ui.dart';
import 'package:e_venues/widgets/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscure = true;
  final _formkey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _passwordMirror = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_passwordMirror != _passwordController.text && mounted) {
        setState(() => _passwordMirror = _passwordController.text);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    // Backend takes first_name/last_name: split "Jane Doe" -> (Jane, Doe).
    final parts =
        _nameController.text.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName =
        parts.length > 1 ? parts.sublist(1).join(' ') : '-';

    final auth = context.read<AuthProvider>();
    try {
      await auth.register(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      AppSnack.success(context, 'Account created. Please log in.');
      Navigator.of(context).pushReplacementNamed('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnack.error(
          context, friendlyAuthError(e, isLogin: false));
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().loading;
    return AuthShell(
      title: 'Create account',
      subtitle: 'Save venues and book in seconds.',
      child: Form(
        key: _formkey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Full name', hintText: 'Jane Doe'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: 'Email', hintText: 'you@example.com'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone', hintText: '+255 ...'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: '6 or more characters',
                suffixIcon: IconButton(
                  tooltip:
                      _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure
                      ? AppIcons.showPassword
                      : AppIcons.hidePassword),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Password required';
                }
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            _PasswordRules(password: _passwordMirror),
            const SizedBox(height: 24),
            AppButton(
              label: 'Sign up',
              loading: isLoading,
              onPressed: () {
                if (_formkey.currentState!.validate()) _signup();
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: AppTokens.inkSecondary)),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Log in',
                      style: TextStyle(
                          color: AppTokens.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Live password checklist: each rule flips grey -> green as it is met.
class _PasswordRules extends StatelessWidget {
  final String password;
  const _PasswordRules({required this.password});

  @override
  Widget build(BuildContext context) {
    return _RuleRow(
      met: password.length >= 6,
      label: 'At least 6 characters',
    );
  }
}

class _RuleRow extends StatelessWidget {
  final bool met;
  final String label;
  const _RuleRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppTokens.success : AppTokens.inkTertiary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(met ? AppIcons.checkCircle : AppIcons.checkCircle,
              size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
