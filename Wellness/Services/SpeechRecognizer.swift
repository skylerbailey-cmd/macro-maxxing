//
//  SpeechRecognizer.swift
//  Wellness
//

import Speech
import AVFoundation

@Observable final class SpeechRecognizer {

    enum Status: Equatable {
        case idle
        case requestingPermission
        case recording
        case done
        case error(String)
    }

    var transcript: String = ""
    var status: Status = .idle

    private var recognizer: SFSpeechRecognizer?
    private var request:    SFSpeechAudioBufferRecognitionRequest?
    private var task:       SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Public API

    func start() {
        status = .requestingPermission
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self else { return }
                guard authStatus == .authorized else {
                    self.status = .error("Speech recognition permission denied. Enable it in Settings.")
                    return
                }
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if granted { self.beginRecording() }
                        else { self.status = .error("Microphone permission denied. Enable it in Settings.") }
                    }
                }
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        request = nil
        task    = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if status == .recording { status = .done }
    }

    func reset() {
        stop()
        transcript = ""
        status     = .idle
    }

    // MARK: - Private

    private func beginRecording() {
        recognizer = SFSpeechRecognizer(locale: Locale.current)
        guard let recognizer, recognizer.isAvailable else {
            status = .error("Speech recognition is not available right now.")
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            status = .error("Could not start audio session.")
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format    = inputNode.outputFormat(forBus: 0)

        // Guard against invalid format (0 sample rate / 0 channels) which crashes installTap
        guard format.sampleRate > 0, format.channelCount > 0 else {
            status = .error("Microphone unavailable.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            status = .error("Could not start audio engine.")
            return
        }

        transcript = ""
        status     = .recording

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stop()
                }
            }
        }
    }
}
