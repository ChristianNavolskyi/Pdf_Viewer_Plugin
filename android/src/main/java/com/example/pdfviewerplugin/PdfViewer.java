package com.example.pdfviewerplugin;


import android.content.Context;
import android.view.View;

import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.listener.OnZoomChangeListener;

import java.io.File;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformView;

public class PdfViewer implements PlatformView, MethodCallHandler, EventChannel.StreamHandler, OnZoomChangeListener {
    private PDFView pdfView;
    private String filePath;
    private EventChannel.EventSink eventSink;

    PdfViewer(Context context, BinaryMessenger messenger, int id, Map<String, Object> args) {
        MethodChannel methodChannel = new MethodChannel(messenger, "pdf_viewer_plugin_" + id);
        methodChannel.setMethodCallHandler(this);

        EventChannel eventChannel = new EventChannel(messenger, "pdf_viewer_plugin_zoom_" + id);
        eventChannel.setStreamHandler(this);


        pdfView = new PDFView(context, null);

        if (!args.containsKey("filePath")) {
            return;
        }

        filePath = (String) args.get("filePath");
        loadPdfView();
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("getPdfViewer")) {
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    private void loadPdfView() {
        pdfView.fromFile(new File(filePath)).enableSwipe(true) // allows to block changing pages using swipe
                .swipeHorizontal(false).enableDoubletap(true).defaultPage(0).onZoom(this).load();
    }

    @Override
    public View getView() {
        return pdfView;
    }

    @Override
    public void dispose() {
    }

    @Override
    public void onZoomChanged(float zoom) {
        if (eventSink != null) {
            eventSink.success(zoom);
        }
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        eventSink.endOfStream();
        eventSink = null;
    }
}
