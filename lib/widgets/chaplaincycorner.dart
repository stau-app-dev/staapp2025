import 'package:flutter/material.dart';
import 'package:staapp2025/models/verseofday.dart';
import 'package:staapp2025/theme/styles.dart';
import 'package:staapp2025/widgets/reusable/basic_container.dart';

class ChaplaincyCorner extends StatelessWidget {
  final VerseOfDay? verseOfDay;

  const ChaplaincyCorner({super.key, this.verseOfDay});

  Widget buildVerseOfDay(BuildContext context, VerseOfDay verseOfDay) {
    return Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: BoxDecoration(
            color: Styles.white,
            border: Border.all(
              color: Styles.primary,
              width: 1.0,
            ),
            borderRadius: Styles.mainBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Verse of The Day',
                style: Theme.of(context).textTheme.titleSmall),
            Text(verseOfDay.verseOfDay),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BasicContainer(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chaplaincy Corner',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20.0),
        verseOfDay != null
            ? buildVerseOfDay(context, verseOfDay!)
            : const Text('Loading...'),
      ],
    ));
  }
}
