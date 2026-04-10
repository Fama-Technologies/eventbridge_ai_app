import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CallHeaderAction extends StatelessWidget {
  final String phoneNumber;
  const CallHeaderAction({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.call),
      onPressed: () async {
        final url = 'tel:$phoneNumber';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      },
    );
  }
}
