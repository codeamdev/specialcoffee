import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(methodCount: 0, dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart),
);

base class RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (newValue is AsyncError) {
      _logger.e(
        '[Riverpod] ${context.provider.name ?? context.provider.runtimeType}',
        error: newValue.error,
        stackTrace: newValue.stackTrace,
      );
    }
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _logger.e(
      '[Riverpod] FAILED: ${context.provider.name ?? context.provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
