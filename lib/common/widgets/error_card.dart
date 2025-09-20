import 'package:flutter/material.dart';
import 'package:staapp2025/common/styles.dart';

/// Small reusable error card used across blocks to show an error message and an optional retry button.
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorCard({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kInnerPadding),
      decoration: BoxDecoration(
        color: kErrorBackground,
        borderRadius: BorderRadius.circular(kInnerRadius),
        border: Border.all(color: kErrorBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: TextStyle(color: kErrorText)),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: kErrorText),
              label: Text('Retry', style: TextStyle(color: kErrorText)),
            ),
        ],
      ),
    );
  }
}
