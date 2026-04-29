// lib/screens/download_helper_stub.dart
// No-op stubs for non-web platforms (Android, iOS).
// On mobile, CSV export is a no-op; consider adding share_plus for real sharing.

void downloadCsv(String content, String fileName) {
  // Not supported on this platform.
}

void openHtmlInNewTab(String htmlContent) {
  // Not supported on this platform.
}