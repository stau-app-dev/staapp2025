import 'package:flutter/material.dart';

// Centralized colors
// Primary/secondary colors aligned with previous app
final Color kMaroon = Color(0xFF8D1230); // previous app primary (#8D1230)
final Color kMaroonAccent = Color(0xFF8D1230);
// Secondary (gold/yellow) from previous app
final Color kGold = Color(0xFFD8AE1A); // previous app secondary (#D8AE1A)
final Color kGoldBorder = Color(0xFFB89016); // darker border for the gold
final Color kBackground = Color(0xFFF6F6F6);
final Color kWhite = Colors.white;
final Color kTransparent = Colors.transparent;

// Shadows and decorations
final List<BoxShadow> kCardShadows = [
  BoxShadow(
    color: Colors.black.withAlpha(20),
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];

final BoxDecoration kCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  boxShadow: kCardShadows,
);

// Inner card decoration for small panels inside blocks
final BoxDecoration kInnerCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(kInnerRadius),
  border: Border.fromBorderSide(BorderSide(color: kMaroon, width: 1)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withAlpha(15),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ],
);

// Layout tokens
const double kPagePadding = 16.0;
const double kBlockPadding = 20.0;
const double kInnerPadding = 12.0;

// Radii
const double kBlockRadius = 24.0;
const double kInnerRadius = 16.0;

// Elevation represented via shadow blur and alpha already defined in kCardShadows
const double kCardBlur = 10.0;

// Text styles
final TextStyle kSectionTitle = TextStyle(
  color: kMaroonAccent,
  fontWeight: FontWeight.bold,
  fontSize: 22,
);

final TextStyle kSectionTitleSmall = TextStyle(
  color: kMaroon,
  fontWeight: FontWeight.bold,
  fontSize: 20,
);

final TextStyle kAnnouncementTitle = TextStyle(
  color: kMaroonAccent,
  fontWeight: FontWeight.bold,
  fontSize: 16,
);
// Generic body text
final TextStyle kBodyText = TextStyle(fontSize: 16);

final TextStyle kAnnouncementBody = TextStyle(
  color: kMaroonAccent,
  fontSize: 15,
);

final TextStyle kVerseText = TextStyle(color: kMaroon, fontSize: 15);

// Progress and grade styles
final Color kProgressBackground = Color(
  0xFFFFF3D6,
); // light warm background matching gold tone

final TextStyle kGradeLabel = TextStyle(
  color: kMaroon,
  fontWeight: FontWeight.bold,
  fontSize: 16,
);

// Welcome banner specific tokens
final BoxDecoration kWelcomeBannerDecoration = BoxDecoration(
  color: kMaroon,
  borderRadius: BorderRadius.circular(kBlockRadius),
  border: Border.all(color: kGoldBorder, width: 2),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withAlpha(26),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ],
);

final TextStyle kWelcomeTitle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 24,
);

final TextStyle kWelcomeBody = TextStyle(color: Colors.white, fontSize: 16);

final TextStyle kWelcomeDate = TextStyle(color: Colors.white, fontSize: 14);

// Font family names (from old app)
const String fontFamilyTitles = 'Raleway';
const String fontFamilyNormal = 'SourceSansPro';

// Shadows from old app
final List<BoxShadow> headerBoxShadow = [
  const BoxShadow(
    color: Color(0xFF8D1230), // Styles.primary equivalent
    spreadRadius: 0,
    blurRadius: 5,
    offset: Offset.zero,
  ),
];

final List<BoxShadow> normalBoxShadow = [
  const BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.3),
    spreadRadius: 0,
    blurRadius: 10,
    offset: Offset(0, 2),
  ),
];

// Main radii and padding tokens from old app
const double mainBorderRadiusValue = 16.0;
const BorderRadius mainBorderRadius = BorderRadius.all(
  Radius.circular(mainBorderRadiusValue),
);

const double mainHorizontalPadding = 24.0;
const double mainVerticalPadding = 16.0;
const double mainSpacing = 20.0;
const double mainInsidePadding = 20.0;
// Additional padding sizes for normalized usage
const double kSmallPadding = 8.0;
const double kMediumPadding = 12.0;

// Background banner depth
const double backgroundBannerDepth = 0.5;

/// Basic helper to compute picture container dimensions.
/// Returns a map with keys 'width' and 'height'.
Map<String, double> pictureContainerDimensions({
  required BuildContext context,
  required double width,
  double? ratioXY,
}) {
  // If ratio is not provided, assume square (1:1)
  final double ratio = ratioXY ?? 1.0;
  // Respect available screen width
  final double maxWidth = MediaQuery.of(context).size.width;
  final double finalWidth = width <= maxWidth ? width : maxWidth;
  final double finalHeight = finalWidth / ratio;
  return {'width': finalWidth, 'height': finalHeight};
}

/// Namespaced layout tokens for easier use and discoverability.
class Spacing {
  /// Page-level padding (outermost padding around content).
  static const double page = 16.0;

  /// Padding for major blocks (cards/sections).
  static const double block = 20.0;

  /// Inner padding used inside cards.
  static const double inner = 12.0;

  /// Small helper spacing values.
  static const double tiny = 4.0;
  static const double small = 8.0;
}

class Radii {
  static const double block = 24.0;
  static const double inner = 16.0;
}

class Elevation {
  static const double cardBlur = 10.0;
  static const int cardShadowAlpha = 20;
}

// Backwards-compatible aliases
const double kPage = Spacing.page;
const double kBlock = Spacing.block;
const double kInner = Spacing.inner;

// Placeholder / small page text
final TextStyle kPlaceholderText = TextStyle(color: kMaroon, fontSize: 18);

// Button padding token
const EdgeInsets kButtonPadding = EdgeInsets.symmetric(
  horizontal: 18,
  vertical: 12,
);

// Error tokens
final Color kErrorBackground = Colors.red.shade50;
final Color kErrorBorder = Colors.red.shade200;
final Color kErrorText = Colors.red.shade700;
