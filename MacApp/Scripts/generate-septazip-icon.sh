#!/bin/bash
#
# Generate SeptaZip app icon
# Creates a modern macOS icon with a metallic 'S' that forms the number '7'
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../SevenZipMac/Resources/Assets.xcassets/AppIcon.appiconset"

mkdir -p "$OUTPUT_DIR"

echo "=== Generating SeptaZip App Icon ==="

# Create the icon using Swift with Core Graphics
swift - <<'SWIFT_CODE'
import Cocoa
import CoreGraphics

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let outputDir = CommandLine.arguments[1]

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Background - Deep navy blue with subtle gradient
    let gradient = NSGradient(colors: [
        NSColor(red: 0.12, green: 0.18, blue: 0.32, alpha: 1.0),  // Dark navy
        NSColor(red: 0.08, green: 0.12, blue: 0.24, alpha: 1.0)   // Darker navy
    ])!

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.225  // macOS squircle radius
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    gradient.draw(in: path, angle: 135)

    // Add subtle inner shadow for depth
    context.saveGState()
    path.addClip()

    let shadowColor = NSColor(white: 0, alpha: 0.3)
    context.setShadow(offset: CGSize(width: 0, height: size * -0.02), blur: size * 0.04, color: shadowColor.cgColor)

    NSColor(white: 1, alpha: 0.05).setFill()
    NSBezierPath(rect: rect.insetBy(dx: size * 0.02, dy: size * 0.02)).fill()

    context.restoreGState()

    // Draw zipper teeth border (left edge)
    let zipperWidth = size * 0.08
    let teethCount = Int(size / 12)

    for i in 0..<teethCount {
        let y = CGFloat(i) * (size / CGFloat(teethCount))
        let teethRect = CGRect(x: 0, y: y, width: zipperWidth, height: size / CGFloat(teethCount) * 0.4)

        let gradient = NSGradient(colors: [
            NSColor(white: 0.8, alpha: 1.0),
            NSColor(white: 0.6, alpha: 1.0)
        ])!

        gradient.draw(in: NSBezierPath(rect: teethRect), angle: 90)
    }

    // Draw metallic 'S' that forms '7'
    context.saveGState()

    let fontSize = size * 0.65
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)

    let text = "S"
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.clear
    ]

    let textSize = (text as NSString).size(withAttributes: attributes)
    let textRect = CGRect(
        x: (size - textSize.width) / 2 + size * 0.05,
        y: (size - textSize.height) / 2 - size * 0.02,
        width: textSize.width,
        height: textSize.height
    )

    // Create metallic gradient for the 'S'
    let metallicGradient = NSGradient(colors: [
        NSColor(white: 0.95, alpha: 1.0),  // Bright silver
        NSColor(white: 0.7, alpha: 1.0),   // Mid silver
        NSColor(white: 0.85, alpha: 1.0),  // Light silver
        NSColor(white: 0.6, alpha: 1.0)    // Dark silver
    ])!

    // Draw 'S' with metallic effect
    let textPath = NSBezierPath()
    textPath.move(to: textRect.origin)
    textPath.appendRect(textRect)

    context.saveGState()

    // Shadow for depth
    context.setShadow(offset: CGSize(width: 0, height: size * -0.015), blur: size * 0.03, color: NSColor(white: 0, alpha: 0.6).cgColor)

    let textAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(white: 0.9, alpha: 1.0)
    ]
    (text as NSString).draw(in: textRect, withAttributes: textAttributes)

    context.restoreGState()

    // Add subtle highlight
    context.saveGState()
    context.setBlendMode(.plusLighter)

    let highlightAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.3)
    ]

    let highlightRect = textRect.offsetBy(dx: 0, dy: size * 0.01)
    (text as NSString).draw(in: highlightRect, withAttributes: highlightAttributes)

    context.restoreGState()

    // Draw subtle '7' integration (small 7 in the 'S' curve)
    let sevenFont = NSFont.systemFont(ofSize: fontSize * 0.25, weight: .medium)
    let sevenAttributes: [NSAttributedString.Key: Any] = [
        .font: sevenFont,
        .foregroundColor: NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.6)
    ]

    let sevenText = "7"
    let sevenSize = (sevenText as NSString).size(withAttributes: sevenAttributes)
    let sevenRect = CGRect(
        x: textRect.midX - sevenSize.width / 2,
        y: textRect.midY - sevenSize.height / 2,
        width: sevenSize.width,
        height: sevenSize.height
    )

    (sevenText as NSString).draw(in: sevenRect, withAttributes: sevenAttributes)

    context.restoreGState()

    image.unlockFocus()
    return image
}

// Generate all icon sizes
for size in sizes {
    let icon = drawIcon(size: CGFloat(size))

    guard let tiffData = icon.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG for size \(size)")
        continue
    }

    let filename = "\(outputDir)/icon_\(size)x\(size).png"
    try? pngData.write(to: URL(fileURLWithPath: filename))
    print("Generated: icon_\(size)x\(size).png")
}

// Generate Contents.json
let contentsJSON = """
{
  "images" : [
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16.png", "scale" : "1x" },
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_32x32.png", "scale" : "2x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32.png", "scale" : "1x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_64x64.png", "scale" : "2x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128.png", "scale" : "1x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_256x256.png", "scale" : "2x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256.png", "scale" : "1x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_512x512.png", "scale" : "2x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512.png", "scale" : "1x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_1024x1024.png", "scale" : "2x" }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
"""

let contentsPath = "\(outputDir)/Contents.json"
try? contentsJSON.write(toFile: contentsPath, atomically: true, encoding: .utf8)
print("Generated: Contents.json")
print("\n✓ SeptaZip icon generation complete!")
SWIFT_CODE
"$OUTPUT_DIR"

echo ""
echo "Icon generated at: $OUTPUT_DIR"
