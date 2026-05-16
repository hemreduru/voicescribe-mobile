import 'package:talker_flutter/talker_flutter.dart';

final talker = TalkerFlutter.init(
  settings: TalkerSettings(),
  logger: TalkerLogger(settings: TalkerLoggerSettings()),
);

class AppLogger {
  static void info(
    dynamic message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    talker.info(message, exception, stackTrace);
  }

  static void warning(
    dynamic message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    talker.warning(message, exception, stackTrace);
  }

  static void error(
    dynamic message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    talker.error(message, exception, stackTrace);
  }

  static void debug(
    dynamic message, [
    Object? exception,
    StackTrace? stackTrace,
  ]) {
    talker.debug(message, exception, stackTrace);
  }
}
