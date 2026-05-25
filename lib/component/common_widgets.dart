import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

AppBar buildAppBar(String title, Color color) => AppBar(
  title: Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontSize: 18,
    ),
  ),
  backgroundColor: color,
  centerTitle: true,
  elevation: 0,
  iconTheme: const IconThemeData(color: Colors.white),
);

Widget buildCard({required Widget child}) => Card(
  elevation: 0,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.grey.shade200),
  ),
  child: Padding(padding: const EdgeInsets.all(16), child: child),
);

Widget buildSectionLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    t,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade700,
    ),
  ),
);

Widget buildErrorBanner(String msg) => Padding(
  padding: const EdgeInsets.only(top: 12),
  child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(fontSize: 13, color: Colors.red.shade700),
          ),
        ),
      ],
    ),
  ),
);
