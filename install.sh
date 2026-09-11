#!/bin/bash
# claude-song installer (macOS).
#   From a checkout:   ./install.sh
#   One line:          curl -fsSL https://raw.githubusercontent.com/BharatVerma77/claude-song/main/install.sh | bash
set -euo pipefail

REPO="${CLAUDE_SONG_REPO:-BharatVerma77/claude-song}"
APP="$HOME/.claude/claude-song"
SETTINGS="$HOME/.claude/settings.json"

[ "$(uname -s)" = "Darwin" ] || { echo "claude-song needs macOS (it uses afplay)."; exit 1; }

# Locate the source: next to this script, or download the repo when piped from curl.
SRC=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/bin/claude-song" ]; then
  SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  echo "Downloading $REPO ..."
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP" --strip-components=1
  SRC="$TMP"
fi

echo "Installing claude-song to $APP"
"$APP/bin/claude-song" stop >/dev/null 2>&1 || true
mkdir -p "$APP/bin" "$APP/songs" "$HOME/.claude"
cp "$SRC/bin/claude-song" "$SRC/bin/song-dialog.swift" "$SRC/bin/song-dialog.applescript" "$APP/bin/"
[ -f "$SRC/bin/song-dialog" ] && cp "$SRC/bin/song-dialog" "$APP/bin/song-dialog"
chmod +x "$APP/bin/claude-song"
cp "$SRC/uninstall.sh" "$APP/uninstall.sh" 2>/dev/null && chmod +x "$APP/uninstall.sh" || true
xattr -dr com.apple.quarantine "$APP/bin" 2>/dev/null || true
for f in "$SRC"/songs/*; do
  [ -f "$f" ] && [ ! -e "$APP/songs/$(basename "$f")" ] && cp "$f" "$APP/songs/"
done

# Build the Space-key window locally when the Xcode Command Line Tools are present.
if xcode-select -p >/dev/null 2>&1 && command -v swiftc >/dev/null 2>&1; then
  echo "Compiling the Space-key window ..."
  swiftc -swift-version 5 -suppress-warnings -O -framework AppKit \
    -o "$APP/bin/song-dialog" "$APP/bin/song-dialog.swift" 2>/dev/null \
    || echo "  compile failed; using the prebuilt window instead."
else
  echo "Xcode Command Line Tools not found; using the prebuilt window."
  echo "  (If it cannot run on this Mac, a fallback dialog appears and Enter stops the music.)"
fi

# First install: pick the bundled jingle so it works immediately.
[ -f "$APP/song.conf" ] || "$APP/bin/claude-song" set default-jingle >/dev/null

# Add the two hooks to ~/.claude/settings.json (replacing any older claude-song entries).
[ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak-claude-song"
osascript -l JavaScript - "$SETTINGS" "$APP/bin/claude-song" >/dev/null <<'JXA'
function run(argv) {
  ObjC.import('Foundation');
  var path = argv[0], cmd = argv[1], text = '{}';
  if ($.NSFileManager.defaultManager.fileExistsAtPath(path)) {
    text = ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null)) || '{}';
  }
  var s;
  try { s = JSON.parse(text); } catch (e) { throw new Error('settings.json is not valid JSON: ' + path); }
  s.hooks = s.hooks || {};
  function put(event, command, extra) {
    var list = (s.hooks[event] || []).filter(function (g) { return JSON.stringify(g).indexOf('claude-song') === -1; });
    var h = { type: 'command', command: command, timeout: 10 };
    for (var k in extra) h[k] = extra[k];
    list.push({ hooks: [h] });
    s.hooks[event] = list;
  }
  put('Stop', '"' + cmd + '" play >/dev/null 2>&1 || true', { async: true });
  put('UserPromptSubmit', '"' + cmd + '" stop >/dev/null 2>&1 || true', {});
  var out = JSON.stringify(s, null, 2) + '\n';
  $.NSString.alloc.initWithUTF8String(out).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
  return 'ok';
}
JXA
echo "Hooks added to $SETTINGS"

# Put the command on PATH.
mkdir -p "$HOME/.local/bin"
ln -sf "$APP/bin/claude-song" "$HOME/.local/bin/claude-song"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    if ! grep -qs 'claude-song' "$HOME/.zshrc" 2>/dev/null; then
      printf '\n# claude-song command (added by the claude-song installer)\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zshrc"
      echo "Added ~/.local/bin to PATH in ~/.zshrc (open a new terminal to use 'claude-song')."
    fi ;;
esac

echo
echo "claude-song is installed."
echo "  Test it now:        claude-song play        (press Space to stop)"
echo "  Use your own song:  claude-song add ~/Downloads/your-song.mp3"
echo "  Status / settings:  claude-song status      claude-song config"
echo "  In Claude Code, run /hooks once (or restart it) so the new hooks load."
