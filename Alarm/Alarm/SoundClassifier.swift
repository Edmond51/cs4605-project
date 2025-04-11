import SoundAnalysis
import AVFoundation

class SoundClassifier: NSObject {
    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer
    private let queue = DispatchQueue(label: "SoundAnalysisQueue")

    var onWaterDetected: (() -> Void)? // Callback when water is detected
    var onSessionEndRequested: (() -> Void)? // ✅ NEW: Callback to request audio session end

    override init() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        print("Recording format: \(recordingFormat)")

        guard recordingFormat.sampleRate != 0, recordingFormat.channelCount != 0 else {
            print("Invalid audio format")
            self.analyzer = SNAudioStreamAnalyzer(format: AVAudioFormat())
            super.init()
            return
        }

        self.analyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        super.init()
    }

    func startListening() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate != 0, recordingFormat.channelCount != 0 else {
            print("Invalid audio format")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            print("Audio buffer received")
            self.queue.async {
                self.analyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
            }
        }

        do {
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            try analyzer.add(request, withObserver: self)
            try audioEngine.start()
            print("Listening for water sounds...")
        } catch {
            print("Error starting sound analysis: \(error.localizedDescription)")
        }
    }

    func stopListening() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        print("Stopped listening.")

        // ✅ Trigger session end when stopping
        onSessionEndRequested?()
    }
}

// MARK: - Sound Classification Results
extension SoundClassifier: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }

        print("Sound detected: \(classification.identifier), Confidence: \(classification.confidence)")

        if (classification.identifier.lowercased() == "water_tap_faucet" || classification.identifier.lowercased() == "water"),
            classification.confidence > 0.3 {
            print("🚰 Running water detected! Confidence: \(classification.confidence)")
            DispatchQueue.main.async {
                self.onWaterDetected?()
                self.onSessionEndRequested?() // ✅ Call session-end trigger here too
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Sound classification failed: \(error.localizedDescription)")
    }
}


