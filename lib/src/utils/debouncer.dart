import 'dart:async';

/// A debouncer utility class that delays the execution of a function
/// until after a specified duration has passed since the last time it was invoked.
/// 
/// This is useful for preventing rapid-fire function calls, such as button clicks
/// or search input changes.
/// 
/// Example usage:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(milliseconds: 500));
/// 
/// void onButtonClick() {
///   debouncer.call(() {
///     performSave();
///   });
/// }
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;

  /// Creates a new Debouncer instance.
  /// 
  /// [delay] - The duration to wait before executing the action.
  ///           Defaults to 500 milliseconds.
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Calls the provided action after the delay period.
  /// If called again before the delay expires, the previous call is cancelled
  /// and a new delay period starts.
  /// 
  /// [action] - The function to execute after the delay.
  void call(Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels any pending action.
  void cancel() {
    _timer?.cancel();
  }

  /// Disposes of the debouncer and cancels any pending action.
  /// Call this when the debouncer is no longer needed to prevent memory leaks.
  void dispose() {
    _timer?.cancel();
  }
}

