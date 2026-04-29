// lib/screens/download_helper_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadCsv(String content, String fileName) {
  final blob = html.Blob([content], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement()
    ..href = url
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void openHtmlInNewTab(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}