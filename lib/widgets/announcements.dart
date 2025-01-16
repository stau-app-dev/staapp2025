import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:staapp2025/theme/styles.dart';
import 'package:staapp2025/widgets/reusable/basic_container.dart';
import 'package:staapp2025/widgets/reusable/rounded_button.dart';
import 'package:staapp2025/models/announcement.dart';

/// {@template announcements_board}
/// Reusable widget for displaying a list of announcements.
/// {@endtemplate}
class AnnouncementsBoard extends StatelessWidget {
  /// The list of general announcements.
  final List<Announcement>? announcements;

  /// Function to call when the user presses the Add Announcement button.
  final Function()? onPressAddAnnouncement;

  /// Function to call when the user presses and holds to delete an announcement.
  final Function(
      {required String id,
      required String content,
      required String creatorName})? onLongPressAnnouncement;

  /// {@macro announcements_board}
  const AnnouncementsBoard(
      {super.key,
      this.announcements,
      this.onPressAddAnnouncement,
      this.onLongPressAnnouncement});

  Widget buildContent(
      {required BuildContext context,
      required String title,
      required String content}) {
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
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Linkify(
                text: content,
                linkStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Styles.secondary,
                      decoration: TextDecoration.underline,
                    ),
                onOpen: (link) async {
                  //launchURL(context: context, url: link.url);
                },
              ),
            ]));
  }

  List<Widget> buildWrapper(
      {required BuildContext context,
      required List<Announcement> data}) {
    List<Widget> rows = [const SizedBox(height: 20.0)];

    for (var announcement in data) {
      rows.add(
        buildContent(
            context: context,
            title: announcement.title,
            content: announcement.content),
      );
      rows.add(const SizedBox(height: 10.0));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    List<Announcement> data = announcements ?? [];

    if (data.isEmpty) {
      data.add(const Announcement(
          title: 'No announcements yet!',
          content: 'There are no announcements yet. Check back later!'));
    }

    return BasicContainer(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Announcements Board',
            style: Theme.of(context).textTheme.titleLarge),
        ...buildWrapper(context: context, data: data),
        if (onPressAddAnnouncement != null) ...[
          const SizedBox(height: 15.0),
          RoundedButton(
              text: 'Add Announcement', onPressed: onPressAddAnnouncement!),
        ]
      ],
    ));
  }
  

}
