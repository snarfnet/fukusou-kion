import Foundation
import UIKit

enum APNGEncoder {
    static func encode(images: [UIImage], delay: TimeInterval, loopCount: Int) throws -> Data {
        let frames = try images.map { image -> PNGFrame in
            guard let pngData = image.pngData(),
                  let frame = PNGFrame(pngData: pngData) else {
                throw StudioError.renderFailed
            }
            return frame
        }

        guard let first = frames.first else {
            throw StudioError.renderFailed
        }

        var output = Data([137, 80, 78, 71, 13, 10, 26, 10])
        output.append(chunk(type: "IHDR", data: first.ihdr))
        output.append(chunk(type: "acTL", data: actl(frameCount: frames.count, loopCount: loopCount)))

        var sequence: UInt32 = 0
        let delayParts = delayFraction(delay)
        output.append(chunk(type: "fcTL", data: fctl(
            sequence: sequence,
            width: first.width,
            height: first.height,
            delayNumerator: delayParts.numerator,
            delayDenominator: delayParts.denominator
        )))
        sequence += 1
        output.append(chunk(type: "IDAT", data: first.idat))

        for frame in frames.dropFirst() {
            output.append(chunk(type: "fcTL", data: fctl(
                sequence: sequence,
                width: frame.width,
                height: frame.height,
                delayNumerator: delayParts.numerator,
                delayDenominator: delayParts.denominator
            )))
            sequence += 1

            var frameData = Data()
            frameData.appendUInt32(sequence)
            frameData.append(frame.idat)
            output.append(chunk(type: "fdAT", data: frameData))
            sequence += 1
        }

        output.append(chunk(type: "IEND", data: Data()))
        return output
    }

    private struct PNGFrame {
        let width: Int
        let height: Int
        let ihdr: Data
        let idat: Data

        init?(pngData: Data) {
            guard pngData.starts(with: Data([137, 80, 78, 71, 13, 10, 26, 10])) else {
                return nil
            }

            var offset = 8
            var ihdrData: Data?
            var idatData = Data()

            while offset + 12 <= pngData.count {
                let length = Int(pngData.readUInt32(at: offset))
                let typeStart = offset + 4
                let dataStart = offset + 8
                let dataEnd = dataStart + length
                let nextOffset = dataEnd + 4

                let typeData = pngData.subdata(in: typeStart..<(typeStart + 4))
                guard nextOffset <= pngData.count,
                      let type = String(data: typeData, encoding: .ascii) else {
                    return nil
                }

                let chunkData = pngData.subdata(in: dataStart..<dataEnd)

                switch type {
                case "IHDR":
                    ihdrData = chunkData
                case "IDAT":
                    idatData.append(chunkData)
                case "IEND":
                    offset = pngData.count
                    continue
                default:
                    break
                }

                offset = nextOffset
            }

            guard let ihdrData,
                  ihdrData.count == 13,
                  !idatData.isEmpty else {
                return nil
            }

            ihdr = ihdrData
            idat = idatData
            width = Int(ihdrData.readUInt32(at: 0))
            height = Int(ihdrData.readUInt32(at: 4))
        }
    }

    private static func actl(frameCount: Int, loopCount: Int) -> Data {
        var data = Data()
        data.appendUInt32(UInt32(frameCount))
        data.appendUInt32(UInt32(max(0, loopCount)))
        return data
    }

    private static func fctl(sequence: UInt32, width: Int, height: Int, delayNumerator: UInt16, delayDenominator: UInt16) -> Data {
        var data = Data()
        data.appendUInt32(sequence)
        data.appendUInt32(UInt32(width))
        data.appendUInt32(UInt32(height))
        data.appendUInt32(0)
        data.appendUInt32(0)
        data.appendUInt16(delayNumerator)
        data.appendUInt16(delayDenominator)
        data.append(0)
        data.append(0)
        return data
    }

    private static func delayFraction(_ delay: TimeInterval) -> (numerator: UInt16, denominator: UInt16) {
        let denominator: UInt16 = 1000
        let numerator = UInt16(max(1, min(65535, Int((delay * 1000).rounded()))))
        return (numerator, denominator)
    }

    private static func chunk(type: String, data: Data) -> Data {
        var output = Data()
        let typeData = Data(type.utf8)
        output.appendUInt32(UInt32(data.count))
        output.append(typeData)
        output.append(data)

        var crcInput = Data()
        crcInput.append(typeData)
        crcInput.append(data)
        output.appendUInt32(crc32(crcInput))
        return output
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                let mask = UInt32(bitPattern: Int32(-(Int(crc & 1))))
                crc = (crc >> 1) ^ (0xedb88320 & mask)
            }
        }
        return ~crc
    }
}

private extension Data {
    func readUInt32(at index: Int) -> UInt32 {
        (UInt32(self[index]) << 24)
            | (UInt32(self[index + 1]) << 16)
            | (UInt32(self[index + 2]) << 8)
            | UInt32(self[index + 3])
    }

    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }
}
