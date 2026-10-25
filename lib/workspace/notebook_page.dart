import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/workspace_api.dart';
import 'common.dart';

class NotebookPage extends StatefulWidget {
  final WorkspaceApi? api;
  final bool active;
  const NotebookPage({super.key, this.api, this.active = true});
  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  List<Map<String, dynamic>>? _scans;
  String _query = '';
  String? _error;
  bool _loading = false;
  WorkspaceApi get api => widget.api ?? workspaceApi;
  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(covariant NotebookPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scans = await api.scans();
      if (mounted) {
        setState(() {
          _scans = scans;
        });
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
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = (_scans ?? [])
        .where((scan) =>
            '${scan['result']['selected_crop']} ${candidateTitle(scan['result'])} ${scan['notes']}'
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();
    return RefreshIndicator(
        onRefresh: _load,
        child: workspaceBody([
          sectionLabel('Field notebook'),
          Row(children: [
            Expanded(child: pageTitle(context, 'Your leaf records.')),
            IconButton(
                tooltip: 'Refresh notebook',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh))
          ]),
          const Text(
              'Your latest 200 saved photos, model suggestions and observations. Stored on this local service, separate from your Firebase account.',
              style: TextStyle(color: muted)),
          const SizedBox(height: 24),
          TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search crop, suggestion or notes',
                  border: OutlineInputBorder()),
              onChanged: (value) => setState(() {
                    _query = value;
                  })),
          const SizedBox(height: 24),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) errorNotice(_error!, _load),
          if (!_loading && _error == null && filtered.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(children: [
                  const Icon(Icons.menu_book_outlined, size: 42, color: muted),
                  const SizedBox(height: 16),
                  Text(
                      (_scans ?? []).isEmpty
                          ? 'No saved scans yet.'
                          : 'No matching records.',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                      (_scans ?? []).isEmpty
                          ? 'Run a leaf screening, then save the photo with your field notes.'
                          : 'Try a different crop or note.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: muted))
                ])),
          ...filtered.map((scan) => Column(children: [
                ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(api.imageUrl(scan['image_url']),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined))),
                    title: Text(candidateTitle(scan['result']),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${scan['result']['dataset_sample'] == true ? 'Dataset demonstration · ' : ''}${DateFormat.yMMMd().add_jm().format(DateTime.parse(scan['created_at']).toLocal())}\n${(scan['notes'] as String).isEmpty ? 'Unverified screening · No notes' : scan['notes']}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) =>
                              NotebookDetail(scan: scan, api: api)));
                      if (mounted) _load();
                    }),
                const Divider(height: 1),
              ])),
        ]));
  }
}

class NotebookDetail extends StatefulWidget {
  final Map<String, dynamic> scan;
  final WorkspaceApi api;
  const NotebookDetail({super.key, required this.scan, required this.api});
  @override
  State<NotebookDetail> createState() => _NotebookDetailState();
}

class _NotebookDetailState extends State<NotebookDetail> {
  late final TextEditingController _notes;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.scan['notes']);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.update(widget.scan['id'], _notes.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Field notes updated')));
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Delete this record?'),
                content: const Text(
                    'This removes the saved photo, model suggestion and notes from the local notebook.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep record')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete record'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.delete(widget.scan['id']);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = Map<String, dynamic>.from(widget.scan['result']);
    return Scaffold(
        appBar: AppBar(title: const Text('Saved leaf record')),
        body: workspaceBody([
          sectionLabel(
              '${result['dataset_sample'] == true ? 'Dataset demonstration' : 'Unverified screening'} / ${result['selected_crop']}'),
          pageTitle(context, candidateTitle(result)),
          Text(
              DateFormat.yMMMd()
                  .add_jm()
                  .format(DateTime.parse(widget.scan['created_at']).toLocal()),
              style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                  widget.api.imageUrl(widget.scan['image_url']),
                  height: 280,
                  fit: BoxFit.contain)),
          const SizedBox(height: 24),
          CandidateList(result: result),
          const SizedBox(height: 24),
          TextField(
              controller: _notes,
              enabled: !_busy,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                  labelText: 'Field notes', border: OutlineInputBorder())),
          FilledButton(
              onPressed: _busy ? null : _update,
              child: const Text('Update field notes')),
          TextButton.icon(
              onPressed: () => copyReport(context, result, _notes.text),
              icon: const Icon(Icons.copy),
              label: const Text('Copy screening report')),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          const Divider(height: 40),
          Text(
              'Model version: ${result['model_version']}\nModel output has not been confirmed by an expert.',
              style: const TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 20),
          TextButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete record and photo')),
        ], width: 720));
  }
}
