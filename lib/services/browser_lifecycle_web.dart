import 'dart:async';
import 'dart:html' as html;

class BrowserLifecycle {
  static final StreamController<BrowserLifecycleEvent> _controller =
      StreamController<BrowserLifecycleEvent>.broadcast(sync: true);
  static bool _installed = false;

  static Stream<BrowserLifecycleEvent> get events {
    _install();
    return _controller.stream;
  }

  static void _install() {
    if (_installed) return;
    _installed = true;

    html.document.on['visibilitychange']?.listen((_) {
      _emit(html.document.hidden == true
          ? BrowserLifecycleEvent.hidden
          : BrowserLifecycleEvent.visible);
    });
    html.window.on['focus']?.listen((_) {
      _emit(BrowserLifecycleEvent.focused);
    });
    html.window.on['blur']?.listen((_) {
      _emit(BrowserLifecycleEvent.blurred);
    });
    html.window.on['pageshow']?.listen((_) {
      _emit(BrowserLifecycleEvent.pageShown);
    });
    html.window.on['pagehide']?.listen((_) {
      _emit(BrowserLifecycleEvent.pageHidden);
    });
  }

  static void _emit(BrowserLifecycleEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }
}

enum BrowserLifecycleEvent {
  visible,
  hidden,
  focused,
  blurred,
  pageShown,
  pageHidden,
}
