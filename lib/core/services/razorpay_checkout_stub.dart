/// Stub for non-web platforms. This will never be called since
/// mobile/desktop uses razorpay_flutter directly.
void openRazorpayWebCheckout({
  required Map<String, dynamic> options,
  required void Function(String paymentId) onSuccess,
  required void Function(int code, String description) onError,
}) {
  throw UnsupportedError('Web checkout is not available on this platform');
}
