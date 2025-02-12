import 'package:flutter/material.dart';
import 'package:staapp2025/models/spirit_meters.dart';
import 'package:staapp2025/theme/styles.dart';
import 'package:staapp2025/widgets/reusable/word_to_number_conversion.dart';
import 'package:staapp2025/widgets/reusable/basic_container.dart';
import 'package:staapp2025/widgets/reusable/rounded_linear_progress_indicator.dart';

class SpiritMeterBars extends StatelessWidget {
  final SpiritMeters? spiritMeters;

  const SpiritMeterBars({super.key, this.spiritMeters});

  List<Widget> buildSpiritMeters(
      BuildContext context, SpiritMeters spiritMetersData) {
    List<Widget> spiritMeters = [];
    spiritMetersData.toJson().forEach((key, value) {
      spiritMeters.add(SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 30.0,
        child: Row(children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.075,
              child: Text(
                wordToNumberConversion(key),
                style: Theme.of(context).textTheme.titleSmall,
              )),
          Expanded(
              child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: RoundedLinearProgressIndicator(
                      max: 100,
                      value: value,
                      color: Styles.secondary,
                      backgroundColor: Styles.transparent,
                      height: 7.5))),
        ]),
      ));
    });
    return spiritMeters;
  }

  @override
  Widget build(BuildContext context) {
    SpiritMeters data = spiritMeters ??
        const SpiritMeters(
          nine: 0,
          ten: 0,
          eleven: 0,
          twelve: 0,
        );

    return BasicContainer(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spirit Meter', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20.0),
        ...buildSpiritMeters(context, data),
      ],
    ));
  }
}
