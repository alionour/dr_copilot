import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'; // Import for defaultTargetPlatform

// Conditional imports for webview packages
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_windows/webview_windows.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({super.key, required this.title, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _webViewController; // For webview_flutter
  WebviewController? _webviewWindowsController; // For webview_windows
  bool _isWebviewInitialized = false;

  @override
  void initState() {
    super.initState();

    if (defaultTargetPlatform == TargetPlatform.windows) {
      _webviewWindowsController = WebviewController();
      _initWebviewWindows();
    } else {
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      _webViewController = WebViewController.fromPlatformCreationParams(params);

      _webViewController!
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              debugPrint('WebView is loading (progress: $progress%)');
            },
            onPageStarted: (String url) {
              debugPrint('Page started loading: $url');
            },
            onPageFinished: (String url) {
              debugPrint('Page finished loading: $url');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('Web resource error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        )
        ..addJavaScriptChannel(
          'Toaster',
          onMessageReceived: (JavaScriptMessage message) {
            debugPrint('SnackBar Info: ${message.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message.message)),
            );
          },
        )
        ..loadRequest(Uri.parse(widget.url));

      if (_webViewController!.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (_webViewController!.platform as AndroidWebViewController)
            .setTextZoom(100);
      }
      _isWebviewInitialized = true;
    }
  }

  Future<void> _initWebviewWindows() async {
    try {
      await _webviewWindowsController!.initialize();
      _webviewWindowsController!.url.listen((url) {
        debugPrint('Current URL: $url');
      });
      await _webviewWindowsController!.setBackgroundColor(Colors.transparent);
      await _webviewWindowsController!
          .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _webviewWindowsController!.loadUrl(widget.url);

      if (!mounted) return;
      setState(() {
        _isWebviewInitialized = true;
      });
    } on Exception catch (e) {
      debugPrint('Error initializing webview_windows: $e');
      if (!mounted) return;
      debugPrint('SnackBar Error: Error initializing webview: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing webview: $e')),
      );
    }
  }

  @override
  void dispose() {
    _webviewWindowsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(widget.url))) {
                await launchUrl(Uri.parse(widget.url));
              } else {
                if (!context.mounted) return;
                debugPrint('SnackBar Error: ${'couldNotLaunch'.tr(args: [widget.url])}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('couldNotLaunch'.tr(args: [widget.url]))),
                );
              }
            },
          ),
        ],
      ),
      body: _isWebviewInitialized
          ? (defaultTargetPlatform == TargetPlatform.windows
              ? Webview(_webviewWindowsController!)
              : WebViewWidget(controller: _webViewController!))
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
