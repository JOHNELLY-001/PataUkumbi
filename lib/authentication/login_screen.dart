import 'package:e_venues/services/api_client.dart';
import 'package:e_venues/theme/tokens.dart';
import 'package:e_venues/ui/ui.dart';
import 'package:e_venues/widgets/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnack.error(
          context, friendlyAuthError(e, isLogin: true));
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, 'Something went wrong. Please try again.');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Log in to find and book great venues.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                  labelText: 'Email', hintText: 'you@example.com'),
              validator: (value) =>
                  (value == null || !value.contains('@'))
                      ? 'Enter a valid email address'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Your password',
                suffixIcon: IconButton(
                  tooltip:
                      _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure
                      ? AppIcons.showPassword
                      : AppIcons.hidePassword),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Enter your password'
                  : null,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Log in',
              loading: loading,
              onPressed: () {
                if (_formKey.currentState!.validate()) _login();
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ",
                    style: TextStyle(color: AppTokens.inkSecondary)),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed('/register'),
                  child: const Text('Sign up',
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
