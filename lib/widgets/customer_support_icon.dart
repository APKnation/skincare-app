import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerSupportIcon extends StatelessWidget {
  final String? phone;
  final String? whatsappUrl;

  const CustomerSupportIcon({
    super.key,
    this.phone,
    this.whatsappUrl,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () async {
        final uri = Uri.parse(whatsappUrl ?? 'https://wa.me/255000000000');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open support channel')),
            );
          }
        }
      },
      heroTag: 'support',
      tooltip: 'Customer Support',
      child: const Icon(Icons.support_agent),
    );
  }
}
