//
//  ViewController.swift
//  Audio Enhance
//
//  Created by Howard Ellenberger on 12/31/23.
//

import UIKit
import AVFoundation
import AudioToolbox
import CoreAudioKit

class ViewController: UIViewController {
    
    var aem: AudioEngineManager?
    let noiseGateNode = NoiseGateNode()
    var input: AVAudioInputNode!
    var eqNode: AVAudioUnitEQ!
    var inputFormat: AVAudioFormat?
    var mixer: AVAudioMixerNode?
    
    public var leftChannelUpdated = false
    public var rightChannelUpdated = false
    
    var threshold: Float = -20.0       // Example value in dB
    var attackTime: Float = 0.004       // Example value in seconds
    var releaseTime: Float = 0.010       // Example value in seconds
    var headRoom: Float = 0.5          // Example headroom value in dB
    var masterGain: Float = 5.0        // Master Gain in dB (default is usually 0)
    
    
    @IBOutlet weak var volumeSlider: UISlider?
    
    @IBOutlet weak var EQ1Slider: UISlider!
    @IBOutlet weak var EQ2Slider: UISlider!
    @IBOutlet weak var EQ3Slider: UISlider!
    @IBOutlet weak var EQ4Slider: UISlider!
    @IBOutlet weak var EQ5Slider: UISlider!
    @IBOutlet weak var EQ6Slider: UISlider!
    
    @IBOutlet weak var noiseGate: UISlider!
    
    @IBOutlet weak var segueToCompressorView: UIButton!
    
