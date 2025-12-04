import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SecureViewerScreen extends StatefulWidget {
  final String url;
  final bool isImage;
  final String senderName;
  final DateTime time;

  const SecureViewerScreen({
    super.key,
    required this.url,
    required this.isImage,
    required this.senderName,
    required this.time,
  });

  @override
  State<SecureViewerScreen> createState() => _SecureViewerScreenState();
}

class _SecureViewerScreenState extends State<SecureViewerScreen> {
  @override
  void initState() {
    super.initState();

    /// Prevent screenshot & screen recording (Android only)
    const secureFlag = SystemUiMode.manual;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    });
  }

  @override
  void dispose() {
    /// Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // final correctedUrl = widget.url.replaceFirst(
    //     "/upload/",
    //     "/upload/fl_attachment:false/f_auto/"
    // );

    // print(correctedUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: Text(widget.senderName),
      ),
      body: widget.isImage
          ? PhotoView(
        imageProvider: NetworkImage(widget.url),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      )
          : SfPdfViewer.network(
        widget.url,
        headers: {"Accept": "application/pdf"},
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}
