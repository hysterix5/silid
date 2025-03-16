// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:ui_web' as ui;
import 'dart:html' as web;
import 'package:flutter/material.dart';

class LearningMaterialsPage extends StatefulWidget {
  const LearningMaterialsPage({super.key});

  @override
  State<LearningMaterialsPage> createState() => _LearningMaterialsPageState();
}

class _LearningMaterialsPageState extends State<LearningMaterialsPage> {
  final String url =
      'https://mfob493jyd.feishu.cn/drive/folder/fldcncxjCT7JZ0h7Tp8anSsrUwd';
  bool _isLoading = true; // State for tracking loading

  @override
  void initState() {
    super.initState();

    // Register the view type for web
    ui.platformViewRegistry.registerViewFactory(
      'webview-$url',
      (int viewId) {
        final iframe = web.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..onLoad.listen((event) {
            setState(() => _isLoading = false); // Hide loader when loaded
          })
          ..onError.listen((event) {
            setState(() => _isLoading = false); // Hide loader on error
          });
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Learning Materials")),
      body: Stack(
        children: [
          // WebView
          HtmlElementView(viewType: 'webview-$url'),

          // Loading Screen
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
