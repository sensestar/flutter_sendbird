import 'package:logger/logger.dart';

final logger = Logger(
  filter: CustomLogFilter(),
  printer: SimplePrinter(),
);

class CustomLogFilter extends LogFilter {
  final List<Level> filterLevels = [Level.verbose, Level.debug, Level.info];

  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= level.index;
  }
}