    @IBAction func segueToCompressorView(_ sender: UIButton) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToCompressorView",
           let compressorVC = segue.destination as? CompressorViewController {

            // Fetch the current settings from AudioEngineManager or another shared instance
            let currentSettings = AudioEngineManager.shared.compressorSettings

            // Pass these settings to the CompressorViewController
            compressorVC.compressorSettings = currentSettings
            compressorVC.delegate = self
        }

    }
    
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {
        if let compressorVC = segue.source as? CompressorViewController,
           let settings = compressorVC.compressorSettings {
            aem?.updateCompressorSettings(settings)
            aem?.applyCompressorSettings(settings)

            compressorVC.delegate = self
        }
    }
    
    @IBAction func volumeSlider(_ sender: UISlider) {
        volumeSliderChanged()
        aem?.startAudioEngineIfNeeded()
    }
    
    @IBAction func noiseGate(_ sender: UISlider) {
        let thresholdValue = sender.value
        noiseGateNode.threshold = thresholdValue
        print("Noise Gate Slider Value: \(thresholdValue)") // Added print statement
    }
    
    @IBAction func EQ1(_ sender: UISlider) {
        let EQ1value = sender.value
        DispatchQueue.main.async {
            self.aem?.eqNode.bands[1].gain = EQ1value

        }
    }
    
    @IBAction func EQ2(_ sender: UISlider) {
        let EQ2value = sender.value
        DispatchQueue.main.async {
            self.aem?.eqNode.bands[2].gain = EQ2value

        }
    }
    
    @IBAction func EQ3(_ sender: UISlider) {
        let EQ3value = sender.value
        DispatchQueue.main.async {
            self.aem?.eqNode.bands[3].gain = EQ3value
        }
    }
    
    @IBAction func EQ4(_ sender: UISlider) {
        let EQ4value = sender.value
        DispatchQueue.main.async {
            self.aem?.eqNode.bands[4].gain = EQ4value
        }
    }
    
    @IBAction func EQ5(_ sender: UISlider) {
        let EQ5value = sender.value
        DispatchQueue.main.async {
            self.aem?.eqNode.bands[5].gain = EQ5value
        }
    }
    
    @IBAction func EQ6(_ sender: UISlider) {
        let EQ6value = sender.value
        DispatchQueue.main.async {
            self.aem?.eqNode.bands[6].gain = EQ6value
        }
    }
    
    lazy var compressorViewController: CompressorViewController = {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CompressorViewController") as? CompressorViewController else {
            fatalError("CompressorViewController not found in Main storyboard")
        }
        return vc
    }()
    
    func setUpSliderFilters(eqNode: AVAudioUnitEQ) {

        eqNode.bypass = false
        
        //set EQ filters
        eqNode.bands[0].bypass = false
        eqNode.bands[0].filterType = .highShelf
        eqNode.bands[0].frequency = 300.0
        
        eqNode.bands[1].bypass = false
        eqNode.bands[1].filterType = .parametric
        eqNode.bands[1].frequency = 700.0
        eqNode.bands[1].bandwidth = 1.5
        eqNode.bands[1].gain = 20.0
        
        eqNode.bands[2].bypass = false
        eqNode.bands[2].filterType = .parametric
        eqNode.bands[2].frequency = 1200.0
        eqNode.bands[2].bandwidth = 1.5
        eqNode.bands[2].gain = 10.0
        
        eqNode.bands[3].bypass = false
        eqNode.bands[3].filterType = .parametric
        eqNode.bands[3].frequency = 3000.0
        eqNode.bands[3].bandwidth = 1.0
        eqNode.bands[3].gain = 20.0
        
        eqNode.bands[4].bypass = false
        eqNode.bands[4].filterType = .parametric
        eqNode.bands[4].frequency = 5000.0
        eqNode.bands[4].bandwidth = 0.30
        eqNode.bands[4].gain = 1.0
        
        eqNode.bands[5].bypass = false
        eqNode.bands[5].filterType = .parametric
        eqNode.bands[5].frequency = 6000.0
        eqNode.bands[5].bandwidth = 0.30
        eqNode.bands[5].gain = 1.0
        
        eqNode.bands[7].bypass = false
        eqNode.bands[7].filterType = .lowShelf
        eqNode.bands[7].frequency = 7000
        
        eqNode.bands[8].bypass = false
        eqNode.bands[8].filterType = .parametric
        eqNode.bands[8].frequency = 4000.0
        eqNode.bands[8].bandwidth = 0.20
        eqNode.bands[8].gain = -20.0
        
        let numberOfBandsUsed = 9 // Adjust this number based on the filter
        for i in numberOfBandsUsed..<eqNode.bands.count {
            eqNode.bands[i].bypass = true
        }
    }
    
    @objc func volumeSliderChanged() {
        print("Volume Slider Value: \(String(describing: volumeSlider?.value))")
        DispatchQueue.main.async { [self] in
            if let volumeSlider = self.volumeSlider {
                let clampedVolume = min(max(0.0, volumeSlider.value), 1.0)
                aem?.mixer?.outputVolume = clampedVolume
            } else {
                print("volumeSlider is nil")
            }
        }
        aem?.startAudioEngineIfNeeded()
    }
    
    func setInitialVolumeAndStartEngine() {
        guard let initialVolume = volumeSlider?.value else { return }
        DispatchQueue.main.async { [self] in
            self.mixer?.outputVolume = initialVolume
            aem?.startAudioEngineIfNeeded()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        aem = AudioEngineManager.shared
        setupSlidersAndAudioEngine()
        
        // Register for route change notifications
        NotificationCenter.default.addObserver(self,
                                                      selector: #selector(handleAudioSessionRouteChange),
                                                      name: AVAudioSession.routeChangeNotification,
                                                      object: nil)
    }
    
    @objc func handleAudioSessionRouteChange(notification: Notification) {
        aem?.handleRouteChange(notification: notification)
    }
    
    private func setupSlidersAndAudioEngine() {
         let eqNode = aem!.eqNode
         setUpSliderFilters(eqNode: eqNode)
         aem?.setupAndStartEngine()
         setInitialVolumeAndStartEngine()
         setupSliderTransforms()
     }
    
    private func setupSliderTransforms() {
        [EQ1Slider, EQ2Slider, EQ3Slider, EQ4Slider, EQ5Slider, EQ6Slider].forEach { slider in
            slider?.transform = CGAffineTransform(rotationAngle: CGFloat.pi * -0.5)
        }
    }
}

