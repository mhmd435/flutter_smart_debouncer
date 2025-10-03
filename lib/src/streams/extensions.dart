import 'dart:async';

extension SmartDebounceStream<T> on Stream<T> {
  /// Emits events from this stream only after the source has been silent for
  /// [duration].
  Stream<T> debounceTime(Duration duration) {
    assert(!duration.isNegative, 'duration must be >= 0');
    final source = this;
    StreamSubscription<T>? subscription;
    Timer? timer;
    T? latest;
    var hasLatest = false;

    void emit(StreamController<T> controller) {
      if (hasLatest) {
        controller.add(latest as T);
        hasLatest = false;
        latest = null;
      }
    }

    late final StreamController<T> controller;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = source.listen(
          (event) {
            timer?.cancel();
            latest = event;
            hasLatest = true;
            timer = Timer(duration, () => emit(controller));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            emit(controller);
            controller.close();
          },
          cancelOnError: false,
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }

  /// Emits at most one value per [duration], honoring the [leading] and
  /// [trailing] edge configuration.
  Stream<T> throttleTime(Duration duration, {bool leading = true, bool trailing = true}) {
    assert(!duration.isNegative, 'duration must be >= 0');
    assert(leading || trailing, 'Either leading or trailing must be enabled');
    final source = this;

    StreamSubscription<T>? subscription;
    Timer? timer;
    T? trailingValue;
    var hasTrailingValue = false;
    var windowOpen = false;

    void openWindow(StreamController<T> controller) {
      windowOpen = true;
      timer = Timer(duration, () {
        timer = null;
        windowOpen = false;
        if (trailing && hasTrailingValue) {
          controller.add(trailingValue as T);
          hasTrailingValue = false;
          trailingValue = null;
          openWindow(controller);
        }
      });
    }

    late final StreamController<T> controller;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = source.listen(
          (event) {
            if (!windowOpen) {
              openWindow(controller);
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
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            if (trailing && hasTrailingValue) {
              controller.add(trailingValue as T);
            }
            controller.close();
          },
          cancelOnError: false,
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
