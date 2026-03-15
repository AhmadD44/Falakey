import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}
// void _removeSplash() async {
//   await Future.delayed(const Duration(seconds: 2)); // Optional extra wait
//   FlutterNativeSplash.remove(); // This finally hides the splash
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyWebView(),
    );
  }
}

class MyWebView extends StatefulWidget {
  const MyWebView({super.key});

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late final WebViewController controller;
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();

    // _removeSplash();

    Future.delayed(const Duration(seconds: 3), () {
    FlutterNativeSplash.remove(); 
  });

    SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.resumed.toString()) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    return null;
  });

    // ✅ Check initial connection
    _checkInitialConnection();

    // ✅ Initialize WebView controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
      )
      ..setNavigationDelegate(
  NavigationDelegate(
    onNavigationRequest: (request) async {
      final url = request.url;

      final InAppBrowser browser = InAppBrowser();

// 2. Inside your NavigationDelegate
if (url.contains("accounts.google.com")) {
  await browser.openUrlRequest(
    urlRequest: URLRequest(url: WebUri(url)),
    settings: InAppBrowserClassSettings(
      browserSettings: InAppBrowserSettings(
        hideToolbarTop: true,      // 👈 THIS HIDES THE TOP BAR COMPLETELY
        hideUrlBar: true,         // 👈 THIS HIDES THE ADDRESS BAR
        hideProgressBar: false,   // Show a tiny progress bar if you want
      ),
      webViewSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        supportZoom: false,
        // Make sure it doesn't look like a "WebView" to Google
        userAgent: "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
      ),
    ),
  );
  return NavigationDecision.prevent;
}

      return NavigationDecision.navigate;
    },

    // keep your error handler
    onWebResourceError: (error) {
      final isConnectionError = error.description.contains('net::ERR_INTERNET_DISCONNECTED') ||
                            error.description.contains('net::ERR_CONNECTION_REFUSED') ||
                            error.description.contains('net::ERR_ADDRESS_UNREACHABLE') ||
                            error.description.contains('net::ERR_NAME_NOT_RESOLVED');

  if (isConnectionError) {
    setState(() => _isConnected = false);
  }
    },
  ),
)
      ..loadRequest(Uri.parse('https://falakey.com'));

    // ✅ Listen to connectivity changes
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (result.contains(ConnectivityResult.none)) {
        setState(() => _isConnected = false);
      } else {
        if (!_isConnected) {
          setState(() => _isConnected = true);
          controller.reload();
        }
      }
    });
  }

  // ✅ Check connection when app starts
  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      setState(() => _isConnected = false);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        if (await controller.canGoBack()) {
          await controller.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ✅ Keep WebView mounted always
            WebViewWidget(controller: controller),

            // ✅ Beautiful offline overlay
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: !_isConnected
                  ? Container(
                      key: const ValueKey("offline"),
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/no-internet.json',
                              width: 220,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "No Connection. Waiting to reconnect...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
