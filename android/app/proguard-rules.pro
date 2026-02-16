-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# smart_auth (pinput dependency) - Google Play Services Credentials
-dontwarn com.google.android.gms.auth.api.credentials.**
