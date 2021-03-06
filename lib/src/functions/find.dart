import 'dart:async';
import 'dart:io';

import 'package:dshell/src/util/waitForEx.dart';

import 'function.dart';
import '../util/progress.dart';

import '../../dshell.dart';

import '../util/log.dart';

///
/// Returns the list of files in the current and child
/// directories that match the passed glob pattern.
///
/// Note: this is a limited implementation of glob.
/// See the below notes for details.
///
/// ```dart
/// find('*.jpg', recursive:true).forEach((file) => print(file));
///
/// String<List> results = find('[a-z]*.jpg', caseSensitive:true).toList();
///
/// find('*.jpg'
///   , types:[FileSystemEntityType.directory, FileSystemEntityType.file])
///     .forEach((file) => print(file));
/// ```
///
/// Valid patterns are:
///
/// [*] - matches any number of any characters including none.
///
/// [?] -  matches any single character
///
/// [[abc]] - matches any one character given in the bracket
///
/// [[a-z]] - matches one character from the range given in the bracket
///
/// [[!abc]] - matches one character that is not given in the bracket
///
/// [[!a-z]] - matches one character that is not from the range given in the bracket
///
/// If [caseSensitive] is true then a case sensitive match is performed.
/// [caseSensitive] defaults to false.
///
/// If [recursive] is true then a recursive search of all subdirectories
///    (all the way down) is performed.
/// [recursive] is true by default.
///
/// [types] allows you to specify the file types you want the find to return.
/// By default [types] limits the results to files.
///
/// [root] allows you to specify an alternate directory to seach within
/// rather than the current work directory.
///
/// [types] the list of types to search file. Defaults to file.
///   See [FileSystemEntityType].
/// [progress] a Progress to output the results to. Passing a progress will
/// allow you to process the results as the are produced rather than having
/// to wait for the call to find to complete.
/// The passed progress is also returned.

Progress find(
  String pattern, {
  bool caseSensitive = false,
  bool recursive = true,
  bool includeHidden = false,
  String root = '.',
  Progress progress,
  List<FileSystemEntityType> types = const [FileSystemEntityType.file],
}) =>
    Find().find(pattern,
        caseSensitive: caseSensitive,
        recursive: recursive,
        includeHidden: includeHidden,
        root: root,
        progress: progress,
        types: types);

class Find extends DShellFunction {
  Progress find(
    String pattern, {
    bool caseSensitive = false,
    bool recursive = true,
    String root = '.',
    Progress progress,
    List<FileSystemEntityType> types = const [FileSystemEntityType.file],
    bool includeHidden,
  }) {
    var matcher = PatternMatcher(pattern, caseSensitive);
    if (root == '.') {
      root = pwd;
    }

    Progress forEach;

    try {
      forEach = progress ?? Progress.forEach();

      if (Settings().debug_on) {
        Log.d(
            'find: pwd: ${pwd} ${absolute(root)} pattern: ${pattern} caseSensitive: ${caseSensitive} recursive: ${recursive} types: ${types} ');
      }

      var completer = Completer<void>();
      var lister = Directory(root).list(recursive: recursive);

      lister.listen((entity) {
        var type = FileSystemEntity.typeSync(entity.path);
        //  print('testing ${entity.path}');
        if (types.contains(type) &&
            matcher.match(basename(entity.path)) &&
            allowed(
              root,
              includeHidden,
              entity,
            )) {
          forEach.addToStdout(normalize(entity.path));
        }
      },
          // should also register onError
          onDone: () => completer.complete(null));

      waitForEx<void>(completer.future);
    } finally {
      forEach.close();
    }

    return forEach;
  }

  bool allowed(String root, bool includeHidden, FileSystemEntity entity) {
    return includeHidden || !isHidden(root, entity);
  }

  // check if the entity is a hidden file (.xxx) or
  // if lives in a hidden directory.
  bool isHidden(String root, FileSystemEntity entity) {
    var relativePath = relative(entity.path, from: root);

    var parts = relativePath.split(separator);

    var isHidden = false;
    for (var part in parts) {
      if (part.startsWith('.')) {
        isHidden = true;
        break;
      }
    }
    return isHidden;
  }
}

class PatternMatcher {
  String pattern;
  RegExp regEx;
  bool caseSensitive;

  PatternMatcher(this.pattern, this.caseSensitive) {
    regEx = buildRegEx();
  }

  bool match(String value) {
    return regEx.stringMatch(value) == value;
  }

  RegExp buildRegEx() {
    var regEx = '';

    for (var i = 0; i < pattern.length; i++) {
      var char = pattern[i];

      switch (char) {
        case '[':
          regEx += '[';
          break;
        case ']':
          regEx += ']';
          break;
        case '*':
          regEx += '.*';
          break;
        case '?':
          regEx += '.';
          break;
        case '-':
          regEx += '-';
          break;
        case '!':
          regEx += '^';
          break;
        case '.':
          regEx += '\\.';
          break;
        default:
          regEx += char;
          break;
      }
    }
    return RegExp(regEx, caseSensitive: caseSensitive);
  }
}
