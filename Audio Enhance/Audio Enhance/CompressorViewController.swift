//
//  CompressorViewController.swift
//  Audio Enhance
//
//  Created by Howard Ellenberger on 1/6/24.

import UIKit
import AVFoundation
import AudioToolbox
import CoreAudioKit

class CompressorViewController: ViewController {
    weak var delegate: CompressorViewControllerDelegate?
    private var compressorNode: AVAudioUnitEffect?
    var compressorSettings: CompressorSettings!
   
    static let shared = CompressorViewController()
    
    @IBOutlet weak var unwindToViewcontroller: UIButton!
    
    @IBOutlet weak var thresholdSlider: UISlider!
    
    @IBOutlet weak var attackTimeSlider: UISlider!
    
    @IBOutlet weak var releaseTimeSlider: UISlider!
    
    @IBOutlet weak var headRoomSlider: UISlider!
    
    @IBOutlet weak var masterGainSlider: UISlider!
    
    @IBAction func thresholdSlider(_ sender: UISlider) {
        compressorSettings.threshold = sender.value
        AudioEngineManager.shared.compressorSettings.threshold = sender.value

          // Notify AudioEngineManager to update settings
          NotificationCenter.default.post(name: .compressorSettingsUpdated, object: compressorSettings)
      }
    
    @IBAction func attackTimeSlider(_ sender: UISlider) {
        compressorSettings.attackTime = sender.value
        AudioEngineManager.shared.compressorSettings.attackTime = sender.value

        // Notify AudioEngineManager to update settings
        NotificationCenter.default.post(name: .compressorSettingsUpdated, object: compressorSettings)
    }
    
    @IBAction func releaseTimeSlider(_ sender: UISlider) {
        compressorSettings.releaseTime = sender.value
        AudioEngineManager.shared.compressorSettings.releaseTime = sender.value
        // Notify AudioEngineManager to update settings
        NotificationCenter.default.post(name: .compressorSettingsUpdated, object: compressorSettings)
    }
    
    @IBAction func headRoomSlider(_ sender: UISlider) {
        compressorSettings.headRoom = sender.value
        AudioEngineManager.shared.compressorSettings.headRoom = sender.value
        // Notify AudioEngineManager to update settings
        NotificationCenter.default.post(name: .compressorSettingsUpdated, object: compressorSettings)
    }
    
    @IBAction func masterGainSlider(_ sender: UISlider) {
        compressorSettings.masterGain = sender.value
        AudioEngineManager.shared.compressorSettings.masterGain = sender.value
        // Notify AudioEngineManager to update settings
        NotificationCenter.default.post(name: .compressorSettingsUpdated, object: compressorSettings)
    }
    

    func updateCompressorParametersIfNeeded() {
        if let compressor = compressorNode {
            setCompressorParameters(compressorNode: compressor)
        } else {
            compressorNode = createCompressorNode()
            setCompressorParameters(compressorNode: compressorNode!)
        }
    }
    
    func getCompressorNode() -> AVAudioUnitEffect {
        if compressorNode == nil {
            compressorNode = createCompressorNode()
            setCompressorParameters(compressorNode: compressorNode!)
            updateCompressorParametersIfNeeded()
        }
        return compressorNode!
    }
    
    public func createCompressorNode() -> AVAudioUnitEffect {
        let audioComponentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_DynamicsProcessor,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        return AVAudioUnitEffect(audioComponentDescription: audioComponentDescription)
    }
    
    func setCompressorParameters(compressorNode: AVAudioUnitEffect) {
        let audioUnit = compressorNode.audioUnit
      
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_Threshold,
                              kAudioUnitScope_Global, 0,
                              threshold, 0)
        
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_AttackTime,
                              kAudioUnitScope_Global, 0,
                              attackTime, 0)
        
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_ReleaseTime,
                              kAudioUnitScope_Global, 0,
                              releaseTime, 0)
        
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_HeadRoom,
                              kAudioUnitScope_Global, 0,
                              headRoom, 0)
        
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_OverallGain,
                              kAudioUnitScope_Global, 0,
                              masterGain, 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch the current settings from the shared instance
        let currentSettings = AudioEngineManager.shared.compressorSettings
        compressorSettings = currentSettings

        // Update your UI elements based on currentSettings
        thresholdSlider.value = currentSettings.threshold
        attackTimeSlider.value = currentSettings.attackTime
        releaseTimeSlider.value = currentSettings.releaseTime
        headRoomSlider.value = currentSettings.headRoom
        masterGainSlider.value = currentSettings.masterGain

        // Notify the delegate if needed
        delegate?.didUpdateCompressorSettings(compressorSettings)
        
        // Set the initial values for your sliders here
        thresholdSlider.minimumValue = -70.0
        thresholdSlider.maximumValue = 0.0
        thresholdSlider.value = threshold
        
        attackTimeSlider.minimumValue = 0.0005
        attackTimeSlider.maximumValue = 0.01
        attackTimeSlider.value = attackTime
        
        releaseTimeSlider.minimumValue = 0.01
        releaseTimeSlider.maximumValue = 1.0
        releaseTimeSlider.value = releaseTime
        
        headRoomSlider.minimumValue = 0.5
        headRoomSlider.maximumValue = 10.0
        headRoomSlider.value = headRoom
        
        masterGainSlider.minimumValue = 1.0
        masterGainSlider.maximumValue = 10.0
        masterGainSlider.value = masterGain
    }
}
protocol CompressorViewControllerDelegate: AnyObject {
    func didUpdateCompressorSettings(_ settings: CompressorSettings)
}

extension Notification.Name {
    static let compressorSettingsUpdated = Notification.Name("compressorSettingsUpdated")
}
