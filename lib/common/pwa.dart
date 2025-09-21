// Cross-platform facade for PWA-related helpers. On web, uses navigator
// and display-mode media query to detect standalone (installed) mode.
// On non-web, returns safe defaults.

import 'pwa_stub.dart' if (dart.library.html) 'pwa_web.dart';

/// Extra bottom padding to apply to the BottomNavigationBar when running as
/// an installed PWA on iOS (to avoid the home indicator/task switcher).
double extraNavBarBottomPadding() => pwaExtraNavBarBottomPadding();
