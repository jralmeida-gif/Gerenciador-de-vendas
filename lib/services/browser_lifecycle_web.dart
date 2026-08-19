import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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

    web.document.addEventListener('visibilitychange', _onVisibility.toJS);
    web.window.addEventListener('focus', _onFocus.toJS);
    web.window.addEventListener('blur', _onBlur.toJS);
    web.window.addEventListener('pageshow', _onPageShow.toJS);
    web.window.addEventListener('pagehide', _onPageHide.toJS);
    web.document.addEventListener('pointerdown', _onActivity.toJS);
    web.document.addEventListener('touchstart', _onActivity.toJS);
    web.document.addEventListener('keydown', _onActivity.toJS);
  }

  static void _onVisibility(web.Event _) {
    _emit(web.document.hidden
        ? BrowserLifecycleEvent.hidden
        : BrowserLifecycleEvent.visible);
  }

  static void _onFocus(web.Event _) {
    _emit(BrowserLifecycleEvent.focused);
  }

  static void _onBlur(web.Event _) {
    _emit(BrowserLifecycleEvent.blurred);
  }

  static void _onPageShow(web.Event _) {
    _emit(BrowserLifecycleEvent.pageShown);
  }

  static void _onPageHide(web.Event _) {
    _emit(BrowserLifecycleEvent.pageHidden);
  }

  static void _onActivity(web.Event _) {
    _emit(BrowserLifecycleEvent.activity);
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
