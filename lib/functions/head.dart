import 'package:dshell/functions/function.dart';
import 'package:dshell/util/file_sync.dart';
import 'package:dshell/util/progress.dart';

import '../util/log.dart';

import 'is.dart';
import 'settings.dart';

///
/// Returns count [lines] from the file at [path].
///
/// ```dart
/// head("/var/log/syslog", 10).forEach((line) => print(line));
/// ```
///
/// Throws a [HeadException] exception if [path] is not a file.
///
Progress head(String path, int lines) => Head().head(path, lines);

class Head extends DShellFunction {
  Progress head(String path, int lines, {Progress progress}) {
    if (Settings().debug_on) {
      Log.d("head ${absolute(path)} lines: ${lines}");
    }

    if (!exists(path)) {
      throw HeadException("The path ${absolute(path)} does not exist.");
    }

    if (!isFile(path)) {
      throw HeadException("The path ${absolute(path)} is not a file.");
    }

    Progress forEach;

    try {
      forEach = progress ?? Progress.forEach();
      int count = 0;
      FileSync file = FileSync(path);
      file.read((line) {
        forEach.addToStdout(line);
        count++;
        if (count >= lines) {
          return false;
        }
        return true;
      });
    } catch (e) {
      throw HeadException(
          "An error occured reading ${absolute(path)}. Error: $e");
    } finally {
      forEach.close();
    }

    return forEach;
  }
}

class HeadException extends FunctionException {
  HeadException(String reason) : super(reason);
}