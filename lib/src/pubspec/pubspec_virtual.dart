import 'package:pub_semver/pub_semver.dart';

import '../script/dependency.dart';

import 'pubspec.dart';

class PubSpecVirtual implements PubSpec //with DependenciesMixin {
{
  PubSpec pubspec;

  ///
  /// Create a virtual pubspec from an existing pubspec
  /// which could have been an default pubspec,
  /// an annotation or an actual file based pubspec.yaml.
  PubSpecVirtual.fromPubSpec(PubSpec sourcePubSpec) {
    pubspec = sourcePubSpec;
  }

  @override
  set dependencies(List<Dependency> newDependencies) {
    pubspec.dependencies = newDependencies;
  }

  @override
  List<Dependency> get dependencies => pubspec.dependencies;

  @override
  String get name => pubspec.name;

  @override
  Version get version => pubspec.version;

  @override
  set version(Version version) => pubspec.version;

  @override
  void writeToFile(String path) {
    pubspec.writeToFile(path);
  }
}
