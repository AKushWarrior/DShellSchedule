import 'package:dshell/dshell.dart';
import 'package:dshell/src/script/my_yaml.dart';
import 'package:test/test.dart' as t;

import 'util/test_fs_zone.dart';
import 'util/test_paths.dart';

void main() {
  TestPaths();

  Settings().debug_on = true;

  t.test('Project Name', () {
    TestZone().run(() {
      print('$pwd');
      var yaml = MyYaml.fromFile('pubspec.yaml');
      var projectName = yaml.getValue('name');

      t.expect(projectName, t.equals('dshell'));
    });
  });
}
