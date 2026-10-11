import 'dart:async';

class RakshakEmergencyCountdown {
  final int seconds;
  Timer? _timer;
  int remainingSeconds;

  void Function(int remaining)? onTick;
  void Function()? onExpired;

  RakshakEmergencyCountdown({
    this.seconds = 10,
    this.onTick,
    this.onExpired,
  }) : remainingSeconds = seconds;

  bool get isRunning => _timer?.isActive ?? false;

  void start() {
    cancel();

    remainingSeconds = seconds;
    onTick?.call(remainingSeconds);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        remainingSeconds--;

        if (remainingSeconds <= 0) {
          timer.cancel();
          onExpired?.call();
          return;
        }

        onTick?.call(remainingSeconds);
      },
    );
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
