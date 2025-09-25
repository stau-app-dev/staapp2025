import 'package:flutter/material.dart';
import 'package:staapp2025/common/styles.dart';

class SongCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int upvotes;
  final VoidCallback? onUpvote;
  const SongCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.upvotes,
    this.onUpvote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onUpvote,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: onUpvote != null ? kGold : Colors.grey,
              borderRadius: BorderRadius.circular(kInnerRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward, color: kWhite, size: 12),
                const SizedBox(height: 1),
                Text(
                  '$upvotes',
                  style: kGradeLabel.copyWith(color: kWhite, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: kMediumPadding,
              horizontal: kMediumPadding,
            ),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(kInnerRadius),
              border: Border.all(color: kMaroon, width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kAnnouncementTitle.copyWith(color: kMaroon)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: kAnnouncementBody.copyWith(color: kMaroon),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
