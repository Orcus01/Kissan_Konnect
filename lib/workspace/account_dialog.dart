import 'package:flutter/material.dart';
import '../services/workspace_api.dart';
import 'common.dart';

class AccountDialog extends StatefulWidget {
  final WorkspaceApi api;
  const AccountDialog({super.key, required this.api});
  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  late final TextEditingController _name;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.api.user.value?['name']);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.updateName(_name.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.signOut();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Your account'),
          content: SizedBox(
              width: 420,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionLabel('Firebase account'),
                    const SizedBox(height: 12),
                    Text(widget.api.user.value?['email'] ?? '',
                        style: const TextStyle(color: muted)),
                    const SizedBox(height: 24),
                    TextField(
                        controller: _name,
                        enabled: !_busy,
                        maxLength: 80,
                        decoration:
                            const InputDecoration(labelText: 'Your name')),
                    const SizedBox(height: 12),
                    const Text(
                        'Your notebook and plant conversations are private to this account. Use the password reset link on the sign-in screen if you need account recovery.',
                        style: TextStyle(fontSize: 13, color: muted)),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)))
                  ])),
          actions: [
            TextButton(
                onPressed: _busy ? null : _logout,
                child: const Text('Sign out')),
            FilledButton(
                onPressed: _busy ? null : _save, child: const Text('Save name'))
          ]);
}
