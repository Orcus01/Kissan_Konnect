import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/workspace_api.dart';
import '../workspace/common.dart';

class OutputPage extends StatefulWidget {
  final Uint8List imageBytes;
  final String crop;
  final bool sample;
  final WorkspaceApi? api;
  const OutputPage(
      {super.key,
      required this.imageBytes,
      this.crop = 'Tomato',
      this.sample = false,
      this.api});
  @override
  State<OutputPage> createState() => _OutputPageState();
}

class _OutputPageState extends State<OutputPage> {
  final _notes = TextEditingController();
  Map<String, dynamic>? _result;
  String? _error;
  bool _busy = false, _saved = false, _saving = false;
  WorkspaceApi get api => widget.api ?? workspaceApi;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await api.predict(widget.imageBytes, widget.crop);
      if (mounted) {
        setState(() {
          _result = result;
          _saved = false;
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
          _busy = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await api.save(_result!['id'], _notes.text);
      if (mounted) {
        setState(() {
          _saved = true;
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
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaf review')),
      body: workspaceBody([
        sectionLabel(
            '${widget.crop} / ${widget.sample ? 'Dataset demonstration' : 'Your photo'}'),
        pageTitle(context,
            result == null ? 'Ready to screen.' : candidateTitle(result)),
        ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
                color: const Color(0xFFE8EBDD),
                child: Image.memory(widget.imageBytes,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                        height: 200,
                        child: Center(
                            child: Text(
                                'Photo could not be displayed. Choose another image.')))))),
        const SizedBox(height: 20),
        if (widget.sample)
          const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                  'PlantVillage sample with a known early-blight label. This is a demonstration from the training dataset family, not an independent accuracy test.',
                  style: TextStyle(color: muted))),
        if (result == null) ...[
          const Text(
              'Use a single, clear leaf from the selected crop. The local model compares 15 trained classes; it cannot reliably reject non-leaf photos or diagnose an unsupported disease.'),
          const SizedBox(height: 12),
          const Text(
              'Processing stays on the local Kissan service. Nothing is added to your notebook until you save.'),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: _busy ? null : _analyse,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.biotech_outlined),
              label:
                  Text(_busy ? 'Running local model…' : 'Run leaf screening')),
        ],
        if (result != null) ...[
          sectionLabel(result['status'] == 'candidate'
              ? 'Unverified model suggestion'
              : 'Review needed'),
          const SizedBox(height: 12),
          Text(result['status'] == 'crop_mismatch'
              ? 'The strongest match belongs to a different crop. Check the selected crop and retake the photo. Do not use this as a disease result.'
              : result['status'] == 'uncertain'
                  ? 'The model did not produce a clear match. Retake a close, well-lit photo and seek expert assessment if symptoms continue.'
                  : 'This is a research model match, not a confirmed diagnosis. Field performance has not been independently validated. A “healthy” match does not rule out a problem.'),
          const SizedBox(height: 28),
          CandidateList(result: result),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Record what you see',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 8),
          const Text(
              'Note when symptoms started, which leaves are affected, and recent watering or weather changes. Ask an agricultural adviser before choosing treatment.'),
          const SizedBox(height: 16),
          TextField(
              controller: _notes,
              maxLines: 3,
              maxLength: 2000,
              enabled: !_saved && !_saving,
              decoration: const InputDecoration(
                  labelText: 'Field notes (optional)',
                  hintText: 'Plot name, symptoms, date first observed…',
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _saved || _saving ? null : _save,
              icon: Icon(_saved ? Icons.check : Icons.bookmark_add_outlined),
              label: Text(_saved
                  ? 'Saved to notebook'
                  : _saving
                      ? 'Saving…'
                      : 'Save photo and notes')),
          TextButton.icon(
              onPressed: () => copyReport(context, result, _notes.text),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy screening report')),
          const SizedBox(height: 8),
          Text(
              '${result['model_name']} · ${result['elapsed_ms']} ms on local service\nVersion ${(result['model_version'] as String).substring(0, 8)} · No images sent to a third-party AI service',
              style: const TextStyle(fontSize: 12, color: muted)),
        ],
        if (_error != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 12),
        TextButton.icon(
            onPressed: _busy || _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Choose another photo')),
      ], width: 720),
    );
  }
}
