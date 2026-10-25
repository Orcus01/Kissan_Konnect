import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const ink = Color(0xFF173B2B);
const muted = Color(0xFF5E6D61);

Widget sectionLabel(String text) => Text(text.toUpperCase(),
    style: const TextStyle(
        color: muted,
        fontSize: 12,
        letterSpacing: 1.7,
        fontWeight: FontWeight.w700));

Widget workspaceBody(List<Widget> children, {double width = 1000}) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
            children: children,
          )),
    );

Widget pageTitle(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(color: ink, fontWeight: FontWeight.w700)),
    );

Widget errorNotice(String message, VoidCallback retry) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message, style: const TextStyle(color: Color(0xFF9F392E))),
        TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry')),
      ]),
    );

String candidateTitle(Map<String, dynamic> result) {
  if (result['status'] == 'crop_mismatch') return 'Crop does not match';
  if (result['status'] == 'uncertain') return 'Ambiguous model match';
  final top = (result['candidates'] as List).first as Map;
  return '${top['crop']} · ${top['condition']}';
}

String resultReport(Map<String, dynamic> result, String notes) {
  final rows = (result['candidates'] as List)
      .map((p) =>
          '${p['crop']} / ${p['condition']}: ${((p['score'] as num) * 100).toStringAsFixed(1)}% model score')
      .join('\n');
  return 'Kissan Konnect — unverified leaf screening\nDate: ${result['created_at']}\nSelected crop: ${result['selected_crop']}\nStatus: ${result['status']}\nDataset demonstration: ${result['dataset_sample'] == true}\n$rows\nModel: ${result['model_name']}\nVersion: ${result['model_version']}\nSource: ${result['model_source']}\nNotes: $notes\nNot a confirmed diagnosis. Model scores are not diagnostic probabilities. Field performance has not been independently validated.';
}

Future<void> copyReport(
    BuildContext context, Map<String, dynamic> result, String notes) async {
  await Clipboard.setData(ClipboardData(text: resultReport(result, notes)));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Screening report copied')));
  }
}

class CandidateList extends StatelessWidget {
  final Map<String, dynamic> result;
  const CandidateList({super.key, required this.result});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionLabel('Top model matches'),
        const SizedBox(height: 18),
        ...(result['candidates'] as List).map((candidate) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                              '${candidate['crop']} · ${candidate['condition']}')),
                      Text(
                          '${((candidate['score'] as num) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w700))
                    ]),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: (candidate['score'] as num).toDouble(),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4),
                        color: ink,
                        backgroundColor: const Color(0xFFE2E6DC)),
                  ]),
            )),
        const Text(
            'Scores compare the 15 trained classes. They are not the probability that your plant has a disease.',
            style: TextStyle(color: muted, fontSize: 13)),
      ]);
}
