import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/workspace_api.dart';
import 'common.dart';

class AssistantPage extends StatefulWidget {
  final WorkspaceApi? api;
  final bool embedded;
  final String? crop;
  final String? initialQuestion;
  const AssistantPage(
      {super.key,
      this.api,
      this.embedded = true,
      this.crop,
      this.initialQuestion});
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true, _busy = false;
  String? _error, _failedQuestion;
  WorkspaceApi get api => widget.api ?? workspaceApi;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _load() async {
    try {
      final messages = await api.messages();
      if (mounted) setState(() => _messages = messages);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted && widget.initialQuestion != null) {
      await _send(widget.initialQuestion!);
    }
    _bottom();
  }

  Future<void> _send([String? question]) async {
    final text = (question ?? _draft.text).trim();
    if (_busy || text.length < 2) return;
    if (text.length > 2000) {
      setState(() => _error = 'Keep your question under 2,000 characters.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _failedQuestion = null;
      _messages.add({'role': 'user', 'content': text});
      _draft.clear();
    });
    _bottom();
    try {
      final reply = await api.ask(text, crop: widget.crop);
      if (mounted) {
        setState(() => _messages.add(
            {'role': 'assistant', 'content': reply['answer'], 'reply': reply}));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _failedQuestion = text;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _bottom();
    }
  }

  Future<void> _clear() async {
    final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Clear this conversation?'),
                content: const Text(
                    'This removes your saved messages from this account.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep conversation')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear messages'))
                ]));
    if (clear != true || !mounted) return;
    try {
      await api.clearChat();
      if (mounted) setState(() => _messages = []);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          sectionLabel('Plant assistant'),
                          const SizedBox(height: 6),
                          Text('A little knowledge goes a long way.',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700, color: ink)),
                          const SizedBox(height: 4),
                          const Text(
                              'Fresh answers from a local AI model, with relevant source references.',
                              style: TextStyle(color: muted, fontSize: 13))
                        ])),
                    IconButton(
                        tooltip: 'Clear conversation',
                        onPressed: _busy || _messages.isEmpty ? null : _clear,
                        icon: const Icon(Icons.delete_sweep_outlined))
                  ])),
              const Divider(height: 1),
              Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                          ? _welcome()
                          : ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 24),
                              itemCount: _messages.length + (_busy ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length) {
                                  return const Padding(
                                      padding: EdgeInsets.all(18),
                                      child: Row(children: [
                                        SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                                        SizedBox(width: 12),
                                        Text('Writing your plant care answer…',
                                            style: TextStyle(color: muted))
                                      ]));
                                }
                                return _message(_messages[index]);
                              })),
              if (_error != null)
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                      if (_failedQuestion != null)
                        TextButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    if (_messages.isNotEmpty &&
                                        _messages.last['role'] == 'user') {
                                      _messages.removeLast();
                                    }
                                    _send(_failedQuestion);
                                  },
                            child: const Text('Retry'))
                    ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                            child: TextField(
                                controller: _draft,
                                enabled: !_busy,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 2000,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: const InputDecoration(
                                    hintText: 'Ask about your plants…',
                                    counterText: ''))),
                        const SizedBox(width: 10),
                        IconButton.filled(
                            tooltip: 'Send plant question',
                            onPressed: _busy ? null : () => _send(),
                            style: IconButton.styleFrom(
                                minimumSize: const Size(52, 52),
                                backgroundColor: ink),
                            icon: const Icon(Icons.arrow_upward))
                      ])),
              const Padding(
                  padding: EdgeInsets.only(bottom: 16, left: 24, right: 24),
                  child: Text(
                      'Generated locally. AI can be wrong; check sources and expert advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 11))),
            ])));
    return widget.embedded
        ? content
        : Scaffold(
            appBar: AppBar(title: const Text('Plant assistant')),
            body: SafeArea(child: content));
  }

  Widget _welcome() => SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        const SizedBox(height: 42),
        Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
                color: Color(0xFFE2EDDA), shape: BoxShape.circle),
            child: const Icon(Icons.spa_outlined, color: ink, size: 38)),
        const SizedBox(height: 24),
        const Text('What’s growing on your mind?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -.7)),
        const SizedBox(height: 12),
        const SizedBox(
            width: 500,
            child: Text(
                'Ask about sunlight, soil, watering or what to record when a plant looks unwell. Follow-up questions keep the plant in context.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.6))),
        const SizedBox(height: 28),
        Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              'How should I water tomatoes?',
              'Tell me about growing basil',
              'What soil does potato need?',
              'My pepper leaves have spots'
            ]
                .map((q) =>
                    ActionChip(label: Text(q), onPressed: () => _send(q)))
                .toList()),
        const SizedBox(height: 32),
        const Text(
            'Ask about crops, garden plants or houseplants. Chat coverage is separate from the photo classifier.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: muted))
      ]));
  Widget _message(Map<String, dynamic> message) {
    final mine = message['role'] == 'user';
    final reply = message['reply'] as Map?;
    if (mine) {
      return Align(
          alignment: Alignment.centerRight,
          child: Container(
              constraints: const BoxConstraints(maxWidth: 640),
              margin: const EdgeInsets.only(left: 40, bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  color: const Color(0xFFE3EEDB),
                  borderRadius: BorderRadius.circular(18)),
              child: SelectableText(message['content'])));
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CircleAvatar(
              radius: 17,
              backgroundColor: ink,
              child: Icon(Icons.spa_outlined, size: 18, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Plant assistant',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 6),
                if (reply?['generative'] == true)
                  Text(
                      reply?['grounded'] == true
                          ? 'AI-generated · reference links supplied'
                          : 'AI-generated · general guidance, no source cited',
                      style: const TextStyle(fontSize: 11, color: muted)),
                const SizedBox(height: 10),
                MarkdownBody(
                    data: message['content'],
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                            height: 1.7, fontSize: 15, color: ink)),
                    onTapLink: (_, href, __) {
                      final links = (reply?['sources'] as List? ?? [])
                          .map((s) => s['url']);
                      if (href != null && links.contains(href)) {
                        launchUrl(Uri.parse(href),
                            mode: LaunchMode.externalApplication);
                      }
                    }),
                if (reply?['sources'] is List) ...[
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      children: (reply!['sources'] as List)
                          .map((source) => TextButton.icon(
                              onPressed: () => launchUrl(
                                  Uri.parse(source['url']),
                                  mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: Text(
                                  source['citation_id'] == null
                                      ? source['title']
                                      : '[${source['citation_id']}] ${source['title']}',
                                  style: const TextStyle(fontSize: 12))))
                          .toList())
                ],
                if (reply?['suggestions'] is List) ...[
                  const SizedBox(height: 10),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (reply!['suggestions'] as List)
                          .take(2)
                          .map((question) => ActionChip(
                              label: Text(question,
                                  style: const TextStyle(fontSize: 12)),
                              onPressed: _busy ? null : () => _send(question)))
                          .toList())
                ]
              ]))
        ]));
  }
}
