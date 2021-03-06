import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dshell/src/functions/env.dart';
import 'package:dshell/src/script/command_line_runner.dart';
import 'package:dshell/src/util/stack_trace_impl.dart';

import 'progress.dart';
import 'waitForEx.dart';
import '../../dshell.dart';
import 'dshell_exception.dart';

typedef LineAction = void Function(String line);
typedef CancelableLineAction = bool Function(String line);

/// [printerr] provides the equivalent functionality to the
/// standard Dart print function but instead writes
/// the output to stderr rather than stdout.
///
/// CLI applications should, by convention, write error messages
/// out to stderr and expected output to stdout.
///
/// [line] the line to write to stderr.
void printerr(String line) {
  stderr.writeln(line);
  // waitForEx<dynamic>(stderr.flush());
}

class RunnableProcess {
  Future<Process> fProcess;

  final String workingDirectory;

  ParsedCliCommand parsed;

  RunnableProcess(String cmdLine, {this.workingDirectory})
      : parsed = ParsedCliCommand(cmdLine);

  RunnableProcess.fromList(String command, List<String> args,
      {this.workingDirectory})
      : parsed = ParsedCliCommand.fromParsed(command, args);

  String get cmdLine => parsed.cmd + ' ' + parsed.args.join(' ');

  /// Experiemental - DO NOT USE
  Stream<List<int>> get stream {
    // wait until the process has started
    var process = waitForEx<Process>(fProcess);
    return process.stdout;
  }

  /// Experiemental - DO NOT USE
  Sink<List<int>> get sink {
    // wait until the process has started
    var process = waitForEx<Process>(fProcess);
    return process.stdin;
  }

  void start(
      {bool runInShell = false,
      bool detached = false,
      bool waitForStart = true,
      bool terminal = false}) {
    var workdir = workingDirectory;
    workdir ??= Directory.current.path;

    assert(!(terminal == true && detached == true),
        'You cannot enable terminal and detached at the same time');

    var mode = detached ? ProcessStartMode.detached : ProcessStartMode.normal;
    if (terminal) {
      mode = ProcessStartMode.inheritStdio;
    }

    if (Settings().isVerbose) {
      Settings().verbose(
          'Starting(runInShell: $runInShell workingDir: $workingDirectory mode: $mode)');
      Settings().verbose('CommandLine: ${parsed.cmd} ${parsed.args.join(' ')}');
    }

    fProcess = Process.start(
      parsed.cmd,
      parsed.args,
      runInShell: runInShell,
      workingDirectory: workdir,
      mode: mode,
      environment: envs,
    );

    // we wait for the process to start.
    // if the start fails we get a clean exception
    // by waiting here.
    if (waitForStart) {
      _waitForStart();
    }
  }

  void _waitForStart() {
    var complete = Completer<Process>();

    fProcess.then((process) {
      complete.complete(process);
    }).catchError((Object e, StackTrace s) {
      complete.completeError(e);
    });
    waitForEx<Process>(complete.future);
  }

  /// Waits for the process to exit
  /// We use this method when we can't or don't
  /// want to process IO.
  /// The main use is when using start(terminal:true).
  /// We don't have access to any IO so we just
  /// have to wait for things to finish.
  int waitForExit() {
    var exited = Completer<int>();
    fProcess.then((process) {
      var exitCode = waitForEx<int>(process.exitCode);

      if (exitCode != 0) {
        exited.completeError(RunException(exitCode,
            'The command ${red('[$cmdLine]')} failed with exitCode: ${exitCode}'));
      } else {
        exited.complete(exitCode);
      }
    });
    return waitForEx<int>(exited.future);
  }

  void pipeTo(RunnableProcess stdin) {
    // fProcess.then((stdoutProcess) {
    //   stdin.fProcess.then<void>(
    //       (stdInProcess) => stdoutProcess.stdout.pipe(stdInProcess.stdin));

    // });

    fProcess.then((lhsProcess) {
      stdin.fProcess.then<void>((rhsProcess) {
        // lhs.stdout -> rhs.stdin
        lhsProcess.stdout.listen(rhsProcess.stdin.add);
        // lhs.stderr -> rhs.stdin
        lhsProcess.stderr.listen(rhsProcess.stdin.add).onDone(() {
          rhsProcess.stdin.close();
        });

        // wire rhs to the console, but thats not our job.
        // rhsProcess.stdout.listen(stdout.add);
        // rhsProcess.stderr.listen(stderr.add);

        // If the rhs process shutsdown before the lhs
        // process we will get a broken pipe. We
        // can safely ignore broken pipe errors (I think :).
        rhsProcess.stdin.done.catchError(
          (Object e) {
            // forget broken pipe after rhs terminates before lhs
          },
          test: (e) =>
              e is SocketException && e.osError.message == 'Broken pipe',
        );
      });
    });
  }

