import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common.dart';

void showModelReport(BuildContext context, Map<String, dynamic>? model) {
  showDialog<void>(
      context: context,
      builder: (context) => Dialog(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 760),
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
                    child: Row(children: [
                      Expanded(
                          child: Text('Inside the leaf model',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700))),
                      IconButton(
                          tooltip: 'Close model report',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close))
                    ])),
                const Divider(height: 1),
                Expanded(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              sectionLabel('Model transparency'),
                              const SizedBox(height: 12),
                              Text(
                                  model?['name'] ?? 'Model service unavailable',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: ink)),
                              const SizedBox(height: 12),
                              const Text(
                                  'A trained-class screening tool. A useful match is a starting point for observation, not a confirmed diagnosis.'),
                              const SizedBox(height: 24),
                              if (model?['evaluation'] is Map)
                                ..._evaluation(model!),
                              if (model?['dataset'] is Map) ...[
                                const SizedBox(height: 24),
                                sectionLabel('Dataset provenance'),
                                const SizedBox(height: 12),
                                Text(
                                    '${model!['dataset']['provider'] ?? 'Dataset'} · ${model['dataset']['slug']}\nVersion ${model['dataset']['version']} · ${model['dataset']['license']}',
                                    style: const TextStyle(height: 1.6)),
                                TextButton.icon(
                                    onPressed: () => launchUrl(
                                        Uri.parse(model['dataset']['url']),
                                        mode: LaunchMode.externalApplication),
                                    icon:
                                        const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('Open dataset record'))
                              ],
                              const SizedBox(height: 24),
                              sectionLabel('Supported crops and classes'),
                              const SizedBox(height: 12),
                              if (model?['classes'] is List)
                                Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: (model!['crops'] as List? ?? [])
                                        .map((crop) => Chip(label: Text(crop)))
                                        .toList()),
                              if (model?['classes'] is List)
                                ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: Text(
                                        'View all ${(model!['classes'] as List).length} trained classes'),
                                    children: (model['classes'] as List)
                                        .map((c) => ListTile(
                                            dense: true,
                                            title: Text(
                                                '${c['crop']} · ${c['condition']}'),
                                            subtitle: c['training_samples'] ==
                                                    null
                                                ? null
                                                : Text(
                                                    '${c['training_samples']} training images · validation F1: ${c['validation_f1'] == null ? 'unreported' : (c['validation_f1'] as num).toStringAsFixed(2)}')))
                                        .toList()),
                              const SizedBox(height: 24),
                              sectionLabel('What it cannot tell you'),
                              const SizedBox(height: 12),
                              const Text(
                                  'There is no prospective field validation or universal unknown-input detector. A high score can still be wrong, and a healthy match does not rule out a problem. Follow local expert advice before choosing treatment.',
                                  style: TextStyle(height: 1.7)),
                              const SizedBox(height: 20),
                              if (model != null)
                                Text(
                                    'Model version: ${model['version']}\nRuntime: ${model['runtime']}',
                                    style: const TextStyle(
                                        color: muted, fontSize: 12)),
                              if (model?['source'] is String)
                                TextButton.icon(
                                    onPressed: () => launchUrl(
                                        Uri.parse(model!['source']),
                                        mode: LaunchMode.externalApplication),
                                    icon: const Icon(Icons.code, size: 16),
                                    label: const Text(
                                        'Model repository and documentation'))
                            ])))
              ]))));
}

List<Widget> _evaluation(Map<String, dynamic> model) {
  final e = model['evaluation'];
  return [
    sectionLabel('Measured evaluation'),
    const SizedBox(height: 8),
    Text(e['scope'] ?? 'Held-out research split',
        style: const TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 16),
    Wrap(spacing: 32, runSpacing: 20, children: [
      _metric('${((e['test_accuracy'] as num) * 100).toStringAsFixed(2)}%',
          'Grouped-test accuracy'),
      _metric((e['macro_f1'] as num).toStringAsFixed(3), 'Macro F1'),
      _metric('${e['test_samples']}', 'Held-out images')
    ]),
    if (e['external'] is Map && e['external']['samples'] != null) ...[
      const SizedBox(height: 24),
      sectionLabel('PlantDoc source holdout'),
      const SizedBox(height: 10),
      Text(
          '${((e['external']['accuracy'] as num) * 100).toStringAsFixed(2)}% accuracy on ${e['external']['samples']} images. These source groups were excluded from training and validation.',
          style: const TextStyle(fontSize: 13, height: 1.6)),
    ],
    if (e['novelty'] is Map) ...[
      const SizedBox(height: 20),
      const Text(
          'Unsupported-photo screening uses feature similarity and image-detail checks. It is a conservative heuristic, not a universal unknown-disease detector.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.6)),
    ],
    const SizedBox(height: 18),
    Text(
        '${e['unique_images']} unique images after exclusions. Split: ${e['split_counts']['train']} train / ${e['split_counts']['validation']} validation / ${e['split_counts']['test']} test.',
        style: const TextStyle(color: muted, fontSize: 13)),
    const SizedBox(height: 12),
    Text(e['method'] ?? '', style: const TextStyle(fontSize: 13, height: 1.6)),
    const SizedBox(height: 12),
    const Text(
        'Exact and perceptual image groups reduce split leakage. They do not prove biological-plant independence. Calibration was fit on validation data; these metrics do not represent field accuracy.',
        style: TextStyle(fontSize: 12, color: muted, height: 1.6)),
    const SizedBox(height: 12),
    Text(
        'Calibrated ECE: ${(e['calibration_error'] as num).toStringAsFixed(4)} · ONNX export checked against PyTorch.',
        style: const TextStyle(fontSize: 12, color: muted))
  ];
}

Widget _metric(String value, String label) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.w700, color: ink)),
      Text(label, style: const TextStyle(color: muted, fontSize: 12))
    ]);
