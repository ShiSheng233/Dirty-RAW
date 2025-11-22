//
//  TIFFExporter.swift
//  Dirty RAW
//

import Foundation
import AppKit
import UniformTypeIdentifiers

class TIFFExporter {

    enum ExportError: LocalizedError {
        case noImage
        case failedToCreateDestination
        case failedToWrite

        var errorDescription: String? {
            switch self {
            case .noImage:
                return "No image to export"
            case .failedToCreateDestination:
                return "Failed to create TIFF destination"
            case .failedToWrite:
                return "Failed to write TIFF file"
            }
        }
    }

    static func export(image: NSImage, to url: URL, bitDepth: Int = 16) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExportError.noImage
        }

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.tiff.identifier as CFString,
            1,
            nil
        ) else {
            throw ExportError.failedToCreateDestination
        }

        // Configure TIFF options for uncompressed output
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 1.0,
            kCGImagePropertyTIFFCompression: 1, // No compression
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        if !CGImageDestinationFinalize(destination) {
            throw ExportError.failedToWrite
        }
    }

}

