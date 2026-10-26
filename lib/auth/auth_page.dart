import 'package:flutter/material.dart';
import '../services/workspace_api.dart';
import 'firebase_setup.dart';
import '../workspace/common.dart';

class AuthPage extends StatefulWidget {
  final WorkspaceApi api;
  const AuthPage({super.key, required this.api});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirmation = TextEditingController(),
      _recovery = TextEditingController();
  String _mode = 'login';
  String? _error;
  bool _busy = false, _obscure = true;
  bool get signup => _mode == 'signup';
  bool get recovery => _mode == 'recover';
  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirmation, _recovery]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switch(String mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _password.clear();
      _confirmation.clear();
      _recovery.clear();
      _form.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'email': _email.text.trim(),
        'password': _password.text
      };
      if (signup) data['name'] = _name.text.trim();
      if (recovery) data['recovery_code'] = _recovery.text.trim();
      final response = await widget.api.authenticate(_mode, data);
      if (!mounted) return;
      if (response['reset_sent'] == true) {
        _switch('login');
        setState(() => _error =
            'If this email has an account, check its inbox for a password reset link.');
      } else {
        widget.api.acceptUser(Map<String, dynamic>.from(response['user']));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  InputDecoration _decoration(String label, IconData icon) =>
      InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20));
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final form = Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: wide ? 36 : 24, vertical: 32),
                    child: AutofillGroup(
                        child: Form(
                            key: _form,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (FirebaseSetup.emulatorMode) ...[
                                    const Text('LOCAL ACCOUNT DEMO',
                                        style: TextStyle(
                                            color: ink,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    const Text(
                                        'Uses the Firebase emulator. Test accounts stay on this computer. Use a test password and sign in again after reloading.',
                                        style: TextStyle(color: muted)),
                                    const SizedBox(height: 24),
                                  ],
                                  if (!wide) ...[
                                    const Row(children: [
                                      Icon(Icons.spa_outlined, color: ink),
                                      SizedBox(width: 10),
                                      Expanded(
                                          child: Text('Kissan Konnect',
                                              style: TextStyle(
                                                  fontSize: 23,
                                                  fontWeight: FontWeight.w700,
                                                  color: ink)))
                                    ]),
                                    const SizedBox(height: 40)
                                  ],
                                  sectionLabel(signup
                                      ? 'Start growing with us'
                                      : recovery
                                          ? 'Account recovery'
                                          : 'Your growing workspace'),
                                  const SizedBox(height: 16),
                                  Text(
                                      signup
                                          ? 'Make room for\nbetter plant care.'
                                          : recovery
                                              ? 'Let’s get you back.'
                                              : 'Welcome back.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: ink,
                                              fontSize: wide ? 40 : 34,
                                              height: 1.1,
                                              letterSpacing: -1.2)),
                                  const SizedBox(height: 14),
                                  Text(
                                      signup
                                          ? 'Create an account to keep your leaf scans, notes and plant conversations together.'
                                          : recovery
                                              ? 'Enter your email to request a password reset link.'
                                              : 'Your plants, observations and growing guides, in one place.',
                                      style: const TextStyle(
                                          color: muted,
                                          height: 1.6,
                                          fontSize: 16)),
                                  const SizedBox(height: 32),
                                  if (signup) ...[
                                    TextFormField(
                                        controller: _name,
                                        enabled: !_busy,
                                        autofillHints: const [
                                          AutofillHints.name
                                        ],
                                        textCapitalization:
                                            TextCapitalization.words,
                                        decoration: _decoration(
                                            'Your name', Icons.person_outline),
                                        validator: (value) => value == null ||
                                                value.trim().length < 2
                                            ? 'Enter your name.'
                                            : null),
                                    const SizedBox(height: 18)
                                  ],
                                  TextFormField(
                                      controller: _email,
                                      enabled: !_busy,
                                      autofillHints: const [
                                        AutofillHints.username
                                      ],
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: _decoration('Email address',
                                          Icons.alternate_email),
                                      validator: (value) => value == null ||
                                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                  .hasMatch(value.trim())
                                          ? 'Enter a valid email address.'
                                          : null),
                                  const SizedBox(height: 18),
                                  if (!recovery)
                                    TextFormField(
                                        controller: _password,
                                        enabled: !_busy,
                                        obscureText: _obscure,
                                        autofillHints: signup || recovery
                                            ? const [AutofillHints.newPassword]
                                            : const [AutofillHints.password],
                                        onFieldSubmitted: (_) {
                                          if (!signup && !recovery) _submit();
                                        },
                                        decoration: _decoration(
                                                recovery
                                                    ? 'New password'
                                                    : 'Password',
                                                Icons.lock_outline)
                                            .copyWith(
                                                helperText: signup || recovery
                                                    ? 'At least 12 characters. A passphrase works well.'
                                                    : null,
                                                suffixIcon: IconButton(
                                                    tooltip: _obscure
                                                        ? 'Show password'
                                                        : 'Hide password',
                                                    onPressed: () => setState(() =>
                                                        _obscure = !_obscure),
                                                    icon: Icon(
                                                        _obscure
                                                            ? Icons
                                                                .visibility_outlined
                                                            : Icons.visibility_off_outlined,
                                                        size: 20))),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Enter your password.';
                                          }
                                          if ((signup || recovery) &&
                                              (value.length < 12 ||
                                                  value.length > 128)) {
                                            return 'Use between 12 and 128 characters.';
                                          }
                                          return null;
                                        }),
                                  if (signup) ...[
                                    const SizedBox(height: 18),
                                    TextFormField(
                                        controller: _confirmation,
                                        enabled: !_busy,
                                        obscureText: true,
                                        decoration: _decoration(
                                            'Confirm password',
                                            Icons.check_circle_outline),
                                        validator: (value) =>
                                            value != _password.text
                                                ? 'The passwords do not match.'
                                                : null)
                                  ],
                                  if (!signup && !recovery)
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _switch('recover'),
                                            child: const Text(
                                                'Forgot your password?'))),
                                  if (_error != null)
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: Text(_error!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error))),
                                  const SizedBox(height: 20),
                                  FilledButton(
                                      onPressed: _busy ? null : _submit,
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: _busy
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : Text(signup
                                                  ? 'Create account'
                                                  : recovery
                                                      ? 'Send reset link'
                                                      : 'Sign in'))),
                                  const SizedBox(height: 20),
                                  Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                            signup
                                                ? 'Already growing with us?'
                                                : recovery
                                                    ? 'Remember your password?'
                                                    : 'New to Kissan Konnect?',
                                            style:
                                                const TextStyle(color: muted)),
                                        TextButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _switch(
                                                    signup || recovery
                                                        ? 'login'
                                                        : 'signup'),
                                            child: Text(signup || recovery
                                                ? 'Sign in'
                                                : 'Create an account'))
                                      ]),
                                  const SizedBox(height: 28),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  const Text(
                                      'PRIVATE BY ACCOUNT\nYour notes and conversations stay on this service and are visible only when you sign in.',
                                      style: TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                          height: 1.7)),
                                ]))))));
        if (!wide) return form;
        return Row(children: [
          Expanded(
              flex: 5,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset('assets/images/image1.jpg', fit: BoxFit.cover),
                const ColoredBox(color: Color(0xCC123B2A)),
                const Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.spa_outlined,
                                color: Colors.white, size: 30),
                            SizedBox(width: 12),
                            Text('Kissan Konnect',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28))
                          ]),
                          Spacer(),
                          Text('A little care.\nA healthier\ngrowing season.',
                              style: TextStyle(
                                  color: Color(0xFFF5F8EE),
                                  fontSize: 54,
                                  fontWeight: FontWeight.w700,
                                  height: 1.08,
                                  letterSpacing: -2)),
                          SizedBox(height: 24),
                          Text(
                              'Check a leaf. Keep a record.\nUnderstand your plants.',
                              style: TextStyle(
                                  color: Color(0xFFD0DFD0),
                                  fontSize: 18,
                                  height: 1.7)),
                          SizedBox(height: 48),
                          Row(children: [
                            Icon(Icons.eco_outlined,
                                color: Color(0xFFC5E1AF), size: 18),
                            SizedBox(width: 10),
                            Text('Built for curious growers',
                                style: TextStyle(color: Color(0xFFD0DFD0)))
                          ]),
                        ]))
              ])),
          Expanded(flex: 6, child: form)
        ]);
      })));
}
