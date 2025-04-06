import SoundAnalysis
import AVFoundation

class SoundClassifier: NSObject {
    private let audioEngine = AVAudioEngine()
    private var analyzer: SNAudioStreamAnalyzer
    private let queue = DispatchQueue(label: "SoundAnalysisQueue")
    
    var onWaterDetected: (() -> Void)? // Callback when water is detected

    override init() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Log the actual audio format received from input node
        print("Recording format: \(recordingFormat)")

        // Ensure that the format is valid
        guard recordingFormat.sampleRate != 0, recordingFormat.channelCount != 0 else {
            print("Invalid audio format")
            // Initialize analyzer with a fallback format
            self.analyzer = SNAudioStreamAnalyzer(format: AVAudioFormat())
            super.init() // Call super.init before returning
            return
        }
        
        // If the format is valid, initialize the analyzer with the correct format
        self.analyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        
        super.init() // Call super.init here to ensure it's called on all paths
    }

    func startListening() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Validate sample rate and channel count
        guard recordingFormat.sampleRate != 0, recordingFormat.channelCount != 0 else {
            print("Invalid audio format")
            return
        }

        // Tap audio buffer for processing
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
    }
}

// MARK: - Sound Classification Results
extension SoundClassifier: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }

        print("Sound detected: \(classification.identifier), Confidence: \(classification.confidence)")

        // Only trigger if confidence is above a certain threshold
        if (classification.identifier.lowercased() == "water_tap_faucet" || classification.identifier.lowercased() == "water") && classification.confidence > 0.75 {
            print("🚰 Running water detected! Confidence: \(classification.confidence)")
            DispatchQueue.main.async {
                self.onWaterDetected?() // Trigger alarm stop
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("Sound classification failed: \(error.localizedDescription)")
    }
}

