import 'package:dshell/src/script/entry_point.dart';
import 'package:dshell/src/util/dshell_exception.dart';
import 'package:test/test.dart';

import '../util/test_fs_zone.dart';
import '../util/wipe.dart';

String script = 'test/test_scripts/hello_world.dart';

void main() {
  group('Compile using DShell', () {
    test('install examples/dsort.dart', () {
      TestZone().run(() {
        var exit = -1;
        try {
          // setEnv('HOME', '/home/test');
          // createDir('/home/test', recursive: true);
          wipe();
          exit = EntryPoint().process(['compile', 'example/dsort.dart']);
        } on DShellException catch (e) {
          print(e);
        }
        expect(exit, equals(0));
      });
    });
  });
}