  // Monitors the process until it exists.
  // If a LineAction exists we call
  // line action each time the process emmits a line.
  /// The [nothrow] argument is EXPERIMENTAL
  void processUntilExit(Progress progress, {bool nothrow}) {
    var done = Completer<bool>();

    Progress forEach;

    forEach = progress ?? Progress.forEach();

    fProcess.then((process) {
      /// handle stdout stream
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        forEach.addToStdout(line);
      });

      // handle stderr stream
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        forEach.addToStderr(line);
      });
      // trap the process finishing
      process.exitCode.then((exitCode) {
        // CONSIDER: do we pass the exitCode to ForEach or just throw?
        // If the start failed we don't want to rethrow
        // as the exception will be thrown async and it will
        // escape as an unhandled exception and stop the whole script
        if (exitCode != 0 && nothrow == false) {
          done.completeError(RunException(exitCode,
              'The command ${red('[$cmdLine]')} failed with exitCode: ${exitCode}'));
        } else {
          done.complete(true);
        }
      });
    }).catchError((Object e, StackTrace s) {
      // print('caught ${e}');
      // throw e;
    }); // .whenComplete(() => print('start completed'));

    try {
      // wait for the process to finish.
      waitForEx<bool>(done.future);
    } catch (e) {
      rethrow;
    }
  }
}

/// Class to parse a OS command, contained in a string, which we need to pass
/// into the dart Process.start method as a application name and a series
/// of arguments.
class ParsedCliCommand {
  String cmd;
  var args = <String>[];

  ParsedCliCommand(String command) {
    parse(command);
  }

  ParsedCliCommand.fromParsed(this.cmd, this.args);

  void parse(String command) {
    var parts = <String>[];

    var state = ParseState.STARTING;

    // if try the next character should be escaped.
    // var escapeNext = false;

    // when we find a quote this will be storing
    // the quote char (' or ") that we are looking for.

    String matchingQuote;
    var currentPart = '';

    for (var i = 0; i < command.length; i++) {
      var char = command[i];

      switch (state) {
        case ParseState.STARTING:
          // ignore leading space.
          if (char == ' ') {
            break;
          }
          if (char == '"') {
            state = ParseState.IN_QUOTE;
            matchingQuote = '"';
            break;
          }
          if (char == "'") {
            state = ParseState.IN_QUOTE;
            matchingQuote = "'";
            break;
          }
          // if (char == '\\') {
          //   //escapeNext = true;
          // }

          currentPart += char;
          state = ParseState.IN_WORD;

          break;

        case ParseState.IN_WORD:
          if (char == ' ') // && !escapeNext)
          {
            //escapeNext = false;
            // a non-escape space means a new part.
            state = ParseState.STARTING;
            parts.add(currentPart);
            currentPart = '';
            break;
          }

          if (char == '"' || char == "'") {
            state = ParseState.IN_QUOTE;
            matchingQuote = char;
            break;
//             throw InvalidArguments(
//                 '''A command argument may not have a quote in the middle of a word.
// Command: $command
// ${' '.padRight(9 + i)}^''');
          }

          // if (char == '\\' && !escapeNext) {
          //   escapeNext = true;
          // } else {
          //   escapeNext = false;
          // }
          currentPart += char;
          break;

        case ParseState.IN_QUOTE:
          if (char == matchingQuote) {
            state = ParseState.STARTING;
            parts.add(currentPart);
            currentPart = '';
            break;
          }

          currentPart += char;
          break;
      }
    }

    if (currentPart.isNotEmpty) {
      parts.add(currentPart);
    }

    if (parts.isEmpty) {
      throw InvalidArguments('The string did not contain a command.');
    }
    cmd = parts[0];

    if (parts.length > 1) {
      args = parts.sublist(1);
    }

    if (Settings().isVerbose) {
      Settings().verbose('CWD: ${Directory.current}');
      Settings().verbose('Parsed results cmd: $cmd args: $args');
    }
  }
}

enum ParseState { STARTING, IN_QUOTE, IN_WORD }

class RunException extends DShellException {
  int exitCode;
  String reason;
  RunException(this.exitCode, this.reason, {StackTraceImpl stackTrace})
      : super(reason, stackTrace);

  @override
  RunException copyWith(StackTraceImpl stackTrace) {
    return RunException(exitCode, reason, stackTrace: stackTrace);
  }
}
