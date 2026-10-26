import 'package:flutter/material.dart';
import '../page/camera_page.dart';
import '../services/workspace_api.dart';
import 'account_dialog.dart';
import 'assistant_page.dart';
import 'common.dart';
import 'guide_page.dart';
import 'model_report.dart';
import 'notebook_page.dart';
import 'overview_page.dart';
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
  static const _labels = [
    'Overview',
    'Scan',
    'Notebook',
    'Plant assistant',
    'Weather',
    'Crop guide'
  ];
  static const _icons = [
    Icons.space_dashboard_outlined,
    Icons.document_scanner_outlined,
    Icons.menu_book_outlined,
    Icons.chat_bubble_outline,
    Icons.cloud_outlined,
    Icons.eco_outlined
  ];
  @override
  void initState() {
    super.initState();
    _check();
  }

  void _navigate(int value) => setState(() => _selected = value);
  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final model = await api.model();
      if (mounted) setState(() => _model = model);
    } catch (e) {
      if (mounted) {
        setState(() {
          _model = null;
          _error = '$e';
        });
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _report() => showModelReport(context, _model);
  void _account() => showDialog<void>(
      context: context, builder: (_) => AccountDialog(api: api));
  void _more() => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Weather'),
                onTap: () {
                  Navigator.pop(context);
                  _navigate(4);
                }),
            ListTile(
                leading: const Icon(Icons.eco_outlined),
                title: const Text('Crop guide'),
                onTap: () {
                  Navigator.pop(context);
                  _navigate(5);
                }),
            ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Model report'),
                onTap: () {
                  Navigator.pop(context);
                  _report();
                }),
            ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Your account'),
                onTap: () {
                  Navigator.pop(context);
                  _account();
                }),
            const SizedBox(height: 12)
          ])));
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final account = api.user.value;
        final name = account?['name'] as String? ?? 'Grower';
        final crops = (_model?['crops'] as List?)?.cast<String>() ??
            const ['Tomato', 'Potato', 'Bell pepper'];
        final pages = [
          OverviewPage(
              api: api,
              model: _model,
              active: _selected == 0,
              navigate: _navigate,
              modelReport: _report),
          CameraPage(
              openCameraOnLoad: false, embedded: true, api: api, crops: crops),
          NotebookPage(api: api, active: _selected == 2),
          AssistantPage(api: api),
          WeatherPage(api: api),
          const GuidePage()
        ];
        final workspace = Column(children: [
          Container(
              height: 76,
              padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 18),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE3E8DF)))),
              child: Row(children: [
                if (!wide) ...[
                  const Icon(Icons.spa_outlined, color: ink),
                  const SizedBox(width: 10)
                ],
                Expanded(
                    child: Text(wide ? _labels[_selected] : 'Kissan Konnect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: wide ? 22 : 19,
                            fontWeight: FontWeight.w700,
                            color: ink))),
                if (constraints.maxWidth >= 600)
                  TextButton.icon(
                      onPressed: _checking ? null : _check,
                      icon: Icon(
                          _model == null
                              ? Icons.sync
                              : Icons.check_circle_outline,
                          size: 16),
                      label: Text(_checking
                          ? 'Connecting…'
                          : _model != null
                              ? 'Model ready'
                              : 'Connect service')),
                IconButton(
                    tooltip: 'Model details and limitations',
                    onPressed: _report,
                    icon: const Icon(Icons.science_outlined, size: 21)),
                const SizedBox(width: 8),
                IconButton(
                    tooltip: 'Your account',
                    onPressed: _account,
                    icon: CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFE4EEDC),
                        child: Text(
                            name.isEmpty
                                ? 'G'
                                : name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ink,
                                fontSize: 14))))
              ])),
          if (_error != null)
            MaterialBanner(content: Text(_error!), actions: [
              TextButton(onPressed: _check, child: const Text('Retry'))
            ]),
          Expanded(
              child: IndexedStack(
                  index: _selected,
                  children: List.generate(
                      pages.length,
                      (i) => TickerMode(
                          enabled: _selected == i, child: pages[i])))),
        ]);
        return Scaffold(
            body: SafeArea(
                child: Row(children: [
              if (wide) _sidebar(name),
              Expanded(child: workspace)
            ])),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    height: 74,
                    backgroundColor: Colors.white,
                    selectedIndex: _selected < 4 ? _selected : 4,
                    onDestinationSelected: (index) {
                      if (index == 4) {
                        _more();
                      } else {
                        _navigate(index);
                      }
                    },
                    destinations: const [
                        NavigationDestination(
                            icon: Icon(Icons.space_dashboard_outlined),
                            label: 'Home'),
                        NavigationDestination(
                            icon: Icon(Icons.document_scanner_outlined),
                            label: 'Scan'),
                        NavigationDestination(
                            icon: Icon(Icons.menu_book_outlined),
                            label: 'Notebook'),
                        NavigationDestination(
                            icon: Icon(Icons.chat_bubble_outline),
                            label: 'Assistant'),
                        NavigationDestination(
                            icon: Icon(Icons.more_horiz), label: 'More')
                      ]));
      });
  Widget _sidebar(String name) => Container(
        width: 218,
        color: ink,
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 36),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.spa_outlined, color: Color(0xFFCAE3B6), size: 28),
              SizedBox(width: 12),
              Expanded(
                  child: Text('Kissan\nKonnect.',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.08,
                          letterSpacing: -.7))),
            ]),
          ),
          const Padding(
              padding: EdgeInsets.only(left: 14, bottom: 10),
              child: Text('YOUR WORKSPACE',
                  style: TextStyle(
                      color: Color(0xFF95B19D),
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700))),
          ...List.generate(_labels.length, _navItem),
          const Spacer(),
          TextButton.icon(
              onPressed: _report,
              icon: const Icon(Icons.science_outlined,
                  color: Color(0xFFCADAC8), size: 18),
              label: const Text('Inside the model',
                  style: TextStyle(color: Color(0xFFCADAC8), fontSize: 12))),
          const Divider(color: Color(0xFF3B5A47), height: 30),
          InkWell(
              onTap: _account,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(children: [
                  const CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0xFFCAE3B6),
                      child: Icon(Icons.person_outline, color: ink, size: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        const Text('Personal account',
                            style: TextStyle(
                                color: Color(0xFF9DB7A4), fontSize: 10)),
                      ])),
                  const Icon(Icons.more_horiz,
                      color: Color(0xFFBDCFBF), size: 18),
                ]),
              )),
        ]),
      );

  Widget _navItem(int index) {
    final selected = _selected == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
          button: true,
          selected: selected,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
                color: selected ? const Color(0xFFCAE3B6) : Colors.transparent,
                borderRadius: BorderRadius.circular(12)),
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _navigate(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    child: Row(children: [
                      Icon(_icons[index],
                          size: 20,
                          color: selected ? ink : const Color(0xFFD1DED2)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(_labels[index],
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? ink
                                      : const Color(0xFFD1DED2)))),
                    ]),
                  ),
                )),
          )),
    );
  }
}
