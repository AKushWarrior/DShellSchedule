// @Timeout(Duration(seconds: 600))

import 'package:dshell/dshell.dart' hide equals;
import 'package:dshell/src/script/entry_point.dart';
import 'package:dshell/src/util/dshell_exception.dart';
import 'package:test/test.dart';

import '../util/test_fs_zone.dart';
import '../util/test_paths.dart';

String script = 'test/test_scripts/hello_world.dart';

void main() {
  TestPaths();

  group('Cleaning using DShell', () {
    test('clean with virtual pubspec', () {
      TestZone().run(() {
        var exit = -1;
        try {
          // with a virtual pubspec
          exit = EntryPoint().process(['clean', 'example/dsort.dart']);
        } on DShellException catch (e) {
          print(e);
        }
        expect(exit, equals(0));
      });
    });

    test('clean  with a local pubspec', () {
      TestZone().run(() {
        var exit = -1;
        try {
          print(pwd);
          exit = EntryPoint().process(
              ['clean', 'test/test_scripts/local_pubspec/hello_world.dart']);
        } on DShellException catch (e) {
          print(e);
        }
        expect(exit, equals(0));
      });
    });
  });
}
