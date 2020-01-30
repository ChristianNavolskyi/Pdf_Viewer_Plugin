package com.example.pdfviewerplugin;


import android.content.Context;
import android.view.View;

import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.listener.OnSizeChangeListener;
import com.github.barteksc.pdfviewer.listener.OnZoomChangeListener;

import java.io.File;
import java.nio.ByteBuffer;
import java.util.Map;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformView;

public class PdfViewer implements PlatformView, MethodCallHandler, OnZoomChangeListener, OnSizeChangeListener {
	private PDFView                     pdfView;
	private String                      filePath;
	private EventChannel.EventSink      zoomEventSink;
	private BasicMessageChannel<PdfSize> sizeEventSink;

	PdfViewer(Context context, BinaryMessenger messenger, int id, Map<String, Object> args) {
		MethodChannel methodChannel = new MethodChannel(messenger, "pdf_viewer_plugin_" + id);
		methodChannel.setMethodCallHandler(this);

//		new EventChannel(messenger, "pdf_viewer_plugin_zoom_" + id).setStreamHandler(new EventChannel.StreamHandler() {
//			@Override
//			public void onListen(Object arguments, EventChannel.EventSink events) {
//				zoomEventSink = events;
//			}
//
//			@Override
//			public void onCancel(Object arguments) {
//				zoomEventSink.endOfStream();
//				zoomEventSink = null;
//			}
//		});

		sizeEventSink = new BasicMessageChannel<>(messenger, "pdf_viewer_plugin_size_" + id, new MessageCodec<PdfSize>() {
			@Override
			public ByteBuffer encodeMessage(PdfSize message) {
				ByteBuffer buffer = ByteBuffer.allocate(16);

				buffer.putDouble(message.width);
				buffer.putDouble(message.height);


				return buffer;
			}

			@Override
			public PdfSize decodeMessage(ByteBuffer message) {
				return new PdfSize(message.getDouble(), message.getDouble());
			}
		});

		sizeEventSink.setMessageHandler(new BasicMessageChannel.MessageHandler<PdfSize>() {
			@Override
			public void onMessage(PdfSize message, BasicMessageChannel.Reply<PdfSize> reply) {

			}
		});


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
		if (zoomEventSink != null) {
			zoomEventSink.success(zoom);
		}

		if (sizeEventSink != null) {
			sizeEventSink.send(new PdfSize(1.0, 1.0));
		}
	}

	@Override
	public void onSizeChanged(float width, float height) {
		if (sizeEventSink != null) {
			sizeEventSink.send(new PdfSize(width, height));
		}
	}
}
