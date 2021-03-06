import 'package:dshell/src/script/entry_point.dart';

void main(List<String> arguments) {
  DShellInstall().run(arguments);
}

class DShellInstall {
  void run(List<String> arguments) {
    List<String> mutableArgs = [];
    mutableArgs.addAll(arguments);

    if (!mutableArgs.contains('doctor')) {
      // We add the 'install' so we do the install
      // by default.
      // Unless the passed doctor.
      // we do an add so they can still pass global
      // switches such as -v
      mutableArgs.add('install');
    }
    EntryPoint().process(mutableArgs);
  }
}
