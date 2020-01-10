import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void PdfViewerCreatedCallback(int id);
typedef void PdfVieverZoomLevelChangedCallback(double zoom);

class PdfViewer extends StatefulWidget {
  const PdfViewer({
    Key key,
    this.filePath,
    this.onPdfViewerCreated,
    this.onZoomLevelChanged,
  }) : super(key: key);

  final String filePath;
  final PdfViewerCreatedCallback onPdfViewerCreated;
  final PdfVieverZoomLevelChangedCallback onZoomLevelChanged;

  @override
  _PdfViewerState createState() => _PdfViewerState();
}

class ZoomLevel {
  ZoomLevel(int id) {
    _eventChannel = new EventChannel('pdf_viewer_plugin_zoom_$id');
  }

  EventChannel _eventChannel;

  Stream<double> _onZoomChanged;

  Stream<double> get onZoomChanged {
    if (_onZoomChanged == null) {
      _onZoomChanged =
          _eventChannel.receiveBroadcastStream().map((dynamic event) => event);
    }
    return _onZoomChanged;
  }
}

class _PdfViewerState extends State<PdfViewer> {
  ZoomLevel _zoom;
  StreamSubscription<double> _zoomLevelSubscription;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'pdf_viewer_plugin',
        creationParams: <String, dynamic>{
          'filePath': widget.filePath,
        },
        creationParamsCodec: StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'pdf_viewer_plugin',
        creationParams: <String, dynamic>{
          'filePath': widget.filePath,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return Text(
        '$defaultTargetPlatform is not yet supported by the pdf_viewer plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onPdfViewerCreated == null) {
      return;
    }
    widget.onPdfViewerCreated(id);
    _zoom = ZoomLevel(id);
    _zoomLevelSubscription = _zoom.onZoomChanged.listen((double zoom) {
      widget.onZoomLevelChanged(zoom);
    });
  }
}
