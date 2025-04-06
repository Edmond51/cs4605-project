import Foundation
import SoundAnalysis
import AVFoundation

class SoundDetectionManager: NSObject, SNResultsObserving {
    
    private var analyzer: SNAudioStreamAnalyzer?
    private var request: SNClassifySoundRequest?
    private let queue = DispatchQueue(label: "SoundAnalysisQueue")
    private var audioEngine: AVAudioEngine?
    
    var detectionCallback: ((DetectedSound) -> Void)?

    override init() {
        super.init()
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine?.inputNode
        let format = inputNode?.outputFormat(forBus: 0)

        guard let format = format else {
            print("Failed to get audio format")
            return
        }

        analyzer = SNAudioStreamAnalyzer(format: format)
        
        do {
            request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            if let request = request {
                try analyzer?.add(request, withObserver: self)
            }
        } catch {
            print("Error setting up sound classification request: \(error)")
        }
    }

    func startListening(callback: @escaping (DetectedSound) -> Void) {
        detectionCallback = callback
        
        guard let inputNode = audioEngine?.inputNode else {
            print("Failed to get input node")
            return
        }
        
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, time) in
            self.queue.async {
                self.analyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }

        do {
            try audioEngine?.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
    }

    // ✅ FIX: Handle results using SNResultsObserving
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        
        if let bestClassification = result.classifications.first, bestClassification.confidence > 0.8 {
            let detectedSound = DetectedSound(from: bestClassification.identifier)
            detectionCallback?(detectedSound)
        }
    }
}

// ✅ Enum to handle detected sounds
enum DetectedSound {
    case runningWater
    case unknown

    init(from identifier: String) {
        switch identifier {
        case "running_water":
            self = .runningWater
        default:
            self = .unknown
        }
    }
}
