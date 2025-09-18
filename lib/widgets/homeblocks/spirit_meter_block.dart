import 'package:flutter/material.dart';
import 'package:staapp2025/styles.dart';
import 'package:staapp2025/widgets/error_card.dart';
import 'package:staapp2025/services/home_service.dart';

class SpiritMeterBlock extends StatefulWidget {
  const SpiritMeterBlock({super.key});

  @override
  State<SpiritMeterBlock> createState() => _SpiritMeterBlockState();
}

class _SpiritMeterBlockState extends State<SpiritMeterBlock> {
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;
  Map<String, double> _spiritLevels = {
    '9': 0.0,
    '10': 0.0,
    '11': 0.0,
    '12': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchSpiritMeters();
  }

  double _clampToUnit(num? v) {
    if (v == null) return 0.0;
    final val = v.toDouble() / 100.0;
    if (val.isNaN) return 0.0;
    return val.clamp(0.0, 1.0);
  }

  Future<void> _fetchSpiritMeters() async {
    try {
      final data = await fetchSpiritMeters();
      setState(() {
        _spiritLevels = {
          '9': _clampToUnit(data['nine']),
          '10': _clampToUnit(data['ten']),
          '11': _clampToUnit(data['eleven']),
          '12': _clampToUnit(data['twelve']),
        };
        _loading = false;
        _error = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });
    await _fetchSpiritMeters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kCardDecoration,
      padding: EdgeInsets.all(kBlockPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spirit Meters', style: kSectionTitleSmall),
          SizedBox(height: 12),
          if (_loading)
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kMaroon,
                ),
              ),
            ),
          if (!_loading && _error)
            ErrorCard(
              message: _errorMessage ?? 'Failed to load spirit meters',
              onRetry: _retry,
            ),
          if (!_loading && !_error)
            ...['9', '10', '11', '12'].map((grade) {
              final value = _spiritLevels[grade] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.tiny),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: Text(grade, style: kGradeLabel)),
                    SizedBox(width: Spacing.small),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: kProgressBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(kGold),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
