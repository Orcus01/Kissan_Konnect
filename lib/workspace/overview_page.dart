import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/workspace_api.dart';
import 'common.dart';
import 'notebook_page.dart';

class OverviewPage extends StatefulWidget {
  final WorkspaceApi api;
  final Map<String, dynamic>? model;
  final bool active;
  final void Function(int) navigate;
  final VoidCallback modelReport;
  const OverviewPage(
      {super.key,
      required this.api,
      required this.navigate,
      required this.modelReport,
      this.model,
      this.active = true});
  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _scans = [];
  String? _error;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(covariant OverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results =
          await Future.wait([widget.api.stats(), widget.api.scans()]);
      final stats = results[0] as Map<String, dynamic>;
      if (stats['saved_scans'] is! num) {
        throw const WorkspaceException(
            'Personal activity could not be loaded.');
      }
      if (mounted) {
        setState(() {
          _stats = stats;
          _scans = results[1] as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.api.user.value?['name'] as String? ?? 'grower')
        .split(' ')
        .first;
    final classes = (widget.model?['classes'] as List?)?.length;
    final crops = (widget.model?['crops'] as List?)?.length;
    return RefreshIndicator(
        onRefresh: _load,
        child: workspaceBody([
          sectionLabel(DateFormat('EEEE, d MMMM').format(DateTime.now())),
          pageTitle(context, 'Hello, $name.'),
          const Text('Your saved scans and growing tools, in one place.',
              style: TextStyle(color: muted, fontSize: 16)),
          const SizedBox(height: 26),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 620;
            final text = Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LEAF SCREENING',
                          style: TextStyle(
                              color: Color(0xFFC8DEBA),
                              fontSize: 11,
                              letterSpacing: 1.7,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      const Text('Check your plant.\nKeep the bigger picture.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              letterSpacing: -.7)),
                      const SizedBox(height: 14),
                      Text(
                          classes == null
                              ? 'Choose your crop and review a clear leaf photo.'
                              : '$classes trained classes across $crops crops.\nReview a match, then record what you see.',
                          style: const TextStyle(
                              color: Color(0xFFCCDBCB), height: 1.6)),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFC8E5B7),
                              foregroundColor: ink),
                          onPressed: () => widget.navigate(1),
                          icon: const Icon(Icons.document_scanner_outlined,
                              size: 18),
                          label: const Text('Start a plant scan'))
                    ]));
            return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColoredBox(
                    color: ink,
                    child: narrow
                        ? text
                        : Row(children: [
                            Expanded(flex: 6, child: text),
                            Expanded(
                                flex: 4,
                                child: Image.asset(
                                    'assets/samples/potato_early_blight.jpg',
                                    height: 306,
                                    fit: BoxFit.cover))
                          ])));
          }),
          if (widget.model?['quality_status'] == 'experimental') ...[
            const SizedBox(height: 18),
            Text(
                'Experimental worldwide screening: ${((widget.model!['evaluation']['external']['accuracy'] as num) * 100).toStringAsFixed(1)}% on the separate source holdout. Image matches need expert review.',
                style:
                    const TextStyle(color: muted, fontSize: 13, height: 1.6)),
          ],
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
                child: _stat(_stats == null ? '—' : '${_stats!['saved_scans']}',
                    'Saved scans')),
            Expanded(
                child: _stat(
                    _stats == null
                        ? '—'
                        : '${(_stats!['crops'] as List).length}',
                    'Crops in notebook')),
            Expanded(
                child: _stat(
                    _stats?['latest_scan'] == null
                        ? '—'
                        : DateFormat('d MMM').format(
                            DateTime.parse(_stats!['latest_scan']).toLocal()),
                    'Latest record'))
          ]),
          if (_loading)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2)),
          if (_error != null) errorNotice(_error!, _load),
          const Divider(height: 52),
          LayoutBuilder(builder: (context, c) {
            final tools = [
              _tool(
                  Icons.chat_bubble_outline,
                  'Plant assistant',
                  'Ask about watering, soil, light or symptoms.',
                  () => widget.navigate(3)),
              _tool(
                  Icons.cloud_outlined,
                  'Your weather outlook',
                  'Find current conditions and a five-day forecast.',
                  () => widget.navigate(4))
            ];
            return c.maxWidth < 620
                ? Column(
                    children: [tools[0], const SizedBox(height: 14), tools[1]])
                : Row(children: [
                    Expanded(child: tools[0]),
                    const SizedBox(width: 18),
                    Expanded(child: tools[1])
                  ]);
          }),
          const SizedBox(height: 32),
          Row(children: [
            const Expanded(
                child: Text('Your recent scans',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                        color: ink))),
            TextButton(
                onPressed: () => widget.navigate(2),
                child: const Text('View notebook'))
          ]),
          if (!_loading && _error == null && _scans.isEmpty)
            Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.centerLeft,
                child: const Row(children: [
                  Icon(Icons.menu_book_outlined, color: muted, size: 30),
                  SizedBox(width: 16),
                  Expanded(
                      child: Text(
                          'Your notebook starts with a leaf.\nSave a scan and add a few observations.',
                          style: TextStyle(color: muted, height: 1.7)))
                ])),
          ..._scans.take(3).map((scan) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.api.imageUrl(scan['image_url']),
                      headers: widget.api.imageHeaders,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.eco_outlined))),
              title: Text(candidateTitle(scan['result']),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${DateFormat.yMMMd().format(DateTime.parse(scan['created_at']).toLocal())} · Unverified screening'),
              trailing: const Icon(Icons.arrow_forward, size: 20),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        NotebookDetail(scan: scan, api: widget.api)));
                if (mounted) _load();
              })),
          const Divider(height: 40),
          Row(children: [
            const Icon(Icons.science_outlined, color: muted, size: 20),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('Know what the model can—and cannot—tell you.',
                    style: TextStyle(fontSize: 13, color: muted))),
            TextButton(
                onPressed: widget.modelReport,
                child: const Text('Model report'))
          ]),
        ], width: 1060));
  }

  Widget _stat(String value, String label) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: muted))
      ]);
  Widget _tool(
          IconData icon, String title, String subtitle, VoidCallback action) =>
      Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
              onTap: action,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Icon(icon, color: ink, size: 27),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                  fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(subtitle,
                              style:
                                  const TextStyle(color: muted, fontSize: 13))
                        ])),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, size: 18, color: muted)
                  ]))));
}
