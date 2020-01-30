import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void PdfViewerCreatedCallback(int id);
typedef void PdfViewerZoomLevelChangedCallback(double zoom);
typedef void PdfViewerSizeChanged(Size size);

class PdfSize {
  double width, height;

  PdfSize({this.width, this.height});
}

class PdfViewer extends StatefulWidget {
  const PdfViewer({
    Key key,
    this.filePath,
    this.onPdfViewerCreated,
    this.onZoomLevelChanged,
    this.onSizeChanged,
  }) : super(key: key);

  final String filePath;
  final PdfViewerCreatedCallback onPdfViewerCreated;
  final PdfViewerZoomLevelChangedCallback onZoomLevelChanged;
  final PdfViewerSizeChanged onSizeChanged;

  @override
  _PdfViewerState createState() => _PdfViewerState();
}

class PdfSizeCodec extends MessageCodec<Size> {
  @override
  Size decodeMessage(ByteData message) {
    return new Size(message.getFloat64(0), message.getFloat64(8));
  }

  @override
  ByteData encodeMessage(Size message) {
    ByteData data = ByteData(16);

    data.setFloat64(0, message.width);
    data.setFloat64(8, message.height);

    return data;
  }
}

class PdfInformation {
  EventChannel _zoomEventChannel;
  BasicMessageChannel _sizeEventChannel;

  PdfInformation(int id) {
    _zoomEventChannel = new EventChannel('pdf_viewer_plugin_zoom_$id');
    _sizeEventChannel = new BasicMessageChannel('pdf_viewer_plugin_size_$id', new PdfSizeCodec());
  }

  Stream<double> _onZoomChanged;

  Stream<double> get onZoomChanged {
    if (_onZoomChanged == null) {
      _onZoomChanged =
          _zoomEventChannel.receiveBroadcastStream().map((dynamic event) => event);
    }
    return _onZoomChanged;
  }
}

class _PdfViewerState extends State<PdfViewer> {
  PdfInformation _pdfInformation;

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
    if (widget.onPdfViewerCreated != null) {
      widget.onPdfViewerCreated(id);
    }

    _pdfInformation = PdfInformation(id);

    if (widget.onZoomLevelChanged != null) {
      _pdfInformation.onZoomChanged.listen((double zoom) {
        widget.onZoomLevelChanged(zoom);
      });
    }

    if (widget.onSizeChanged != null) {
      _pdfInformation._sizeEventChannel.setMessageHandler((dynamic obj) {
        Size size = obj as Size;

        widget.onSizeChanged(size);

        return null;
      });
    }
  }
}
