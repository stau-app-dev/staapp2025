import 'package:flutter/material.dart';
import 'package:staapp2025/common/styles.dart';
import 'package:staapp2025/widgets/error_card.dart';
import 'package:staapp2025/features/home/data.dart';

class ChaplaincyBlock extends StatefulWidget {
  const ChaplaincyBlock({super.key});

  @override
  State<ChaplaincyBlock> createState() => _ChaplaincyBlockState();
}

class _ChaplaincyBlockState extends State<ChaplaincyBlock> {
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;
  String _verse =
      'What you heard from me, keep as the pattern of sound teaching, with faith and love in Christ Jesus. Guard the good deposit that was entrusted to you—guard it with the help of the Holy Spirit who lives in us.';

  @override
  void initState() {
    super.initState();
    _fetchVerse();
  }

  String _decodeHtmlEntities(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  Future<void> _fetchVerse() async {
    try {
      final v = await fetchVerseOfDay();
      setState(() {
        _verse = _decodeHtmlEntities(v ?? _verse);
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
    await _fetchVerse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kCardDecoration,
      padding: EdgeInsets.all(kBlockPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chaplaincy Corner', style: kSectionTitleSmall),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: kInnerCardDecoration,
            padding: EdgeInsets.all(kInnerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verse of The Day',
                  style: kSectionTitleSmall.copyWith(fontSize: 16),
                ),
                SizedBox(height: 8),
                if (_loading)
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kMaroon,
                    ),
                  ),
                if (!_loading && _error)
                  ErrorCard(
                    message: _errorMessage ?? 'Failed to load verse.',
                    onRetry: _retry,
                  ),
                if (!_loading && !_error) Text(_verse, style: kVerseText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
