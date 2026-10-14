import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import 'register_page.dart';

class LoginScreen extends StatefulWidget {
  final Store store;

  const LoginScreen({super.key, required this.store});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _busy = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await widget.store.login(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      // Let Android's autofill service offer to save these credentials.
      TextInput.finishAutofillContext(shouldSave: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: scheme.primaryContainer,
                      child: Text('SY',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer)),
                    ),
                    const SizedBox(height: 16),
                    Text('Sura Yangu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Skincare & cosmetics marketplace',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email
                      ],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                    const SizedBox(height: 8),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            style: TextStyle(color: scheme.error)),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(store: widget.store),
                        ),
                      ),
                      child: const Text('Create an account'),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Demo accounts',
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Customer: zawadi@example.com / customer123\n'
                              'Seller: neema@kilimanjaroskin.tz / seller123\n'
                              'Admin: admin@surayangu.co.tz / admin123',
                              style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}
