# claude-song 🎵

**Know the moment Claude Code is done, from anywhere in the room.**

When Claude Code finishes a task, claude-song plays a song of your choice on repeat and pops up a small
"Claude Code is done" window. Press **Space** (or Enter, Esc, or click) and the music stops.
Sending your next prompt in Claude Code stops it too.

Works in every Claude Code window and project on your Mac, because it hooks into Claude Code itself.

## Install (macOS)

One line:

```bash
curl -fsSL https://raw.githubusercontent.com/BharatVerma77/claude-song/main/install.sh | bash
```

Or from a clone:

```bash
git clone https://github.com/BharatVerma77/claude-song.git
cd claude-song && ./install.sh
```

Then, in Claude Code, run `/hooks` once (or restart Claude Code) so it loads the new hooks.
Everything lands in `~/.claude/claude-song/`. Your `~/.claude/settings.json` gets two hooks added; a backup is
saved next to it as `settings.json.bak-claude-song`.

### Or install it as a Claude Code plugin

```
/plugin marketplace add BharatVerma77/claude-song
/plugin install claude-song@claude-song
```

The plugin route adds the hooks for you. To get the `claude-song` command on your PATH as well, symlink it:
`ln -s ~/.claude/plugins/cache/*/claude-song/*/bin/claude-song ~/.local/bin/claude-song` (path may vary).

## Use your own song

```bash
claude-song add ~/Downloads/my-song.mp3     # copies it into ~/.claude/claude-song/songs and selects it
claude-song set moon                         # or select by (part of) a filename already in that folder
claude-song play                             # try it now, press Space to stop
claude-song status
```

Any file macOS can play works: mp3, m4a, wav, aiff, flac. A short royalty-free jingle is included so it works
out of the box.

## A whole playlist instead of one song

Add as many songs as you want, then turn on shuffle. Every time Claude finishes, a different one plays —
never the same song twice in a row.

```bash
claude-song add ~/Downloads/song-one.mp3
claude-song add ~/Downloads/song-two.mp3
claude-song add ~/Downloads/song-three.mp3
claude-song shuffle on
```

`claude-song status` shows how many songs are in rotation and which one played last.
`claude-song shuffle off` goes back to always playing one fixed song.

## Commands

| Command | What it does |
|---|---|
| `claude-song play` | Start the song and the window (this is what the Stop hook runs) |
| `claude-song stop` | Stop the song (this is what the UserPromptSubmit hook runs) |
| `claude-song add <file>` | Copy a song into the songs folder |
| `claude-song set <file-or-name>` | Play one fixed song, by path or by part of a filename in the songs folder |
| `claude-song shuffle on` / `off` | Rotate a different song every time, instead of one fixed song |
| `claude-song list` | List the songs folder |
| `claude-song status` | Current song or shuffle state, window type, playing or not |
| `claude-song off` / `on` | Pause or resume the alert without uninstalling |
| `claude-song config` | Print the settings file path |

## Settings

`~/.claude/claude-song/song.conf`:

```bash
SONG="moonrise"     # a path, or part of a filename inside the songs folder (ignored while SHUFFLE=1)
VOLUME=1            # 1 = normal, 0.5 = half, 2 = louder
LOOP=1              # 1 = repeat the current song until you press Space, 0 = play once and stop on its own
MAX_MINUTES=0       # safety cap in minutes; 0 = keep playing until dismissed
SHUFFLE=0           # 1 = pick a different song from the songs folder every time, 0 = always play SONG
```

Set `LOOP=0` if you'd rather it just play the song once and stop, instead of looping until you dismiss it.

## How it works

- A **Stop** hook in Claude Code runs `claude-song play`. It starts a detached player that loops the song with
  `afplay` and shows the window. The window is a tiny native macOS app (Swift, `bin/song-dialog.swift`) that
  takes keyboard focus and exits on Space, Enter, Esc, click, or close. When it exits, the music stops.
- A **UserPromptSubmit** hook runs `claude-song stop`, so typing your next prompt silences it.
- The installer compiles the window locally when the Xcode Command Line Tools are present, otherwise it uses the
  prebuilt universal binary in `bin/`. If neither can run, an AppleScript dialog appears instead and Enter stops
  the music.

## Good to know

- The window takes focus when it appears. If you are typing in another app at that exact moment, your first
  Space press stops the music instead of typing a space.
- With several Claude Code windows open, any window finishing plays the song, and sending a prompt in any window
  stops it.
- Requires macOS. Nothing is sent anywhere; it is a few shell scripts and one small Swift program.

## Uninstall

```bash
~/.claude/claude-song/uninstall.sh      # or: ./uninstall.sh from a clone
```

This removes the hooks, the command, and `~/.claude/claude-song` (including the songs folder).

## License

MIT
