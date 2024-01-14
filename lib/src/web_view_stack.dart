// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewStack extends StatefulWidget {
  const WebViewStack({
    required this.controller,
    required this.cookieManager,
    super.key,
  });

  final WebViewController controller;
  final WebViewCookieManager cookieManager;

  @override
  State<WebViewStack> createState() => _WebViewStackState();
}

class _WebViewStackState extends State<WebViewStack> {
  var loadingPercentage = 0;

  Future<String> onSetCookie() async {
    await widget.controller.runJavaScript('''var date = new Date();
    date.setTime(date.getTime()+(30*24*60*60*1000));
    document.cookie = "FirstName=John; expires=" + date.toGMTString();''');
    return await widget.controller
        .runJavaScriptReturningResult('document.cookie') as String;
  }

  @override
  void initState() {
    super.initState();

    widget.controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              loadingPercentage = 0;
            });
          },
          onProgress: (progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageFinished: (url) {
            setState(() {
              loadingPercentage = 100;
            });
          },
          onNavigationRequest: (navigation) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SnackBar',
        onMessageReceived: (message) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message.message)));
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder(
            future: onSetCookie(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                log("${snapshot.data}");
              }
              return WebViewWidget(
                controller: widget.controller,
              );
            }),
        if (loadingPercentage < 100)
          LinearProgressIndicator(
            value: loadingPercentage / 100.0,
          ),
      ],
    );
  }
}
