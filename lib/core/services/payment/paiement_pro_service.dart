import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaiementProService {
  static const String merchantId = 'PP-F92780';
  static const String currencyCode = '952';

  static String generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'FD-$timestamp';
  }

  static String get initHtml => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Paiement Pro</title>
  <script src="https://www.paiementpro.net/webservice/onlinepayment/js/paiementpro.v1.0.2.js"></script>
</head>
<body>
  <script>
    window.initPayment = function(merchantId, params) {
      try {
        let paiementPro = new PaiementPro(merchantId);
        
        paiementPro.amount = parseInt(params.amount);
        paiementPro.channel = params.channel;
        paiementPro.referenceNumber = params.referenceNumber;
        paiementPro.customerEmail = params.customerEmail;
        paiementPro.customerFirstName = params.customerFirstName;
        paiementPro.customerLastname = params.customerLastname;
        paiementPro.customerPhoneNumber = params.customerPhoneNumber;
        paiementPro.description = params.description;
        paiementPro.countryCurrencyCode = '952';
        paiementPro.returnURL = params.returnURL || '';
        paiementPro.notificationURL = params.notificationURL || '';

        paiementPro.getUrlPayment().then(function() {
          if (paiementPro.success) {
            PaymentChannel.postMessage(JSON.stringify({
              success: true,
              url: paiementPro.url
            }));
          } else {
            PaymentChannel.postMessage(JSON.stringify({
              success: false,
              error: paiementPro.error || 'Erreur inconnue'
            }));
          }
        }).catch(function(error) {
          PaymentChannel.postMessage(JSON.stringify({
            success: false,
            error: error.toString()
          }));
        });
      } catch (e) {
        PaymentChannel.postMessage(JSON.stringify({
          success: false,
          error: e.toString()
        }));
      }
    };
  </script>
</body>
</html>
''';
}

class PaiementProWebView extends StatefulWidget {
  final double amount;
  final String channel;
  final String referenceNumber;
  final String customerEmail;
  final String customerFirstName;
  final String customerLastName;
  final String customerPhone;
  final String description;
  final String returnURL;
  final String notificationURL;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const PaiementProWebView({
    super.key,
    required this.amount,
    required this.channel,
    required this.referenceNumber,
    required this.customerEmail,
    required this.customerFirstName,
    required this.customerLastName,
    required this.customerPhone,
    required this.description,
    this.returnURL = '',
    this.notificationURL = '',
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<PaiementProWebView> createState() => _PaiementProWebViewState();
}

class _PaiementProWebViewState extends State<PaiementProWebView> {
  late final WebViewController _controller;
  bool _paymentUrlLoaded = false;
  bool _processing = true;
  String _debugStatus = 'Initialisation...';

  /// Schemes à ouvrir dans une app externe
  static const List<String> _externalSchemes = [
    'wave:',
    'orangemoney:',
    'om:',
    'mtn:',
    'moov:',
    'whatsapp:',
    'tel:',
    'mailto:',
    'sms:',
    'intent:',
  ];

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'PaymentChannel',
        onMessageReceived: _onPaymentMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('🔵 Page started: $url');
          },
          onPageFinished: (url) {
            debugPrint('🟢 Page finished: $url');
            if (!_paymentUrlLoaded) {
              setState(() => _debugStatus = 'Appel de initPayment...');
              _callInitPayment();
            }
          },
          onWebResourceError: (error) {
            debugPrint('❌ WebView error: ${error.description}');
          },
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadHtmlString(PaiementProService.initHtml);
  }

  void _callInitPayment() {
    final params = {
      'amount': widget.amount.toInt().toString(),
      'channel': widget.channel,
      'referenceNumber': widget.referenceNumber,
      'customerEmail': widget.customerEmail,
      'customerFirstName': widget.customerFirstName,
      'customerLastname': widget.customerLastName,
      'customerPhoneNumber': widget.customerPhone,
      'description': widget.description,
      'returnURL': widget.returnURL,
      'notificationURL': widget.notificationURL,
    };

    final js = "initPayment('${PaiementProService.merchantId}', ${jsonEncode(params)})";
    debugPrint('🔵 Calling JS: $js');
    _controller.runJavaScript(js);
  }

  void _onPaymentMessage(JavaScriptMessage message) {
    debugPrint('🟢 Message from JS: ${message.message}');
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (success) {
        final paymentUrl = data['url'] as String?;
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          _paymentUrlLoaded = true;
          setState(() {
            _processing = false;
            _debugStatus = 'Redirection vers Paiement Pro...';
          });
          _controller.loadRequest(Uri.parse(paymentUrl));
        }
      } else {
        _showError(data['error'] as String? ?? 'Erreur d\'initialisation');
      }
    } catch (e) {
      _showError('Erreur JSON : $e');
    }
  }

  /// 🔥 Gère les schemes personnalisés (Wave, Orange, MTN, etc.)
  Future<NavigationDecision> _onNavigationRequest(
      NavigationRequest request) async {
    final url = request.url;
    debugPrint('🔵 Navigation: $url');

    // 1. Détecter le retour après paiement
    if (widget.returnURL.isNotEmpty && url.startsWith(widget.returnURL)) {
      final uri = Uri.parse(url);
      final responseCode = uri.queryParameters['responsecode'];

      if (responseCode == '0') {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess?.call();
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          widget.onFailure?.call();
        }
      }
      return NavigationDecision.prevent;
    }

    // 2. Détecter les schemes externes (Wave, Orange, MTN, Moov...)
    final lowerUrl = url.toLowerCase();
    for (final scheme in _externalSchemes) {
      if (lowerUrl.startsWith(scheme)) {
        debugPrint('📱 Ouverture de l\'app externe : $url');
        final uri = Uri.parse(url);
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            // Essayer avec LaunchMode.platformDefault
            await launchUrl(uri);
          }
        } catch (e) {
          debugPrint('❌ Erreur lancement : $e');
          if (mounted) {
            _showError('App non installée : ${scheme.replaceAll(':', '')}');
          }
        }
        return NavigationDecision.prevent;
      }
    }

    // 3. Gérer les URLs https:// avec User-Agent mobile pour Wave
    if (url.contains('pay.wave.com')) {
      debugPrint('🌊 Redirection Wave détectée');
      // Laisser la WebView naviguer (Wave a une version web)
      return NavigationDecision.navigate;
    }

    return NavigationDecision.navigate;
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _debugStatus = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_processing ? 'Initialisation...' : 'Paiement sécurisé'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
            widget.onFailure?.call();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_processing)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _debugStatus,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
