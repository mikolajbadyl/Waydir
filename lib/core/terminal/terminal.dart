import 'dart:io';

class TerminalSpec {
  final String id;
  final String displayName;
  final String executable;
  final List<String> Function(String directory) argsBuilder;
  final bool useWorkingDirectory;

  const TerminalSpec({
    required this.id,
    required this.displayName,
    required this.executable,
    required this.argsBuilder,
    this.useWorkingDirectory = true,
  });
}

class TerminalRegistry {
  static final List<TerminalSpec> linux = [
    TerminalSpec(
      id: 'kitty',
      displayName: 'Kitty',
      executable: 'kitty',
      argsBuilder: (_) => const [],
    ),
    TerminalSpec(
      id: 'alacritty',
      displayName: 'Alacritty',
      executable: 'alacritty',
      argsBuilder: (_) => const [],
    ),
    TerminalSpec(
      id: 'wezterm',
      displayName: 'WezTerm',
      executable: 'wezterm',
      argsBuilder: (_) => const [],
    ),
    TerminalSpec(
      id: 'foot',
      displayName: 'Foot',
      executable: 'foot',
      argsBuilder: (_) => const [],
    ),
    TerminalSpec(
      id: 'ghostty',
      displayName: 'Ghostty',
      executable: 'ghostty',
      argsBuilder: (_) => const [],
    ),
    TerminalSpec(
      id: 'ptyxis',
      displayName: 'Ptyxis',
      executable: 'ptyxis',
      argsBuilder: (d) => ['--new-window', '--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'kgx',
      displayName: 'GNOME Console',
      executable: 'kgx',
      argsBuilder: (d) => ['--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'gnome-terminal',
      displayName: 'GNOME Terminal',
      executable: 'gnome-terminal',
      argsBuilder: (d) => ['--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'konsole',
      displayName: 'Konsole',
      executable: 'konsole',
      argsBuilder: (d) => ['--workdir', d],
    ),
    TerminalSpec(
      id: 'yakuake',
      displayName: 'Yakuake',
      executable: 'yakuake',
      argsBuilder: (_) => const [],
    ),
    TerminalSpec(
      id: 'deepin-terminal',
      displayName: 'Deepin Terminal',
      executable: 'deepin-terminal',
      argsBuilder: (d) => ['--work-directory', d],
    ),
    TerminalSpec(
      id: 'xfce4-terminal',
      displayName: 'Xfce Terminal',
      executable: 'xfce4-terminal',
      argsBuilder: (d) => ['--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'mate-terminal',
      displayName: 'MATE Terminal',
      executable: 'mate-terminal',
      argsBuilder: (d) => ['--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'lxterminal',
      displayName: 'LXTerminal',
      executable: 'lxterminal',
      argsBuilder: (d) => ['--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'terminator',
      displayName: 'Terminator',
      executable: 'terminator',
      argsBuilder: (d) => ['--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'tilix',
      displayName: 'Tilix',
      executable: 'tilix',
      argsBuilder: (d) => ['--working-directory=$d'],
    ),
    TerminalSpec(
      id: 'terminology',
      displayName: 'Terminology',
      executable: 'terminology',
      argsBuilder: (d) => ['-d', d],
    ),
    TerminalSpec(
      id: 'xterm',
      displayName: 'Xterm',
      executable: 'xterm',
      argsBuilder: (_) => const [],
    ),
  ];

  static final List<TerminalSpec> macos = [
    TerminalSpec(
      id: 'iterm',
      displayName: 'iTerm',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'iTerm', d],
      useWorkingDirectory: false,
    ),
    TerminalSpec(
      id: 'warp',
      displayName: 'Warp',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Warp', d],
      useWorkingDirectory: false,
    ),
    TerminalSpec(
      id: 'alacritty',
      displayName: 'Alacritty',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Alacritty', d],
      useWorkingDirectory: false,
    ),
    TerminalSpec(
      id: 'kitty',
      displayName: 'Kitty',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'kitty', d],
      useWorkingDirectory: false,
    ),
    TerminalSpec(
      id: 'ghostty',
      displayName: 'Ghostty',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Ghostty', d],
      useWorkingDirectory: false,
    ),
    TerminalSpec(
      id: 'terminal',
      displayName: 'Terminal',
      executable: 'open',
      argsBuilder: (d) => ['-a', 'Terminal', d],
      useWorkingDirectory: false,
    ),
  ];

  static final List<TerminalSpec> windows = [
    TerminalSpec(
      id: 'wt',
      displayName: 'Windows Terminal',
      executable: 'wt',
      argsBuilder: (d) => ['-d', d],
    ),
    TerminalSpec(
      id: 'powershell',
      displayName: 'PowerShell',
      executable: 'powershell',
      argsBuilder: (d) => [
        '-NoExit',
        '-Command',
        'Set-Location -LiteralPath "$d"',
      ],
    ),
    TerminalSpec(
      id: 'cmd',
      displayName: 'Command Prompt',
      executable: 'cmd',
      argsBuilder: (d) => ['/k', 'cd', '/d', d],
    ),
  ];

  static List<TerminalSpec> all() {
    if (Platform.isLinux) return linux;
    if (Platform.isMacOS) return macos;
    if (Platform.isWindows) return windows;
    return const [];
  }

  static TerminalSpec? byId(String id) {
    for (final t in all()) {
      if (t.id == id) return t;
    }
    return null;
  }
}

class TerminalService {
  static final _detectionCache = <String, bool>{};

  static Future<bool> isAvailable(String executable) async {
    final cached = _detectionCache[executable];
    if (cached != null) return cached;
    final result = await _which(executable);
    _detectionCache[executable] = result;
    return result;
  }

  static Future<bool> _which(String executable) async {
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, [executable], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<List<TerminalSpec>> detectAvailable() async {
    final results = <TerminalSpec>[];
    for (final spec in TerminalRegistry.all()) {
      if (Platform.isMacOS) {
        results.add(spec);
        continue;
      }
      if (await isAvailable(spec.executable)) {
        results.add(spec);
      }
    }
    return results;
  }

  static Future<bool> launch(TerminalSpec spec, String directory) async {
    try {
      await Process.start(
        spec.executable,
        spec.argsBuilder(directory),
        workingDirectory: spec.useWorkingDirectory ? directory : null,
        mode: ProcessStartMode.detached,
        runInShell: Platform.isWindows,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openInDirectory(
    String directory, {
    String? preferredId,
    String? customCommand,
  }) async {
    if (preferredId == 'custom' &&
        customCommand != null &&
        customCommand.trim().isNotEmpty) {
      if (await _launchCustom(customCommand, directory)) return;
    }
    if (preferredId != null &&
        preferredId != 'auto' &&
        preferredId != 'custom') {
      final spec = TerminalRegistry.byId(preferredId);
      if (spec != null && await launch(spec, directory)) return;
    }
    for (final spec in TerminalRegistry.all()) {
      if (Platform.isLinux || Platform.isWindows) {
        if (!await isAvailable(spec.executable)) continue;
      }
      if (await launch(spec, directory)) return;
    }
  }

  static Future<bool> _launchCustom(String command, String directory) async {
    try {
      final expanded = command.replaceAll(r'{dir}', directory);
      final parts = _tokenize(expanded);
      if (parts.isEmpty) return false;
      await Process.start(
        parts.first,
        parts.sublist(1),
        workingDirectory: directory,
        mode: ProcessStartMode.detached,
        runInShell: Platform.isWindows,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buf = StringBuffer();
    String? quote;
    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      if (quote != null) {
        if (c == quote) {
          quote = null;
        } else {
          buf.write(c);
        }
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if (c == ' ' || c == '\t') {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
      } else {
        buf.write(c);
      }
    }
    if (buf.isNotEmpty) tokens.add(buf.toString());
    return tokens;
  }
}
