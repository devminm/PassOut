import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/account.dart';
import 'gap.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onDelete;
  const AccountCard({super.key, required this.account, this.onDelete});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    String logoUrl = extractAssetUrl(account.subdomain);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          Clipboard.setData(ClipboardData(text: await account.password()));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password copied to clipboard'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (logoUrl.isNotEmpty)
                Image.asset(
                  height: 50,
                  width: 50,
                  extractAssetUrl(account.subdomain),
                ),
              Gap.horizontal(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (account.companyName != null)
                    Column(
                      children: [
                        Text(
                          account.companyName!,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Gap.vertical(8),
                      ],
                    ),
                  Text(
                    "Username: ${account.username}",
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    "Url: ${account.subdomain.replaceAll("https://", "")}",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (onDelete != null) {
                          onDelete!();
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.deepPurple,
                      )),
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        Clipboard.setData(ClipboardData(text: await account.password()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password copied to clipboard'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.copy_outlined,
                        color: Colors.deepPurple,
                      )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String extractAssetUrl(String url) {
    if (url.contains("google")) {
      return "assets/logos/google.png";
    }
    if (url.contains("mastercard")) {
      return "assets/logos/mastercard.png";
    }
    if (url.contains("twitter")) {
      return "assets/logos/twitter.png";
    }
    if (url.contains("youtube")) {
      return "assets/logos/youtube.png";
    }
    if (url.contains("instagram")) {
      return "assets/logos/instagram.png";
    }
    if (url.contains("linkedin")) {
      return "assets/logos/linkedin.png";
    }
    if (url.contains("netflix")) {
      return "assets/logos/netflix.png";
    }
    return "";
  }
}
