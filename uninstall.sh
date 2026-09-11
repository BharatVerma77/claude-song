#!/bin/bash
# Removes claude-song: hooks, command, and ~/.claude/claude-song (including your songs folder).
set -uo pipefail
APP="$HOME/.claude/claude-song"
SETTINGS="$HOME/.claude/settings.json"
"$APP/bin/claude-song" stop >/dev/null 2>&1 || true
if [ -f "$SETTINGS" ]; then
  osascript -l JavaScript - "$SETTINGS" >/dev/null <<'JXA'
function run(argv) {
  ObjC.import('Foundation');
  var path = argv[0];
  var text = ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null)) || '{}';
  var s = JSON.parse(text);
  if (s.hooks) {
    for (var ev in s.hooks) {
      s.hooks[ev] = s.hooks[ev].filter(function (g) { return JSON.stringify(g).indexOf('claude-song') === -1; });
      if (s.hooks[ev].length === 0) delete s.hooks[ev];
    }
    if (Object.keys(s.hooks).length === 0) delete s.hooks;
  }
  var out = JSON.stringify(s, null, 2) + '\n';
  $.NSString.alloc.initWithUTF8String(out).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
  return 'ok';
}
JXA
  echo "Hooks removed from $SETTINGS"
fi
rm -f "$HOME/.local/bin/claude-song"
rm -rf "$APP"
echo "claude-song uninstalled. (The PATH line in ~/.zshrc, if any, was left alone.)"
