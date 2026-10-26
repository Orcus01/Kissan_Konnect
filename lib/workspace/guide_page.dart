import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common.dart';

const cropGuides = [
  {
    'crop': 'Bell pepper · Tomato',
    'title': 'Bacterial spot',
    'signs':
        'Document spots on leaves, stems and fruit. Photograph both sides of a leaf and note whether nearby plants are also affected.',
    'next':
        'Record when spots appeared and any recent wet conditions. Similar symptoms can have different causes; seek local confirmation.',
    'source':
        'https://extension.umn.edu/agriculture/specialty-crops/vegetable-farming/disease-management/bacterial-spot-of-tomato-and-pepper',
  },
  {
    'crop': 'Tomato',
    'title': 'Early blight',
    'signs':
        'Photograph older leaves and any dark spots with ring-like patterns. Note whether yellowing is spreading upward.',
    'next':
        'Record which parts of the plant are affected and how quickly symptoms change. Similar-looking problems need an assessment beyond a photo.',
    'source':
        'https://extension.umn.edu/disease-management/early-blight-tomato-and-potato'
  },
  {
    'crop': 'Potato',
    'title': 'Early blight',
    'signs':
        'Document dark, ringed leaf spots, their location on the plant, and whether several plants show the same pattern.',
    'next':
        'Take an overview and a close-up. Include crop age and recent weather in your field notes.',
    'source':
        'https://extension.umn.edu/disease-management/early-blight-tomato-and-potato'
  },
  {
    'crop': 'Tomato · Potato',
    'title': 'Late blight',
    'signs':
        'Document rapidly expanding brown areas on leaves or stems. Check both sides of the leaf and note recent damp weather.',
    'next':
        'Seek prompt local advice if damage is spreading quickly. A model suggestion alone cannot establish late blight.',
    'source': 'https://extension.umn.edu/disease-management/late-blight'
  },
];

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});
  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final guides = cropGuides
        .where((guide) => '${guide['crop']} ${guide['title']} ${guide['signs']}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    return workspaceBody([
      sectionLabel('Crop reference'),
      pageTitle(context, 'Observe before you act.'),
      const Text(
          'A small, sourced observation guide. Use it to prepare better photos and field notes; local treatment advice should come from an agricultural adviser.',
          style: TextStyle(color: muted, fontSize: 16)),
      const SizedBox(height: 24),
      TextField(
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search crop, condition or symptom',
              border: OutlineInputBorder()),
          onChanged: (value) => setState(() {
                _query = value;
              })),
      const SizedBox(height: 28),
      if (guides.isEmpty)
        const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'No guide matches this search. Try tomato, potato, spots or blight.')),
      ...guides.map((guide) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 24),
                title: Text(guide['title']!,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                subtitle: Text(guide['crop']!),
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            sectionLabel('Signs to document'),
                            const SizedBox(height: 12),
                            Text(guide['signs']!),
                            const SizedBox(height: 20),
                            sectionLabel('Next step'),
                            const SizedBox(height: 12),
                            Text(guide['next']!),
                            const SizedBox(height: 12),
                            TextButton.icon(
                                onPressed: () async {
                                  final opened = await launchUrl(
                                      Uri.parse(guide['source']!),
                                      mode: LaunchMode.externalApplication);
                                  if (!opened && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Reference could not be opened. Try again.')));
                                  }
                                },
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label:
                                    const Text('Read UMN Extension reference')),
                          ]))
                ]),
            const Divider(height: 1),
          ])),
      const SizedBox(height: 36),
      sectionLabel('Every crop / field checklist'),
      const SizedBox(height: 16),
      const Text(
          '• Photograph the whole plant and one affected leaf.\n\n• Record crop variety, plant age and when symptoms began.\n\n• Note whether the issue affects one plant or a wider area.\n\n• Keep track of watering, weather and recent applications.\n\n• Compare observations over time; do not choose a pesticide from a model label.',
          style: TextStyle(height: 1.5)),
      const SizedBox(height: 28),
      const Text(
          'References are published for their stated regions. This guide does not translate regional chemical recommendations into advice for your farm.',
          style: TextStyle(color: muted, fontSize: 12)),
    ], width: 850);
  }
}
