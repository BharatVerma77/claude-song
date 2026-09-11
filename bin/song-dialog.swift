// song-dialog: floating "Claude Code is done" window. Exits when the user presses
// Space, Enter, Escape, clicks the button, or closes the window (or after a timeout).
// Usage: song-dialog "<message>" "<title>" <timeout-seconds (0 = never)>
import AppKit

let args    = CommandLine.arguments
let message = args.count > 1 ? args[1] : "Claude Code is done."
let title   = args.count > 2 ? args[2] : "Claude Code"
let timeout = args.count > 3 ? (Double(args[3]) ?? 0) : 0

func log(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }
final class Controller: NSObject, NSApplicationDelegate, NSWindowDelegate {
    @objc func stop(_ sender: Any?) { log("exit: button"); NSApp.terminate(nil) }
    func windowWillClose(_ n: Notification) { log("exit: window closed"); NSApp.terminate(nil) }
    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
let ctl = Controller()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = ctl

let w: CGFloat = 440, h: CGFloat = 168
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: w, height: h),
                      styleMask: [.titled, .closable], backing: .buffered, defer: false)
window.title = title
window.level = .floating
window.isReleasedWhenClosed = false
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
window.delegate = ctl
window.center()

let content = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
window.contentView = content

let note = NSTextField(labelWithString: "🎵")
note.font = NSFont.systemFont(ofSize: 44)
note.frame = NSRect(x: 22, y: h - 92, width: 64, height: 64)
content.addSubview(note)

let label = NSTextField(wrappingLabelWithString: message)
label.font = NSFont.systemFont(ofSize: 13)
label.maximumNumberOfLines = 0
label.frame = NSRect(x: 96, y: 60, width: w - 116, height: h - 80)
content.addSubview(label)

let hint = NSTextField(labelWithString: "Space  ·  Enter  ·  Esc  — any of them stops the music")
hint.font = NSFont.systemFont(ofSize: 11)
hint.textColor = .secondaryLabelColor
hint.frame = NSRect(x: 96, y: 22, width: 220, height: 18)
content.addSubview(hint)

let button = NSButton(title: "Stop music", target: ctl, action: #selector(Controller.stop(_:)))
button.bezelStyle = .rounded
button.keyEquivalent = "\r"
button.frame = NSRect(x: w - 140, y: 14, width: 120, height: 32)
content.addSubview(button)

// Space (49), Return (36), keypad Enter (76), Escape (53)
NSEvent.addLocalMonitorForEvents(matching: .keyDown) { ev in
    if [49, 36, 76, 53].contains(Int(ev.keyCode)) { log("exit: key \(ev.keyCode)"); NSApp.terminate(nil); return nil }
    return ev
}

if timeout > 0 {
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { log("exit: timeout"); NSApp.terminate(nil) }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
    FileHandle.standardError.write("active=\(NSApp.isActive) key=\(window.isKeyWindow) visible=\(window.isVisible)\n".data(using: .utf8)!)
}
window.makeKeyAndOrderFront(nil)
NSApp.activate(ignoringOtherApps: true)
app.run()
