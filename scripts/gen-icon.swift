// Genera build/AppIcon_1024.png: squircle estilo macOS + emoji escoba.
import AppKit

let canvas = CGSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)
image.lockFocus()

NSColor.clear.setFill()
NSRect(origin: .zero, size: canvas).fill()

// Rejilla de iconos de macOS: contenido 824x824 centrado, esquinas ~185.
let rect = NSRect(x: 100, y: 100, width: 824, height: 824)
let path = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)
let top = NSColor(calibratedRed: 0.98, green: 0.97, blue: 0.95, alpha: 1)
let bottom = NSColor(calibratedRed: 0.85, green: 0.86, blue: 0.89, alpha: 1)
NSGradient(starting: top, ending: bottom)?.draw(in: path, angle: -90)

let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 580)]
let broom = NSAttributedString(string: "🧹", attributes: attributes)
let textSize = broom.size()
broom.draw(at: NSPoint(x: (canvas.width - textSize.width) / 2,
                       y: (canvas.height - textSize.height) / 2 + 10))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:])
else { fatalError("no se pudo renderizar") }
try! png.write(to: URL(fileURLWithPath: "build/AppIcon_1024.png"))
print("build/AppIcon_1024.png listo")
