# Vision Framework Documentation

## Overview
The Vision framework provides computer vision capabilities for analyzing poker table content, including OCR for text recognition and image analysis for card/chip detection.

## Key Classes

### VNRecognizeTextRequest
Optical Character Recognition for poker table text.

```swift
func recognizeText(in image: CGImage) {
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            // Process recognized text
            processPokerText(topCandidate.string, confidence: topCandidate.confidence)
        }
    }
    
    // Configure for poker-specific text
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = ["en-US"]
    
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([request])
}
```

### VNDetectRectanglesRequest
Detect rectangular regions like cards and chips.

```swift
func detectCards(in image: CGImage) {
    let request = VNDetectRectanglesRequest { request, error in
        guard let observations = request.results as? [VNRectangleObservation] else { return }
        
        for observation in observations {
            if isCardLikeRectangle(observation) {
                processDetectedCard(observation, in: image)
            }
        }
    }
    
    request.minimumAspectRatio = 0.6  // Playing card aspect ratio
    request.maximumAspectRatio = 0.8
    request.minimumSize = 0.02
    request.maximumObservations = 10
    
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([request])
}
```

### VNClassifyImageRequest
Classify poker elements using custom models.

```swift
func classifyPokerElements(in image: CGImage) {
    guard let model = try? VNCoreMLModel(for: PokerElementClassifier().model) else { return }
    
    let request = VNCoreMLRequest(model: model) { request, error in
        guard let observations = request.results as? [VNClassificationObservation] else { return }
        
        for observation in observations {
            if observation.confidence > 0.8 {
                handlePokerElement(observation.identifier, confidence: observation.confidence)
            }
        }
    }
    
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([request])
}
```

## Poker-Specific Recognition

### Bet Amount Recognition
```swift
func extractBetAmounts(from image: CGImage) -> [PokerBet] {
    var bets: [PokerBet] = []
    
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        for observation in observations {
            guard let text = observation.topCandidates(1).first else { continue }
            
            // Look for currency patterns
            let betPattern = #/\$?(\d+(?:,\d{3})*(?:\.\d{2})?)/
            if let match = text.string.firstMatch(of: betPattern) {
                let amount = parseAmount(String(match.1))
                let bounds = observation.boundingBox
                
                bets.append(PokerBet(amount: amount, bounds: bounds))
            }
        }
    }
    
    // Optimize for numbers and currency
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([request])
    
    return bets
}
```

### Card Detection
```swift
func detectPlayingCards(in image: CGImage) -> [PlayingCard] {
    var cards: [PlayingCard] = []
    
    let request = VNDetectRectanglesRequest { request, error in
        guard let observations = request.results as? [VNRectangleObservation] else { return }
        
        for observation in observations {
            // Filter for card-like rectangles
            let aspectRatio = observation.boundingBox.width / observation.boundingBox.height
            if aspectRatio > 0.6 && aspectRatio < 0.8 {
                if let card = analyzeCard(observation, in: image) {
                    cards.append(card)
                }
            }
        }
    }
    
    request.minimumAspectRatio = 0.6
    request.maximumAspectRatio = 0.8
    request.minimumSize = 0.01
    request.minimumConfidence = 0.8
    
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([request])
    
    return cards
}
```

### Button State Detection
```swift
func detectActionButtons(in image: CGImage) -> [PokerAction] {
    var actions: [PokerAction] = []
    
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        for observation in observations {
            guard let text = observation.topCandidates(1).first else { continue }
            
            let buttonText = text.string.lowercased()
            if let actionType = PokerActionType(rawValue: buttonText) {
                actions.append(PokerAction(
                    type: actionType,
                    bounds: observation.boundingBox,
                    confidence: text.confidence
                ))
            }
        }
    }
    
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try? handler.perform([request])
    
    return actions
}
```

## Performance Optimization

### Region of Interest (ROI)
```swift
func processTableRegions(image: CGImage) {
    let tableRegions = [
        CGRect(x: 0.1, y: 0.7, width: 0.8, height: 0.2),  // Action buttons
        CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.1),  // Pot area
        CGRect(x: 0.1, y: 0.5, width: 0.8, height: 0.1)   // Player info
    ]
    
    for region in tableRegions {
        processRegion(image, roi: region)
    }
}
```

### Batch Processing
```swift
func processBatch(_ images: [CGImage]) {
    let requests = images.map { image in
        VNRecognizeTextRequest { request, error in
            // Process results
        }
    }
    
    let handler = VNSequenceRequestHandler()
    try? handler.perform(requests, on: images)
}
```

## Custom Models

### Training Data Preparation
```swift
// Prepare training data for poker-specific elements
struct PokerTrainingData {
    let cardImages: [CGImage]
    let chipImages: [CGImage]
    let buttonImages: [CGImage]
    let annotations: [String: Any]
}
```

### Model Integration
```swift
class PokerVisionAnalyzer {
    private let cardModel: VNCoreMLModel
    private let chipModel: VNCoreMLModel
    
    init() throws {
        cardModel = try VNCoreMLModel(for: CardClassifier().model)
        chipModel = try VNCoreMLModel(for: ChipClassifier().model)
    }
    
    func analyzeTable(_ image: CGImage) -> PokerTableState {
        let cards = detectCards(image)
        let chips = detectChips(image)
        let actions = detectActions(image)
        
        return PokerTableState(cards: cards, chips: chips, actions: actions)
    }
}
```

## Common Patterns

### Text Recognition Pipeline
```swift
class PokerTextRecognizer {
    func processTableText(_ image: CGImage) -> PokerTableData {
        var tableData = PokerTableData()
        
        // Extract pot amount
        if let pot = extractPotAmount(image) {
            tableData.potAmount = pot
        }
        
        // Extract player names and stacks
        tableData.players = extractPlayerInfo(image)
        
        // Extract betting actions
        tableData.actions = extractActions(image)
        
        return tableData
    }
}
```

### Real-time Processing
```swift
class RealTimePokerAnalyzer {
    private let processingQueue = DispatchQueue(label: "poker.vision", qos: .userInitiated)
    
    func analyzeFrame(_ image: CGImage) {
        processingQueue.async {
            let results = self.processPokerFrame(image)
            
            DispatchQueue.main.async {
                self.updateUI(with: results)
            }
        }
    }
}
```

## Error Handling

```swift
func handleVisionError(_ error: Error) {
    if let visionError = error as? VNError {
        switch visionError.code {
        case .invalidFormat:
            print("Invalid image format")
        case .requestCancelled:
            print("Vision request cancelled")
        case .invalidModel:
            print("Invalid Core ML model")
        default:
            print("Vision error: \(error)")
        }
    }
}
```

## Best Practices

1. **Preprocess Images**: Enhance contrast and brightness for better OCR
2. **Use ROI**: Focus on specific table regions to improve performance
3. **Batch Requests**: Process multiple images together when possible
4. **Cache Models**: Load Core ML models once and reuse
5. **Handle Confidence**: Set appropriate confidence thresholds for accuracy