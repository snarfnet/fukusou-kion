import CreateML
import Foundation

let scriptURL = URL(fileURLWithPath: #filePath)
let root = scriptURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let trainURL = root.appendingPathComponent("augmented/train")
let valURL = root.appendingPathComponent("augmented/val")
let modelsURL = root.appendingPathComponent("models")
let modelURL = modelsURL.appendingPathComponent("TsuchinokoCandidate.mlmodel")

try FileManager.default.createDirectory(at: modelsURL, withIntermediateDirectories: true)

let parameters = MLImageClassifier.ModelParameters(
    validation: .split(strategy: .automatic),
    maxIterations: 25,
    augmentation: [.crop, .exposure, .blur, .noise, .flip, .rotation],
    algorithm: .transferLearning(
        featureExtractor: .scenePrint(revision: 2),
        classifier: .logisticRegressor
    )
)

let trainingData = MLImageClassifier.DataSource.labeledDirectories(at: trainURL)
let classifier = try MLImageClassifier(trainingData: trainingData, parameters: parameters)

if FileManager.default.fileExists(atPath: valURL.path) {
    let validationData = MLImageClassifier.DataSource.labeledDirectories(at: valURL)
    let metrics = classifier.evaluation(on: validationData)
    print("validation accuracy: \(metrics.classificationError)")
}

var metadata = MLModelMetadata(author: "TokyoNasu")
metadata.shortDescription = "Classifies tsuchinoko candidate images vs common false positives."
metadata.version = "0.1"

try classifier.write(to: modelURL, metadata: metadata)
print("saved: \(modelURL.path)")
