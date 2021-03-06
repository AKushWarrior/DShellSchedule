import 'package:dshell/src/script/command_line_runner.dart';
import 'package:dshell/src/util/runnable_process.dart';
import 'package:test/test.dart';

import 'test_paths.dart';

void main() {
  TestPaths();

  group('ParseCLICommand', () {
    test('empty string', () {
      var test = '';

      expect(() => ParsedCliCommand(test),
          throwsA(TypeMatcher<InvalidArguments>()));
    });
    test('a', () {
      var test = 'a';
      var parsed = ParsedCliCommand(test);

      expect(parsed.cmd, equals('a'));
      expect(parsed.args, equals(<String>[]));
    });

    test('ab', () {
      var test = 'ab';
      var parsed = ParsedCliCommand(test);

      expect(parsed.cmd, equals('ab'));
    });

    test('a b c', () {
      var test = 'a b c';
      var parsed = ParsedCliCommand(test);

      expect(parsed.cmd, equals('a'));
      expect(parsed.args, equals(['b', 'c']));
    });

    test('aa bb cc', () {
      var test = 'aa bb cc';
      var parsed = ParsedCliCommand(test);

      expect(parsed.cmd, equals('aa'));
      expect(parsed.args, equals(['bb', 'cc']));
    });

    test('a  b  c', () {
      var test = 'a  b  c';
      var parsed = ParsedCliCommand(test);

      expect(parsed.cmd, equals('a'));
      expect(parsed.args, equals(['b', 'c']));
    });

    // test(r'a  \ b  c\ 1', () {
    //   var test = r'a  \ b  c\ 1';
    //   var parsed = ParsedCliCommand(test);

    //   expect(parsed.cmd, equals('a'));
    //   expect(parsed.args, equals([r'\ b', r'c\ 1']));
    // });

    // test('a  \ b  c\ 1', () {
    //   var test = r'a  \ b  c\\ 1';
    //   var parsed = ParsedCliCommand(test);

    //   expect(parsed.cmd, equals('a'));
    //   expect(parsed.args, equals([r'\ b', r'c\\', '1']));
    // });

    test('a  "b"  "c1"', () {
      var test = 'a  "b"  "c1"';
      var parsed = ParsedCliCommand(test);

      expect(parsed.cmd, equals('a'));
      expect(parsed.args, equals([r'b', 'c1']));
    });

    test('git log --pretty=format:"%s" v1.0.45', () {
      var test = 'git log --pretty=format:"%s" v1.0.45';
      var parsed = ParsedCliCommand(test);

      expect(parsed.cmd, equals('git'));
      expect(parsed.args, equals(['log', '--pretty=format:%s', 'v1.0.45']));
    });
  });
}