class AudioEngineManager {
    let compressorNode = CompressorViewController.shared.getCompressorNode()
    let compressorViewController = CompressorViewController()
    
    static let shared = AudioEngineManager()
    var eqNode: AVAudioUnitEQ
    let noiseGateNode = NoiseGateNode()
    var audioEngine = AVAudioEngine()
    var mixer: AVAudioMixerNode?
    var compressorOutputPlayerNode = AVAudioPlayerNode()
    
    var compressorSettings: CompressorSettings
    
    private init() {
        compressorSettings = CompressorSettings(
            threshold: -20.0,
            attackTime: 0.0006,
            releaseTime: 0.010,
            headRoom: 1.0,
            masterGain: 5.0
        )

        eqNode = AVAudioUnitEQ(numberOfBands: 9)

        NotificationCenter.default.addObserver(self, selector: #selector(updateCompressorSettingsFromNotification(_:)), name: .compressorSettingsUpdated, object: nil)
        
        setupEngine()
    }
    
    private var nodesInitialized = false
    private var isEngineReady = false
    
    //let processedBufferPlayerNode = AVAudioPlayerNode()
    let processedBufferPlayerNode = AVAudioMixerNode()
    var commonFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)
    
    var engineSetup = false
    private var isEngineSetup = false
    
    private var bufferQueue: [AVAudioPCMBuffer] = []
    private var bufferQueueAccessQueue = DispatchQueue(label: "com.browser.viewer.Audio-Enhance.AudioEngineManager.bufferQueue")
    
    var convertedAudioBuffer: AVAudioPCMBuffer?
    
    // Keep track of connected nodes
    private var connectedNodes = Set<AVAudioNode>()
    
    public var leftChannelUpdated = false
    public var rightChannelUpdated = false


    @objc func updateCompressorSettingsFromNotification(_ notification: Notification) {
        if let settings = notification.object as? CompressorSettings {
            updateCompressorSettings(settings)
            applyCompressorSettings(settings)
        }
    }
    
    private func initializeAudioEngineManager() {
        guard !nodesInitialized else { return }
        
        // Initialize and attach nodes
        initializeAndAttachNodes()
        // Ensure all nodes are connected
        connectNodes()
        
        nodesInitialized = true
    }

