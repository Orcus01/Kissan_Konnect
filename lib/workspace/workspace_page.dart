import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../page/camera_page.dart';
import '../services/workspace_api.dart';
import 'common.dart';
import 'guide_page.dart';
import 'notebook_page.dart';
import 'weather_page.dart';

class WorkspacePage extends StatefulWidget {
  final WorkspaceApi? api;
  const WorkspacePage({super.key, this.api});
  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  int _selected = 0;
  Map<String, dynamic>? _model;
  bool _checking = false;
  String? _error;
  WorkspaceApi get api => widget.api ?? workspaceApi;
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final model = await api.model();
      if (mounted) {
        setState(() {
          _model = model;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _model = null;
          _error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  void _about() {
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('About this screening model'),
              content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_model?['name'] ?? 'Local model service'),
                        const SizedBox(height: 16),
                        const Text(
                            'Runs on the local Kissan service using ONNX Runtime. Photos are not sent to a third-party AI provider. Saved records live on this service and are shared by its local clients; they are not synced to Firebase.'),
                        const SizedBox(height: 16),
                        const Text(
                            'Trained on curated PlantVillage leaf images. No independent field accuracy is claimed. The model has no reliable non-leaf or unknown-disease detector; high scores can still be wrong.'),
                        const SizedBox(height: 16),
                        const Text('Supported classes',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (_model != null)
                          ...(_model!['classes'] as List).map((c) =>
                              Text('• ${c['crop']} / ${c['condition']}')),
                        const SizedBox(height: 16),
                        if (_model != null)
                          Text(
                              'Version ${_model!['version']}\nDeclared license: ${_model!['license']}',
                              style:
                                  const TextStyle(fontSize: 12, color: muted)),
                        TextButton(
                            onPressed: () => launchUrl(
                                Uri.parse(
                                    'https://huggingface.co/imaflower/plantvillage-mobilenetv3'),
                                mode: LaunchMode.externalApplication),
                            child:
                                const Text('Open model source and model card')),
                      ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final pages = [
          CameraPage(openCameraOnLoad: false, embedded: true, api: api),
          NotebookPage(api: api, active: _selected == 1),
          const GuidePage(),
          WeatherPage(api: api)
        ];
        const icons = [
          Icons.document_scanner_outlined,
          Icons.menu_book_outlined,
          Icons.eco_outlined,
          Icons.cloud_outlined
        ];
        const labels = ['Scan', 'Notebook', 'Crop guide', 'Weather'];
        return Scaffold(
          appBar: AppBar(
              title: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.spa_outlined, color: ink),
                SizedBox(width: 12),
                Flexible(
                    child: Text('Kissan Konnect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700)))
              ]),
              actions: [
                if (constraints.maxWidth >= 600)
                  TextButton.icon(
                      onPressed: _checking ? null : _check,
                      icon: Icon(
                          _model != null
                              ? Icons.check_circle_outline
                              : Icons.sync,
                          size: 16),
                      label: Text(_checking
                          ? 'Connecting…'
                          : _model != null
                              ? 'Model ready'
                              : 'Connect service'))
                else
                  IconButton(
                      tooltip: _checking
                          ? 'Connecting…'
                          : _model != null
                              ? 'Model ready'
                              : 'Connect service',
                      onPressed: _checking ? null : _check,
                      icon: Icon(_model != null
                          ? Icons.check_circle_outline
                          : Icons.sync)),
                IconButton(
                    tooltip: 'Model details and limitations',
                    onPressed: _about,
                    icon: const Icon(Icons.info_outline)),
                const SizedBox(width: 8),
              ]),
          body: Column(children: [
            if (_error != null)
              MaterialBanner(content: Text(_error!), actions: [
                TextButton(onPressed: _check, child: const Text('Retry'))
              ]),
            Expanded(
                child: Row(children: [
              if (wide)
                NavigationRail(
                    selectedIndex: _selected,
                    onDestinationSelected: (value) => setState(() {
                          _selected = value;
                        }),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: const Color(0xFFF7F7F0),
                    destinations: List.generate(
                        labels.length,
                        (i) => NavigationRailDestination(
                            icon: Icon(icons[i]), label: Text(labels[i])))),
              if (wide) const VerticalDivider(width: 1),
              Expanded(
                  child: IndexedStack(
                      index: _selected,
                      children: List.generate(
                          pages.length,
                          (i) => TickerMode(
                              enabled: _selected == i, child: pages[i])))),
            ])),
          ]),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _selected,
                  onDestinationSelected: (value) => setState(() {
                        _selected = value;
                      }),
                  destinations: List.generate(
                      labels.length,
                      (i) => NavigationDestination(
                          icon: Icon(icons[i]), label: labels[i]))),
        );
      });
}
