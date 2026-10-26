import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/workspace_api.dart';
import '../workspace/common.dart';
import 'output_page.dart';

class CameraPage extends StatefulWidget {
  final bool openCameraOnLoad;
  final bool embedded;
  final WorkspaceApi? api;
  final List<String> crops;
  const CameraPage(
      {super.key,
      required this.openCameraOnLoad,
      this.embedded = false,
      this.api,
      this.crops = const ['Tomato', 'Potato', 'Bell pepper']});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _busy = false;
  String? _error;
  String _crop = 'Tomato';

  @override
  void initState() {
    super.initState();
    if (widget.openCameraOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pick(ImageSource.camera);
      });
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final photo = await ImagePicker()
          .pickImage(source: source, maxWidth: 1800, imageQuality: 85);
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        throw const WorkspaceException('Choose a photo under 8 MB.');
      }
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) =>
              OutputPage(imageBytes: bytes, crop: _crop, api: widget.api)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is WorkspaceException
              ? e.message
              : 'Could not open the photo. Check camera or photo access in device settings, then try again.';
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

  Future<void> _sample() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data =
          await rootBundle.load('assets/samples/potato_early_blight.jpg');
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => OutputPage(
              imageBytes: data.buffer.asUint8List(),
              crop: 'Potato',
              sample: true,
              api: widget.api)));
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Sample could not be loaded. Please choose a photo.';
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

  @override
  Widget build(BuildContext context) {
    final body = workspaceBody([
      sectionLabel('Plant health / leaf screening'),
      pageTitle(context, 'Scan a crop leaf.'),
      const Text(
          'Choose your crop, add a clear photo, and compare it with a local plant-health model.',
          style: TextStyle(fontSize: 17, color: muted)),
      const SizedBox(height: 28),
      LayoutBuilder(builder: (context, constraints) {
        final photo = ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(children: [
              Image.asset('assets/samples/potato_early_blight.jpg',
                  height: 340, width: double.infinity, fit: BoxFit.cover),
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                      color: const Color(0xE6173B2B),
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                          'A real leaf. A traceable model.\nSample: potato leaf from PlantVillage.',
                          style: TextStyle(color: Colors.white, height: 1.5)))),
            ]));
        final controls =
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          sectionLabel('01 / Choose your crop'),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
              initialValue: _crop,
              decoration: const InputDecoration(
                  labelText: 'Crop', border: OutlineInputBorder()),
              items: widget.crops
                  .map((crop) =>
                      DropdownMenuItem(value: crop, child: Text(crop)))
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        _crop = value!;
                      })),
          const SizedBox(height: 28),
          sectionLabel('02 / Add one leaf photo'),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Take a photo')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from photos')),
          const SizedBox(height: 12),
          TextButton.icon(
              onPressed: _busy ? null : _sample,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Try a sample leaf')),
          if (_busy) const LinearProgressIndicator(),
        ]);
        return constraints.maxWidth >= 700
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: photo),
                const SizedBox(width: 36),
                Expanded(flex: 5, child: controls)
              ])
            : Column(children: [photo, const SizedBox(height: 28), controls]);
      }),
      if (_error != null)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, constraints) {
        final tips = [
          _tip('01', 'Keep the detail',
              'One leaf, natural light, both sides if possible. Avoid blur and busy backgrounds.'),
          _tip('02', 'Know the scope',
              'Choose a supported crop. The model compares trained disease and healthy classes; unsupported problems may be missed.'),
          _tip('03', 'Keep a record',
              'Save the photo and observations. Confirm suspected problems with an agricultural adviser.'),
        ];
        return constraints.maxWidth >= 700
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tips
                    .map((tip) => Expanded(
                        child: Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: tip)))
                    .toList())
            : Column(
                children: tips
                    .map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 24), child: tip))
                    .toList());
      }),
    ]);
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Kissan Konnect')), body: body);
  }

  Widget _tip(String number, String title, String body) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionLabel(number),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: muted, height: 1.5))
      ]);
}
