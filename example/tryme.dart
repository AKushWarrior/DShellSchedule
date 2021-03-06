#! /usr/bin/env dshell
import 'package:dshell/dshell.dart';

void main() {
  echo('Hello World');
  echo('Where are we: ${pwd}?');

  var dir = 'test';
  createDir(dir);
  touch(join(dir, 'icon.png'));
  touch(join(dir, 'logo.png'));
  touch(join(dir, 'dog.png'));

  // print all the file names in the current directory.
  fileList.forEach((file) => print('Found: ${file}'));

  touch(join(dir, 'subdir', 'monkey.png'));

  // do a recursive find
  find('*.png').forEach((file) => print('$file'));

  // now cleanup
  delete(join(dir, 'icon.png'));
  delete(join(dir, 'logo.png'));
  delete(join(dir, 'dog.png'));

  'grep touch tryme.dart'.forEach((line) => print('Found: $line'));
}
