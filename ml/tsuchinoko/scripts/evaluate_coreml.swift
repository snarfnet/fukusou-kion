import CoreML
import Foundation
import Vision

let scriptURL = URL(fileURLWithPath: #filePath)
let root = scriptURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let modelURL = root.appendingPathComponent("models/TsuchinokoCandidate.mlmodel")
let validationURL = root.appendingPathComponent("augmented/val")
let reportsURL = root.appendingPathComponent("models")
let csvURL = reportsURL.appendingPathComponent("evaluation.csv")
let jsonURL = reportsURL.appendingPathComponent("evaluation.json")
let labels = ["not_tsuchinoko", "tsuchinoko_candidate"]
let imageExtensions = Set(["jpg", "jpeg", "png", "webp"])

struct ResultRow {
    let path: String
    let expected: String
    let predicted: String
    let confidence: Double
    let correct: Bool
}

func csvEscape(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") || value.contains("\n") {
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    return value
}

func classify(url: URL, model: VNCoreMLModel) throws -> (String, Double) {
    let request = VNCoreMLRequest(model: model)
    request.imageCropAndScaleOption = .centerCrop
    let handler = VNImageRequestHandler(url: url)
    try handler.perform([request])
    guard let observations = request.results as? [VNClassificationObservation],
          let top = observations.first else {
        return ("unknown", 0.0)
    }
    return (top.identifier, Double(top.confidence))
}

try FileManager.default.createDirectory(at: reportsURL, withIntermediateDirectories: true)
let compiledModelURL = try MLModel.compileModel(at: modelURL)
let mlModel = try MLModel(contentsOf: compiledModelURL)
let visionModel = try VNCoreMLModel(for: mlModel)

var rows: [ResultRow] = []
for label in labels {
    let labelURL = validationURL.appendingPathComponent(label)
    guard let enumerator = FileManager.default.enumerator(at: labelURL, includingPropertiesForKeys: nil) else {
        continue
    }
    for case let imageURL as URL in enumerator {
        guard imageExtensions.contains(imageURL.pathExtension.lowercased()) else {
            continue
        }
        let (prediction, confidence) = try classify(url: imageURL, model: visionModel)
        let relativePath = imageURL.path.replacingOccurrences(of: root.path + "/", with: "")
        rows.append(ResultRow(
            path: relativePath,
            expected: label,
            predicted: prediction,
            confidence: confidence,
            correct: prediction == label
        ))
    }
}

let total = rows.count
let correct = rows.filter(\.correct).count
let accuracy = total == 0 ? 0.0 : Double(correct) / Double(total)
let falsePositives = rows.filter { $0.expected == "not_tsuchinoko" && $0.predicted == "tsuchinoko_candidate" }.count
let falseNegatives = rows.filter { $0.expected == "tsuchinoko_candidate" && $0.predicted == "not_tsuchinoko" }.count

var csv = "path,expected,predicted,confidence,correct\n"
for row in rows.sorted(by: { $0.path < $1.path }) {
    csv += [
        csvEscape(row.path),
        csvEscape(row.expected),
        csvEscape(row.predicted),
        String(format: "%.6f", row.confidence),
        row.correct ? "true" : "false"
    ].joined(separator: ",") + "\n"
}
try csv.write(to: csvURL, atomically: true, encoding: .utf8)

let json = """
{
  "total": \(total),
  "correct": \(correct),
  "accuracy": \(accuracy),
  "false_positives": \(falsePositives),
  "false_negatives": \(falseNegatives)
}
"""
try json.write(to: jsonURL, atomically: true, encoding: .utf8)

print("evaluation total: \(total)")
print("evaluation correct: \(correct)")
print("evaluation accuracy: \(accuracy)")
print("evaluation false positives: \(falsePositives)")
print("evaluation false negatives: \(falseNegatives)")
print("evaluation csv: \(csvURL.path)")
print("evaluation json: \(jsonURL.path)")