    func applyCompressorSettings(_ settings: CompressorSettings) {
        let audioUnit = compressorNode.audioUnit

        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_Threshold,
                              kAudioUnitScope_Global, 0,
                              settings.threshold, 0)

        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_AttackTime,
                              kAudioUnitScope_Global, 0,
                              settings.attackTime, 0)

        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_ReleaseTime,
                              kAudioUnitScope_Global, 0,
                              settings.releaseTime, 0)

        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_HeadRoom,
                              kAudioUnitScope_Global, 0,
                              settings.headRoom, 0)

        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_OverallGain,
                              kAudioUnitScope_Global, 0,
                              settings.masterGain, 0)
    }
    
    func updateCompressorSettings(_ settings: CompressorSettings) {
        // Update the compressorSettings property
            self.compressorSettings = settings
        // Apply these settings to the compressor node
        applyCompressorSettings(settings)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            if session.currentRoute.outputs.contains(where: { $0.portType == .bluetoothA2DP }) {
                print("Bluetooth A2DP device connected.")
                // Code to handle Bluetooth device connection
            }
        case .oldDeviceUnavailable:
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
               previousRoute.outputs.contains(where: { $0.portType == .bluetoothA2DP }) {
                print("Bluetooth A2DP device disconnected.")
                // Code to handle Bluetooth device disconnection
            }
        default: break
        }
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category, mode, and options
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            
            // Set the preferred input if available
            if let availableInputs = audioSession.availableInputs, let preferredInput = availableInputs.first(where: { $0.portType == .builtInMic || $0.portType != .builtInMic }) {
                try audioSession.setPreferredInput(preferredInput)
            }

            // Set the preferred sample rate
            try audioSession.setPreferredSampleRate(48000)
            
            // Activate the audio session
            try audioSession.setActive(true)
            print("Audio session activated successfully with preferred input: \(audioSession.preferredInput?.portName ?? "Default")")
            isEngineReady = true
        } catch {
            print("Failed to setup and activate audio session: \(error)")
            isEngineReady = false
        }
    }

    // Mono to stereo conversion function
    func convertMonoToStereo(monoBuffer: AVAudioPCMBuffer, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // Create a stereo buffer
        guard let stereoBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: monoBuffer.frameCapacity * 2) else {
            return nil
        }
        
        // Copy mono data to both left and right channels
        if let monoData = monoBuffer.floatChannelData?[0], let leftChannel = stereoBuffer.floatChannelData?[0], let rightChannel = stereoBuffer.floatChannelData?[1] {
            for frame in 0..<monoBuffer.frameLength {
                leftChannel[Int(frame)] = monoData[Int(frame)]
                rightChannel[Int(frame)] = monoData[Int(frame)]
            }
        }
        
        stereoBuffer.frameLength = monoBuffer.frameLength
        return stereoBuffer
    }
    
    func ensureStereo(buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> AVAudioPCMBuffer {
        if buffer.format.channelCount < 2 {
            // If the buffer is mono, convert it to stereo using the provided format
            return convertMonoToStereo(monoBuffer: buffer, format: format)!
        }
        // If the buffer is already stereo, return it as is
        return buffer
    }
    
    func appendBufferToQueue(_ buffer: AVAudioPCMBuffer) {
        bufferQueueAccessQueue.async {
            self.bufferQueue.append(buffer)
            print("Buffer appended. Queue Size: \(self.bufferQueue.count)")
        }
    }
    
    // Thread-safe method to retrieve and remove the first buffer from the queue
    func dequeueBuffer() -> AVAudioPCMBuffer? {
        return bufferQueueAccessQueue.sync {
            if !self.bufferQueue.isEmpty {
                return self.bufferQueue.removeFirst()
            } else {
                return nil
            }
        }
    }
    
    func checkAndLogNodeFormats() {
        // Assuming bufferQueue is accessible and contains the buffers being processed
        guard let currentBuffer = bufferQueue.first else {
            print("Buffer queue is empty, no format to check.")
            return
        }
        
        let bufferFormat = currentBuffer.format
        let mixerFormat = mixer?.outputFormat(forBus: 0)
        let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
        
        // Check and log the format of the mixer node
        if mixerFormat != bufferFormat {
            print("Format mismatch: Mixer format \(String(describing: mixerFormat)) does not match buffer format \(bufferFormat)")
        } else {
            print("Mixer format matches the buffer format.")
        }
        
        // Check and log the format of the output node
        if outputFormat != bufferFormat {
            print("Format mismatch: Output format \(outputFormat) does not match buffer format \(bufferFormat)")
        } else {
            print("Output format matches the buffer format.")
        }
        
        // Schedule the format check to run periodically
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkAndLogNodeFormats()
        }
    }
    
    let downsamplingMixer = AVAudioMixerNode()
    private func setupEngine() {
        if !isEngineReady { setupAudioSession() }
        audioEngine.reset()
        initializeAndAttachNodes()
        // Correctly call connectNodes on the current instance
        connectNodes(withFormatConversion: true)
        isEngineSetup = true
    }
    
    let formatConversionMixer = AVAudioMixerNode()
    let desiredOutputFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)


    func updateCompressorThreshold(_ threshold: Float) {
        let audioUnit = compressorNode.audioUnit
        AudioUnitSetParameter(audioUnit, kDynamicsProcessorParam_Threshold, kAudioUnitScope_Global, 0, threshold, 0)
    }
    
    func updateCompressorAttackTime(_ attackTime: Float) {
        let audioUnit = compressorNode.audioUnit
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_AttackTime,
                              kAudioUnitScope_Global, 0,
                              attackTime, 0)
    }
    
    func updateCompressorReleaseTime(_ releaseTime: Float) {
        let audioUnit =         compressorNode.audioUnit
        AudioUnitSetParameter(audioUnit,
                                                      kDynamicsProcessorParam_ReleaseTime,
                                                      kAudioUnitScope_Global, 0,
                                                      releaseTime, 0)

    }
    
    func updateCompressorHeadRoom(_ headRoom: Float) {
        let audioUnit =         compressorNode.audioUnit
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_HeadRoom,
                              kAudioUnitScope_Global, 0,
                              headRoom, 0)
    }
    
    func updateCompressorMasterGain(_ masterGain: Float) {
        let audioUnit =         compressorNode.audioUnit
        AudioUnitSetParameter(audioUnit,
                              kDynamicsProcessorParam_OverallGain,
                              kAudioUnitScope_Global, 0,
                              masterGain, 0)
    }
    
    private func initializeAndAttachNodes() {
        // Ensure the audio engine is ready before initializing nodes
        guard isEngineReady else {
            print("Audio engine is not ready for node initialization.")
            return
        }
        
        // Create or ensure the mixer node is available
        if mixer == nil {
            mixer = AVAudioMixerNode()
            audioEngine.attach(mixer!)
            print("Mixer node created and attached.")
        }
  

        if !audioEngine.attachedNodes.contains(noiseGateNode) {
            audioEngine.attach(downsamplingMixer)
            print("downsamplingMixer Node attached.")
        }
        if !audioEngine.attachedNodes.contains(noiseGateNode) {
            audioEngine.attach(noiseGateNode)
            print("Noise Gate Node attached.")
        }
        
        if !audioEngine.attachedNodes.contains(eqNode) {
            audioEngine.attach(eqNode)
            print("EQ Node attached.")
        }

        if !audioEngine.attachedNodes.contains(compressorNode) {
            audioEngine.attach(compressorNode)
            print("Compressor Node attached.")
        }
        
        if !audioEngine.attachedNodes.contains(compressorOutputPlayerNode) {
            audioEngine.attach(compressorOutputPlayerNode)
            print("Compressor Output Player Node attached.")
        }
        

        audioEngine.attach(formatConversionMixer)

        
        // Mark nodes as initialized to prevent re-initialization
        nodesInitialized = true
    }
    
    private func connectNodes(withFormatConversion formatConversionNeeded: Bool = false) {
        guard isEngineReady else {
            print("Audio engine is not ready. Cannot connect nodes.")
            return
        }

//        let sampleRate: Double = 44100 // Replace with your desired sample rate
//        let duration: Double = 0.05 // Buffer duration in seconds (e.g., 0.1 seconds)
//        let numberOfChannels: UInt32 = 2 // Mono = 1, Stereo = 2
//
//        let bufferSize: AVAudioFrameCount = AVAudioFrameCount(sampleRate * duration * Double(numberOfChannels))
      
        let input = audioEngine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)
        let downsampledFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)

        // Connect input to Downsampling mixer
        audioEngine.connect(input, to: downsamplingMixer, format: inputFormat)
        audioEngine.connect(downsamplingMixer, to:eqNode, format: downsampledFormat)
        audioEngine.connect(eqNode, to: compressorNode, format: downsampledFormat)
        audioEngine.connect(compressorNode, to: noiseGateNode, format: downsampledFormat)
        audioEngine.connect(noiseGateNode, to: mixer!, format: downsampledFormat)

        print("eqNode Node Output Format: \(eqNode.outputFormat(forBus: 0))")

        // Connect EQ node to Compressor node
        print("compressorNode input Format: \(compressorNode.inputFormat(forBus: 0))")

  
    //let compressorOutputNodeFormat = compressorOutputPlayerNode.outputFormat(forBus: 0)
      
         //If format conversion is needed
        if formatConversionNeeded {

        // Connect the mixer to the format conversion mixer
        audioEngine.connect(mixer!, to: formatConversionMixer, format: mixer!.outputFormat(forBus: 0))

        // Connect the format conversion mixer to the audio engine's output node
        audioEngine.connect(formatConversionMixer, to: audioEngine.outputNode, format: desiredOutputFormat)
        print("Connected Format Conversion Mixer to Audio Engine Output Node with format: \(String(describing: desiredOutputFormat))")
        } else {
        // Connect the mixer directly to the output node if no format conversion is needed
        audioEngine.connect(mixer!, to: audioEngine.outputNode, format: mixer!.outputFormat(forBus: 0))
        print("Connected Mixer to Audio Engine Output Node. Mixer output format: \(mixer!.outputFormat(forBus: 0)), Output Node input format: \(audioEngine.outputNode.inputFormat(forBus: 0))")
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Error starting audioEngine: \(error.localizedDescription)")
        }
    }


    
    // utility function to print the connection status of a node
    private func printNodeConnectionStatus(node: AVAudioNode) {
        guard audioEngine.attachedNodes.contains(node) else {
            print("Node \(node) is not attached to the audio engine.")
            return
        }
        
        let outputConnections = audioEngine.outputConnectionPoints(for: node, outputBus: 0)
        if !outputConnections.isEmpty {
            print("Node \(node) has output connections.")
        } else {
            print("Warning: Node \(node) does not have output connections.")
        }
        
        // Additional check for isPlaying if the node is an AVAudioPlayerNode
        if let playerNode = node as? AVAudioPlayerNode {
            print("Node \(node) isPlaying: \(playerNode.isPlaying)")
        }
    }
    
    func isConnected(node: AVAudioNode) -> Bool {
        // Check if the node is in the connectedNodes set
        let isNodeInConnectedNodes = connectedNodes.contains(node)
        
        // Check if the node has output connections in the audio engine
        let hasOutputConnections = !audioEngine.outputConnectionPoints(for: node, outputBus: 0).isEmpty
        
        // Return true if both conditions are met
        return isNodeInConnectedNodes && hasOutputConnections
    }

    private func startPlayerNodeIfNeeded(_ node: AVAudioPlayerNode) {
        printNodeConnectionStatus(node: processedBufferPlayerNode)
        printNodeConnectionStatus(node: compressorOutputPlayerNode)
        print("Checking connection for \(node) before starting.")
        guard audioEngine.isRunning, isConnected(node: node), !node.isPlaying else {
            print("Node \(node) is not connected or already playing.")
            return
        }
        node.play()
        print("\(node) started playing.")
    }
    
    private func startAudioEngine() {
        do {
            try audioEngine.start()
            compressorOutputPlayerNode.play()
            compressorOutputPlayerNode.play()  // Start the player nodes
            print("Audio engine and player node started successfully.")
        } catch {
            print("Error starting audio engine or player node: \(error)")
        }
    }
    
    func scheduleBufferForPlayback(_ buffer: AVAudioPCMBuffer) {
        print("Scheduling buffer for playback. Frame length: \(buffer.frameLength)")

        // Check if the buffer has a valid frame length
        if buffer.frameLength > 0 {
            if !compressorOutputPlayerNode.isPlaying {
                compressorOutputPlayerNode.play()
                print("Starting processedBufferPlayerNode")
            }

            // Schedule the buffer
            compressorOutputPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            print("Buffer scheduled on processedBufferPlayerNode")
        } else {
            print("Received an empty buffer") // Diagnostic print
        }
    }
    
    func playBuffer(_ buffer: AVAudioPCMBuffer, on playerNode: AVAudioPlayerNode) {
        let isConnected = self.isConnected(node: playerNode)
        print("Preparing to play buffer on \(playerNode). isConnected: \(isConnected)")

        guard isConnected else {
            print("Cannot play buffer. \(playerNode) is not connected.")
            return
        }
        
        // Ensure the audio engine is running
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
                print("Audio engine started")
            } catch {
                print("Error starting audio engine: \(error)")
            }
        }
        
        // Ensure the player node is playing
        if !playerNode.isPlaying {
            playerNode.play()
            print("Starting \(playerNode)")
        }
        
        // Schedule the buffer
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        print("Buffer scheduled on \(playerNode)")
    }
    
    private func configureTapOnCompressorNode() {
        guard audioEngine.attachedNodes.contains(compressorNode) else {
            print("Error: Compressor node is not attached to the audio engine.")
            return
        }

        compressorNode.removeTap(onBus: 0)

        let compressorNodeOutputFormat = compressorNode.outputFormat(forBus: 0)
        compressorNode.installTap(onBus: 0, bufferSize: 1024, format: compressorNodeOutputFormat) { [weak self] (buffer, time) in
            print("Tap callback executed with buffer of size: \(buffer.frameLength)") // Diagnostic print

            // Check if the buffer has a valid frame length
            if buffer.frameLength > 0 {
                self?.playBuffer(buffer, on: self!.compressorOutputPlayerNode)
                print("Buffer scheduled on compressorOutputPlayerNode") // Diagnostic print
            } else {
                print("Received an empty buffer") // Diagnostic print
            }
        }
    }
    
    // Helper function to process and prepare buffer (e.g., convert mono to stereo, apply noise gate)
    func processAndPrepareBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let bufferToProcess = ensureStereo(buffer: buffer, format: format)
        noiseGateNode.applyNoiseGate(to: bufferToProcess)
        return bufferToProcess
    }
    
    func startAudioEngineIfNeeded() {
        guard !audioEngine.isRunning else { return }
        do {
            try audioEngine.start()
            startPlayerNodesIfNeeded()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    private func startPlayerNodesIfNeeded() {
        //startPlayerNodeIfNeeded(processedBufferPlayerNode)
        startPlayerNodeIfNeeded(compressorOutputPlayerNode)
    }
    
    private func startAudioEngineIfNotRunning() {
        guard !audioEngine.isRunning else {
            print("Audio engine is already running.")
            return
        }

        do {
            try audioEngine.start()
            print("Audio engine started successfully.")
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func setupAndStartEngine() {
        if !isEngineSetup {
            setupEngine()
            connectNodes() // Ensure all nodes are connected
            startAudioEngineIfNotRunning() // Start the audio engine if it's not already running
        }
    }
    
    func processAndPlayBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        guard audioEngine.isRunning else {
            print("Cannot process and play buffer. Audio engine is not running.")
            return
        }
        // Convert mono to stereo if necessary
        let bufferToProcess = ensureStereo(buffer: buffer, format: format)
        
        // Apply noise gate to the buffer
        noiseGateNode.applyNoiseGate(to: bufferToProcess)
        
        // Play the buffer on the processedBufferPlayerNode
        playBuffer(bufferToProcess, on: compressorOutputPlayerNode)
    }
    
    func connect(_ node: AVAudioNode, to anotherNode: AVAudioNode, format: AVAudioFormat?) {
        audioEngine.connect(node, to: anotherNode, format: format)
        connectedNodes.insert(node)
        print("Connected \(node) to \(anotherNode). Format: \(String(describing: format))")
        
    }
    
    // Disconnect a node
    func disconnectNodeInput(_ node: AVAudioNode) {
        if connectedNodes.contains(node) {
            audioEngine.disconnectNodeInput(node)
            connectedNodes.remove(node)
        }
    }
    
    func isNodeConnected(_ node: AVAudioNode) -> Bool {
        return connectedNodes.contains(node)
    }
}


class NoiseGateNode: AVAudioMixerNode {
    
    var threshold: Float = -70.0
    
    func applyNoiseGate(to buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        for channel in 0..<channelCount {
            for frame in 0..<frameLength {
                let sampleValue = channelData[channel][frame]
                // Print the sampleValue, maybe just for the first few frames
                if frame < 10 {
                    //print("Sample Value: \(sampleValue)")
                }
                
                let dBValue = 20 * log10(abs(sampleValue))
                channelData[channel][frame] = dBValue < self.threshold ? 0 : sampleValue

            }
            print("Noise gate applied")
        }
    }
}

extension ViewController: CompressorViewControllerDelegate {
    func didUpdateCompressorSettings(_ settings: CompressorSettings) {
        // Use settings here
    }
}
