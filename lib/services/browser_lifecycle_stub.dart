import 'dart:async';

class BrowserLifecycle {
  static Stream<BrowserLifecycleEvent> get events => const Stream<BrowserLifecycleEvent>.empty();
}

enum BrowserLifecycleEvent {
  visible,
  hidden,
  focused,
  blurred,
  pageShown,
  pageHidden,
}
