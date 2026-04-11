import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

/// JS interop binding for the Razorpay checkout constructor exposed by
/// `https://checkout.razorpay.com/v1/checkout.js`.
@JS('Razorpay')
extension type _RazorpayJs._(JSObject _) implements JSObject {
  external _RazorpayJs(JSObject options);
  external void open();
}

/// The shape of the response object Razorpay passes to the success handler.
extension type _RazorpayResponse._(JSObject _) implements JSObject {
  @JS('razorpay_payment_id')
  external String? get razorpayPaymentId;
}

/// Opens Razorpay checkout using the JavaScript SDK (for web platform).
/// Requires <script src="https://checkout.razorpay.com/v1/checkout.js"> in index.html.
void openRazorpayWebCheckout({
  required Map<String, dynamic> options,
  required void Function(String paymentId) onSuccess,
  required void Function(int code, String description) onError,
}) {
  try {
    // Build the success handler as a JS function the Razorpay SDK can invoke.
    final JSFunction handler = ((_RazorpayResponse response) {
      String paymentId = '';
      try {
        paymentId = response.razorpayPaymentId ?? '';
        debugPrint('Razorpay Web: paymentId=$paymentId');
      } catch (e) {
        debugPrint('Razorpay Web: Error reading razorpay_payment_id: $e');
      }
      onSuccess(paymentId);
    }).toJS;

    // Build the modal dismiss handler.
    final JSFunction dismiss = (() {
      debugPrint('Razorpay Web: Checkout dismissed by user');
      onError(2, 'Payment cancelled by user');
    }).toJS;

    // Convert the plain Dart options map to a JS object, then attach the
    // function-valued properties (which jsify cannot represent on its own).
    final JSObject jsOptions = options.jsify() as JSObject;
    jsOptions.setProperty('handler'.toJS, handler);

    final JSObject modal = JSObject();
    modal.setProperty('ondismiss'.toJS, dismiss);
    jsOptions.setProperty('modal'.toJS, modal);

    // Create the Razorpay instance and open the checkout dialog.
    final rzp = _RazorpayJs(jsOptions);
    rzp.open();

    debugPrint('Razorpay Web: Checkout opened successfully');
  } catch (e) {
    debugPrint('Razorpay Web Error: $e');
    onError(0, 'Failed to open Razorpay checkout: $e');
  }
}
