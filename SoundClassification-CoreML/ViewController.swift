//
//  ViewController.swift
//  SoundClassification-CoreML
//
//  Created by jjaychen on 2021/6/7.
//

import UIKit
import SoundAnalysis
import CoreML
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var prediction: UILabel!
    
    private var audioSteamAnalyzer: SNAudioStreamAnalyzer!
    private let audioEngine = AVAudioEngine()
    private var inputFormat: AVAudioFormat!
    private let analysisQueue = DispatchQueue(label: "com.custom.AnalysisQueue")
    private var resultsObserver: ResultsObserver!
    var model: MLModel!
    
    var randomColors: [String: UIColor] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        resultsObserver = ResultsObserver()
        resultsObserver.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        let soundClassifier = MySoundClassifier()
        model = soundClassifier.model
        self.startAudioAnalysis()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        audioEngine.stop()
    }
    
    
    func startAudioAnalysis() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        
            inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
            audioSteamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
        } catch {
            print(error)
        }
        
        // Prepare a new request for the trained model.
        do {
            let request = try SNClassifySoundRequest(mlModel: model)
            try audioSteamAnalyzer.add(request, withObserver: resultsObserver)

        } catch {
            print(error)
        }
        
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
            self.analysisQueue.async {
                self.audioSteamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        
        do{
            try audioEngine.start()
        } catch {
            print("error in starting the Audio Engin")
        }
    }
    
}

extension ViewController: ResultsObserverDelegate {
    func displayPredictionResult(identifier: String, confidence: Double) {
        if confidence > 95 {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.7, delay: 0, options: [.beginFromCurrentState]) {
                    if self.randomColors[identifier] == nil {
                        self.randomColors[identifier] = UIColor(red: CGFloat.random(in: 0.2...0.8),
                                                                green: CGFloat.random(in: 0.2...0.8),
                                                                blue: CGFloat.random(in: 0.2...0.8),
                                                           alpha: 1.0)
                    }
                    self.view.backgroundColor = self.randomColors[identifier]
                    self.prediction.text = identifier
                }
            }
        } else {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.7, delay: 0, options: [.beginFromCurrentState]) {
                    self.view.backgroundColor = self.view.backgroundColor?.withAlphaComponent(0.7)
                    self.prediction.text = ""
                }
            }
        }
    }
}

