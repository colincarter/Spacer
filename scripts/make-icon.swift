// Draws the app icon and writes Spacer/Assets.xcassets/AppIcon.appiconset.
// Usage: swift scripts/make-icon.swift
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let setDir = URL(fileURLWithPath: "Spacer/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: setDir, withIntermediateDirectories: true)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

/// Draws on a 1024-point canvas scaled to `pixels`.
func render(pixels: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)

    // Body: macOS icon grid is an 824-point rounded square centred on the canvas.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.3))
    ctx.addPath(bodyPath)
    ctx.setFillColor(color(0x3A3FD6))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: nil, colors: [color(0x6B5CF6), color(0x2E3AB8)] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

    // Menu bar strip across the top.
    ctx.setFillColor(color(0xFFFFFF, 0.18))
    ctx.fill(CGRect(x: 100, y: 770, width: 824, height: 154))
    ctx.restoreGState()

    // Three desktops; the middle one is current.
    let tileSize = CGSize(width: 190, height: 240)
    let gap: CGFloat = 50
    let startX = 512 - (tileSize.width * 3 + gap * 2) / 2
    for i in 0..<3 {
        let rect = CGRect(x: startX + CGFloat(i) * (tileSize.width + gap), y: 290,
                          width: tileSize.width, height: tileSize.height)
        let path = CGPath(roundedRect: rect, cornerWidth: 40, cornerHeight: 40, transform: nil)
        ctx.addPath(path)
        if i == 1 {
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 20, color: color(0x000000, 0.35))
            ctx.setFillColor(color(0xFFFFFF))
            ctx.fillPath()
            ctx.restoreGState()
        } else {
            ctx.setFillColor(color(0xFFFFFF, 0.35))
            ctx.fillPath()
        }
    }
    return ctx.makeImage()!
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        let dest = CGImageDestinationCreateWithURL(setDir.appendingPathComponent(name) as CFURL,
                                                   UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, render(pixels: points * scale), nil)
        CGImageDestinationFinalize(dest)
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: setDir.appendingPathComponent("Contents.json"))
try #"{"info":{"author":"xcode","version":1}}"#
    .write(to: setDir.deletingLastPathComponent().appendingPathComponent("Contents.json"),
           atomically: true, encoding: .utf8)
print("Wrote \(setDir.path)")
