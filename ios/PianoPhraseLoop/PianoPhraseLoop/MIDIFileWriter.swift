import Foundation

enum MIDIFileWriter {
    static func write(phrase: PianoPhrase) throws -> URL {
        let safeName = phrase.name.replacingOccurrences(of: " ", with: "-")
        let filename = "PianoPhrase-\(safeName)-\(Int(Date().timeIntervalSince1970)).mid"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try makeData(phrase: phrase).write(to: url, options: .atomic)
        return url
    }

    private static func makeData(phrase: PianoPhrase) -> Data {
        let ticksPerBeat: UInt16 = 480
        let ticksPerSecond = Double(ticksPerBeat) * Double(phrase.bpm) / 60.0
        let tempo = 60_000_000 / phrase.bpm
        var track = Data()

        track.appendVLQ(0)
        track.append(contentsOf: [0xFF, 0x51, 0x03])
        track.appendUInt24(UInt32(tempo))

        track.appendVLQ(0)
        track.append(contentsOf: [0xC0, 0x00])

        var events: [(tick: UInt32, bytes: [UInt8])] = []
        for note in phrase.notes {
            let startTick = UInt32((note.start * ticksPerSecond).rounded())
            let endTick = UInt32(((note.start + note.duration) * ticksPerSecond).rounded())
            let pitch = UInt8(max(0, min(127, note.pitch)))
            let velocity = UInt8(max(1, min(127, note.velocity)))
            events.append((startTick, [0x90, pitch, velocity]))
            events.append((max(startTick + 1, endTick), [0x80, pitch, 0]))
        }

        events.sort {
            if $0.tick == $1.tick {
                return $0.bytes[0] < $1.bytes[0]
            }
            return $0.tick < $1.tick
        }

        var lastTick: UInt32 = 0
        for event in events {
            track.appendVLQ(event.tick - lastTick)
            track.append(contentsOf: event.bytes)
            lastTick = event.tick
        }

        let endTick = UInt32((phrase.duration * ticksPerSecond).rounded())
        track.appendVLQ(endTick > lastTick ? endTick - lastTick : 0)
        track.append(contentsOf: [0xFF, 0x2F, 0x00])

        var data = Data()
        data.appendString("MThd")
        data.appendUInt32(6)
        data.appendUInt16(0)
        data.appendUInt16(1)
        data.appendUInt16(ticksPerBeat)
        data.appendString("MTrk")
        data.appendUInt32(UInt32(track.count))
        data.append(track)
        return data
    }
}

private extension Data {
    mutating func appendString(_ value: String) {
        append(contentsOf: value.utf8)
    }

    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }

    mutating func appendUInt24(_ value: UInt32) {
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }

    mutating func appendVLQ(_ value: UInt32) {
        var buffer = [UInt8(value & 0x7F)]
        var next = value >> 7
        while next > 0 {
            buffer.insert(UInt8((next & 0x7F) | 0x80), at: 0)
            next >>= 7
        }
        append(contentsOf: buffer)
    }
}
