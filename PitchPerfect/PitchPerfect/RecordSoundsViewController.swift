//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by Josh Manigsaca on 8/10/20.
//  Copyright © 2020 Josh Manigsaca. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {
    
    // Initialize variables
    var audioRecorder: AVAudioRecorder!
    var levelTimer    : Timer!
    var meterMaxWidth : CGFloat = 0
    let meterMaxPower : Float = 50.0
    let meterBorderColor = UIColor.lightGray.cgColor
    
    // IBOutlets
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var audioLevelView: UIView!
    
    // View functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure audio meter
        audioLevelView.layer.cornerRadius = audioLevelView.bounds.height/2
        audioLevelView.layer.borderColor  = meterBorderColor
        meterMaxWidth = (audioLevelView.bounds.width - recordButton.bounds.width)/2
        
        // Configure record button at start
        uiToggle(recording: false)
    }

    // IBActions
    @IBAction func recordAudio(_ sender: Any) {
        // Toggle record button
        uiToggle(recording: true)
        
        // Get file path
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))
        
        // Configure audio recorder
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        
        // Record audio
        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        
        // Start audio meter timer
        levelTimer = Timer.scheduledTimer(timeInterval: 0.05,
                                          target: self,
                                          selector: #selector(self.updateMeter(_:)),
                                          userInfo: nil,
                                          repeats: true)
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        // Toggle record button
        uiToggle(recording: false)
        
        // Stop timer
        levelTimer.invalidate()
        
        // Stop recording
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    // Other functions
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            performSegue(withIdentifier: "stopRecording", sender: audioRecorder.url)
        } else {
            print("recording was not successful")
        }
        
    }
    
    func uiToggle(recording: Bool = true) {
        // Reset audio meter
        audioLevelView.layer.opacity = 0
        audioLevelView.layer.borderWidth = meterMaxWidth
        
        // Toggle button visibility
        recordButton.isHidden = recording
        stopRecordingButton.isHidden = !recording
        
        // Toggle button text
        recordingLabel.text = recording ? "click to stop recording" : "click to start recording"
    }
    
    // Update audio meter and record time
    @objc func updateMeter(_ timer:Timer) {
        
        let minutes     = Int(audioRecorder.currentTime / 60)
        let seconds     = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
        let timerString = String(format: "%02d:%02d", minutes, seconds)
        
        recordingLabel.text = "\(timerString) click to stop recording"
        
        audioRecorder.updateMeters()
        
        // Update meter indicator using UIView border width
        let averagePowerChannel0 = audioRecorder.averagePower(forChannel: 0)
        
        // Convert power to percentage
        let level : Float = -averagePowerChannel0/meterMaxPower
        
        // Only accept values between 0 and 1 to update opacity and border width
        if level < 1 && level >= 0 {
            audioLevelView.layer.opacity = (1 - level)
            audioLevelView.layer.borderWidth = CGFloat(level) * meterMaxWidth
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stopRecording" {
            let playSoundsVC = segue.destination as! PlaySoundsViewController
            let recordedAudioURL = sender as! URL
            playSoundsVC.recordedAudioURL = recordedAudioURL
        }
    }
}

