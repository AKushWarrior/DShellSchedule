import 'package:pubspec/pubspec.dart';

import '../../dshell.dart';
import '../functions/touch.dart';
import '../script/dependency.dart';
import '../script/my_yaml.dart';

import 'package:path/path.dart' as p;

import 'dependencies_mixin.dart';

///
/// Global dependencies is a file located in ~/.dshell/dependencies.yaml
/// that contains a 'dependencies' section from a pubsec.yaml file.abstract
///
/// The global dependencies allows a user to inject a standard set
/// of dependencies into every script.
///
///

class GlobalDependencies with DependenciesMixin {
  static const String filename = 'dependencies.yaml';
  MyYaml _yaml;

  GlobalDependencies() {
    if (!exists(path)) {
      touch(path, create: true);
    }
    _yaml = MyYaml.fromFile(path);
  }

  /// Use this ctor for unit testing.
  GlobalDependencies.fromString(String yaml) {
    _yaml = MyYaml.fromString(yaml);
  }

  /// Use this ctor for unit testing.
  /// [dependenciesYamlPath] is the path to the 'dependencies.yaml'
  /// file you have created for unit testing.
  GlobalDependencies.fromFile(String dependenciesYamlPath) {
    _yaml = MyYaml.fromFile(dependenciesYamlPath);
  }

  static String get path => p.join(Settings().dshellPath, filename);

  @override
  MyYaml get yaml => _yaml;

  /// Creates the default global dependencies
  static void createDefault() {
    if (!exists(path)) {
      path.write('dependencies:');

      for (var dep in defaultDependencies) {
        path.append(
            '  ${dep.name}: ${(dep.reference as HostedReference).versionConstraint.toString()}');
      }
    }
  }

  static List<Dependency> get defaultDependencies {
    return [
      Dependency.fromHosted('dshell', '^1.0.0'),
      Dependency.fromHosted('args', '^1.5.2'),
      Dependency.fromHosted('path', '^1.6.4'),
    ];
  }
}
