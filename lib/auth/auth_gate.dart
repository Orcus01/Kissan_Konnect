import 'package:flutter/material.dart';
import '../services/workspace_api.dart';
import '../workspace/workspace_page.dart';
import 'auth_page.dart';

class AuthGate extends StatefulWidget {
  final WorkspaceApi? api;
  const AuthGate({super.key, this.api});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  String? _error;
  WorkspaceApi get api => widget.api ?? workspaceApi;
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await api.restoreSession();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 40),
                    const SizedBox(height: 20),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: _restore,
                        child: const Text('Retry connection'))
                  ]))));
    }
    return ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: api.user,
        builder: (context, user, _) => user == null
            ? AuthPage(api: api)
            : WorkspacePage(key: ValueKey(user['id']), api: api));
  }
}
