// @Timeout(Duration(seconds: 600))

import 'package:dshell/src/script/entry_point.dart';
import 'package:dshell/src/util/dshell_exception.dart';
import 'package:test/test.dart';

import '../util/test_fs_zone.dart';
import '../util/test_paths.dart';

String script = 'test/test_scripts/hello_world.dart';

void main() {
  TestPaths();

  group('Compile using DShell', () {
    test('compile examples/dsort.dart', () {
      TestZone().run(() {
        var exit = -1;
        try {
          // setEnv('HOME', '/home/test');
          // createDir('/home/test', recursive: true);
          exit = EntryPoint().process(['compile', 'example/dsort.dart']);
        } on DShellException catch (e) {
          print(e);
        }
        expect(exit, equals(0));
      });
    });

    test('compile -nc examples/dsort.dart', () {
      TestZone().run(() {
        var exit = -1;
        try {
          // setEnv('HOME', '/home/test');
          // createDir('/home/test', recursive: true);
          exit = EntryPoint().process(['compile', '-nc', 'example/dsort.dart']);
        } on DShellException catch (e) {
          print(e);
        }
        expect(exit, equals(0));
      });
    });

    test('compile  with a local pubspec', () {
      TestZone().run(() {
        var exit = -1;
        try {
          exit = EntryPoint().process(
              ['compile', 'test/test_scripts/local_pubspec/hello_world.dart']);
        } on DShellException catch (e) {
          print(e);
        }
        expect(exit, equals(0));
      });
    });
  });
}
