import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staapp2025/styles.dart';
import 'package:provider/provider.dart';
import 'package:staapp2025/auth.dart';
import 'package:staapp2025/services/home_service.dart';

class WelcomeBlock extends StatefulWidget {
  const WelcomeBlock({super.key});

  @override
  State<WelcomeBlock> createState() => _WelcomeBlockState();
}

class _WelcomeBlockState extends State<WelcomeBlock> {
  int? dayNumber;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDayNumber();
  }

  Future<void> _fetchDayNumber() async {
    try {
      final dn = await fetchDayNumber();
      setState(() {
        dayNumber = dn;
        loading = false;
      });
    } catch (e) {
      // ignore, fallback below
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy').format(today);
    return Container(
      decoration: kWelcomeBannerDecoration,
      padding: EdgeInsets.all(kBlockPadding),
      child: LayoutBuilder(
        builder: (context, outerConstraints) {
          // We'll let the left column take remaining space (Expanded) and
          // size the logo as a fraction of the overall available width.
          // This keeps the logo responsive while letting text measurement
          // logic decide whether to shorten the welcome line.
          final avail = outerConstraints.maxWidth;
          // Choose a reasonable fraction and clamp it so logo isn't tiny or huge.
          final logoSize = (avail * 0.18).clamp(80.0, 140.0);

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final auth = Provider.of<AuthService>(context);
                        final displayName = auth.user?.displayName;
                        String? firstName;
                        if (displayName != null &&
                            displayName.trim().isNotEmpty) {
                          final parts = displayName.trim().split(
                            RegExp(r"\s+"),
                          );
                          if (parts.isNotEmpty &&
                              parts.first.trim().isNotEmpty) {
                            firstName = parts.first.trim();
                          }
                        }

                        return Text(
                          firstName != null
                              ? 'Welcome $firstName to St.\u00A0Augustine'
                              : 'Welcome to St.\u00A0Augustine',
                          style: kWelcomeTitle,
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (loading) ...[
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kWhite,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final dn = '${dayNumber ?? '?'}';
                              final full = 'Today is a beautiful day $dn';
                              final short = 'Today is day $dn';
                              final style = kWelcomeBody;
                              final textDirection = Directionality.of(context);

                              // Measure full string to see if it fits on one line
                              final tp = TextPainter(
                                text: TextSpan(text: full, style: style),
                                maxLines: 1,
                                textDirection: textDirection,
                              )..layout(maxWidth: constraints.maxWidth);

                              final fits =
                                  !tp.didExceedMaxLines &&
                                  tp.width <= constraints.maxWidth;
                              final display = fits ? full : short;

                              return Text(
                                display,
                                style: style,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(formattedDate, style: kWelcomeDate),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.all(kSmallPadding),
                child: Image.asset(
                  'assets/logos/sta_logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.school,
                    size: (logoSize * 0.66),
                    color: kMaroonAccent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
