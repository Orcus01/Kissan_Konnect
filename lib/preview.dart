import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'workspace/workspace_page.dart';

/// Firebase-free workspace backed by the local inference/notebook service.
void main() => runApp(const CapturePreview());

class CapturePreview extends StatelessWidget {
  const CapturePreview({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kissan Konnect',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const WorkspacePage(),
      );
}
