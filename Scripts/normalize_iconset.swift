#!/usr/bin/env swift

import AppKit
import Foundation

struct IconNormalizer {
    let iconsetURL: URL
    let contentScale: CGFloat

    func run() throws {
        guard contentScale > 0, contentScale <= 1 else {
            throw NSError(
                domain: "IconNormalizer",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "--content-scale must be in (0, 1]."]
            )
        }

        let files = try FileManager.default.contentsOfDirectory(
            at: iconsetURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let pngFiles = files.filter { $0.pathExtension.lowercased() == "png" }
        guard !pngFiles.isEmpty else {
            throw NSError(
                domain: "IconNormalizer",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No PNG files found in iconset: \(iconsetURL.path)"]
            )
        }

        for fileURL in pngFiles {
            try normalizePNG(at: fileURL)
        }
    }

    private func normalizePNG(at fileURL: URL) throws {
        guard let source = NSImage(contentsOf: fileURL) else {
            throw NSError(
                domain: "IconNormalizer",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load PNG: \(fileURL.path)"]
            )
        }

        let original = bestRepresentationSize(from: source)
        let canvasSide = Int(round(max(original.width, original.height)))
        guard canvasSide > 0 else {
            throw NSError(
                domain: "IconNormalizer",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "Invalid PNG size: \(fileURL.lastPathComponent)"]
            )
        }

        let targetSide = max(1, Int(round(CGFloat(canvasSide) * contentScale)))
        let canvasSize = NSSize(width: canvasSide, height: canvasSide)
        let targetRect = NSRect(
            x: CGFloat(canvasSide - targetSide) / 2,
            y: CGFloat(canvasSide - targetSide) / 2,
            width: CGFloat(targetSide),
            height: CGFloat(targetSide)
        )

        let output = NSImage(size: canvasSize)
        output.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(in: targetRect, from: .zero, operation: .copy, fraction: 1.0)
        output.unlockFocus()

        guard
            let tiff = output.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let pngData = rep.representation(using: .png, properties: [:])
        else {
            throw NSError(
                domain: "IconNormalizer",
                code: 6,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG: \(fileURL.path)"]
            )
        }

        try pngData.write(to: fileURL, options: .atomic)
    }

    private func bestRepresentationSize(from image: NSImage) -> NSSize {
        if let rep = image.representations.max(by: { $0.pixelsWide < $1.pixelsWide }) {
            let width = max(rep.pixelsWide, 1)
            let height = max(rep.pixelsHigh, 1)
            return NSSize(width: width, height: height)
        }
        return image.size
    }
}

func parseArguments() throws -> (URL, CGFloat) {
    let args = CommandLine.arguments.dropFirst()
    var iconsetPath: String?
    var contentScale: CGFloat = 0.82

    var index = 0
    let allArgs = Array(args)
    while index < allArgs.count {
        let arg = allArgs[index]
        switch arg {
        case "--iconset":
            index += 1
            guard index < allArgs.count else {
                throw NSError(domain: "IconNormalizer", code: 10, userInfo: [NSLocalizedDescriptionKey: "Missing value for --iconset"])
            }
            iconsetPath = allArgs[index]
        case "--content-scale":
            index += 1
            guard index < allArgs.count, let value = Double(allArgs[index]) else {
                throw NSError(domain: "IconNormalizer", code: 11, userInfo: [NSLocalizedDescriptionKey: "Invalid value for --content-scale"])
            }
            contentScale = CGFloat(value)
        default:
            throw NSError(domain: "IconNormalizer", code: 12, userInfo: [NSLocalizedDescriptionKey: "Unknown argument: \(arg)"])
        }
        index += 1
    }

    guard let iconsetPath else {
        throw NSError(domain: "IconNormalizer", code: 13, userInfo: [NSLocalizedDescriptionKey: "Missing required --iconset argument"])
    }

    return (URL(fileURLWithPath: iconsetPath), contentScale)
}

do {
    let (iconsetURL, contentScale) = try parseArguments()
    try IconNormalizer(iconsetURL: iconsetURL, contentScale: contentScale).run()
} catch {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
