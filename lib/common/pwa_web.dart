// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

// Heuristic: If display-mode is standalone and it's iOS Safari (PWA),
// provide extra bottom padding to avoid the iOS home indicator overlap.
// Values tuned conservatively; many apps use 16-24. We'll use 20.
double pwaExtraNavBarBottomPadding() {
  try {
    // Check display-mode: standalone
    final mq = html.window.matchMedia('(display-mode: standalone)');
    final isStandalone = mq.matches;

    // iOS detection (weak but adequate):
    final ua = html.window.navigator.userAgent.toLowerCase();
    final isIOS =
        ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');

    if (isStandalone && isIOS) {
      return 20; // px; roughly safe for iOS home indicator
    }
  } catch (_) {}
  return 0;
}
