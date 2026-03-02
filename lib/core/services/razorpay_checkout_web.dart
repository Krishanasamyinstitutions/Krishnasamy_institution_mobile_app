import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Opens Razorpay checkout using the JavaScript SDK (for web platform).
/// Requires <script src="https://checkout.razorpay.com/v1/checkout.js"> in index.html.
void openRazorpayWebCheckout({
  required Map<String, dynamic> options,
  required void Function(String paymentId) onSuccess,
  required void Function(int code, String description) onError,
}) {
  try {
    final fullOptions = Map<String, dynamic>.from(options);

    // Add success handler.
    // dart:js's allowInterop returns a JsFunction (JsObject subtype), which
    // JsObject.jsify passes through unchanged — so this IS called by Razorpay.
    // Use dart:js bracket notation [(response as JsObject)['key']] to read the
    // response, NOT dart:js_util.getProperty — mixing the two interop systems
    // causes property reads to silently return null.
    fullOptions['handler'] = js.allowInterop((dynamic response) {
      String paymentId = '';
      try {
        final jsResponse = response as js.JsObject;
        paymentId = jsResponse['razorpay_payment_id']?.toString() ?? '';
        debugPrint(
            'Razorpay Web: response type=${response.runtimeType}, paymentId=$paymentId');
      } catch (e) {
        debugPrint('Razorpay Web: Error reading razorpay_payment_id: $e');
      }
      debugPrint('Razorpay Web Success: paymentId=$paymentId');
      onSuccess(paymentId);
    });

    // Add modal dismiss handler.
    fullOptions['modal'] = {
      'ondismiss': js.allowInterop((dynamic reason) {
        debugPrint(
            'Razorpay Web: Checkout dismissed by user (reason: $reason)');
        onError(2, 'Payment cancelled by user');
      }),
    };

    // Convert entire options (including JsFunction values) to a JS object.
    // jsify handles JsObject/JsFunction values by passing them through as-is.
    final jsOptions = js.JsObject.jsify(fullOptions);

    // Create Razorpay instance and open checkout
    final razorpayConstructor = js.context['Razorpay'] as js.JsFunction;
    final rzp = js.JsObject(razorpayConstructor, [jsOptions]);
    rzp.callMethod('open');

    debugPrint('Razorpay Web: Checkout opened successfully');
  } catch (e) {
    debugPrint('Razorpay Web Error: $e');
    onError(0, 'Failed to open Razorpay checkout: $e');
  }
}
