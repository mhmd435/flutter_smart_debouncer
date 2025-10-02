import 'dart:async';

extension SmartDebounceStream<T> on Stream<T> {
  /// Emits events from this stream only after the source has been silent for
  /// [duration].
  Stream<T> debounceTime(Duration duration) {
    assert(!duration.isNegative, 'duration must be >= 0');
    final source = this;
    return Stream<T>.multi((controller) {
      Timer? timer;
      T? latest;
      var hasLatest = false;
      late StreamSubscription<T> subscription;

      void emit() {
        if (hasLatest) {
          controller.add(latest as T);
          hasLatest = false;
          latest = null;
        }
      }

      controller.onListen = () {
        subscription = source.listen((event) {
          timer?.cancel();
          latest = event;
          hasLatest = true;
          timer = Timer(duration, emit);
        }, onError: controller.addError, onDone: () {
          timer?.cancel();
          emit();
          controller.close();
        }, cancelOnError: false);
      };

      controller.onPause = () {
        subscription.pause();
      };

      controller.onResume = () {
        subscription.resume();
      };

      controller.onCancel = () async {
        timer?.cancel();
        await subscription.cancel();
      };
    }, isBroadcast: false);
  }

  /// Emits at most one value per [duration], honoring the [leading] and
  /// [trailing] edge configuration.
  Stream<T> throttleTime(Duration duration, {bool leading = true, bool trailing = true}) {
    assert(!duration.isNegative, 'duration must be >= 0');
    assert(leading || trailing, 'Either leading or trailing must be enabled');
    final source = this;
    return Stream<T>.multi((controller) {
      Timer? timer;
      T? trailingValue;
      var hasTrailingValue = false;
      var windowOpen = false;
      late StreamSubscription<T> subscription;

      void openWindow() {
        windowOpen = true;
        timer = Timer(duration, () {
          timer = null;
          windowOpen = false;
          if (trailing && hasTrailingValue) {
            controller.add(trailingValue as T);
            hasTrailingValue = false;
            trailingValue = null;
            openWindow();
          }
        });
      }

      controller.onListen = () {
        subscription = source.listen((event) {
          if (!windowOpen) {
            openWindow();
            if (leading) {
              controller.add(event);
            } else if (trailing) {
              trailingValue = event;
              hasTrailingValue = true;
            }
            return;
          }

          if (trailing) {
            trailingValue = event;
            hasTrailingValue = true;
          }
        }, onError: controller.addError, onDone: () {
          timer?.cancel();
          if (trailing && hasTrailingValue) {
            controller.add(trailingValue as T);
          }
          controller.close();
        }, cancelOnError: false);
      };

      controller.onPause = () {
        subscription.pause();
      };

      controller.onResume = () {
        subscription.resume();
      };

      controller.onCancel = () async {
        timer?.cancel();
        await subscription.cancel();
      };
    }, isBroadcast: false);
  }
}
