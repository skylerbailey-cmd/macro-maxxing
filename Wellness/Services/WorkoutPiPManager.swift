//
//  WorkoutPiPManager.swift
//  Wellness
//
//  Manages an AVPictureInPictureController that renders the live workout
//  timer into an AVSampleBufferDisplayLayer. The PiP window shows the
//  elapsed time and a "Tap to open app" hint — no cancel button, so the
//  user must return to the app to cancel the workout.
//

import AVKit
import UIKit
import CoreMedia
import CoreVideo

final class WorkoutPiPManager: NSObject {

    static let shared = WorkoutPiPManager()

    // The layer MUST be embedded in the view hierarchy for PiP to work.
    // PiPLayerView does this with a 1×1 hidden UIView.
    let displayLayer = AVSampleBufferDisplayLayer()

    private var pipController: AVPictureInPictureController?
    private var renderTimer:   Timer?

    // Current timer state — kept in sync by ContentView
    var startTime:           Date?
    var pausedAt:            Date?
    var totalPausedSeconds:  Double = 0

    private override init() {
        super.init()
        displayLayer.backgroundColor = CGColor(red: 0.07, green: 0.05, blue: 0.14, alpha: 1)
        displayLayer.videoGravity    = .resizeAspect
        setupController()
    }

    // MARK: - Setup

    private func setupController() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        let source = AVPictureInPictureControllerContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        pipController = AVPictureInPictureController(contentSource: source)
        pipController?.delegate = self
        // Do NOT set canStartPictureInPictureAutomaticallyFromInline — we
        // start manually via scenePhase so we control exactly when it appears.
    }

    // MARK: - Public API

    func update(startTime: Date?, pausedAt: Date?, totalPausedSeconds: Double) {
        self.startTime          = startTime
        self.pausedAt           = pausedAt
        self.totalPausedSeconds = totalPausedSeconds
    }

    /// Call when the app moves to the background with an active workout.
    func startPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported(),
              startTime != nil else { return }
        startRenderLoop()
        pipController?.startPictureInPicture()
    }

    /// Call when the app returns to the foreground.
    func stopPiP() {
        pipController?.stopPictureInPicture()
        stopRenderLoop()
    }

    // MARK: - Render loop

    private func startRenderLoop() {
        renderTimer?.invalidate()
        renderFrame()
        renderTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.renderFrame()
        }
    }

    private func stopRenderLoop() {
        renderTimer?.invalidate()
        renderTimer = nil
    }

    // MARK: - Frame rendering

    private func renderFrame() {
        guard let start = startTime else { return }

        let end     = pausedAt ?? Date()
        let elapsed = max(0, end.timeIntervalSince(start) - totalPausedSeconds)
        let paused  = pausedAt != nil

        let size     = CGSize(width: 320, height: 180)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext

            // Background
            cgCtx.setFillColor(CGColor(red: 0.07, green: 0.05, blue: 0.14, alpha: 1))
            cgCtx.fill(CGRect(origin: .zero, size: size))

            // Top accent bar
            cgCtx.setFillColor(CGColor(red: 0.30, green: 0.90, blue: 0.55, alpha: paused ? 0.4 : 0.9))
            cgCtx.fill(CGRect(x: 0, y: 0, width: size.width, height: 3))

            // Elapsed time
            let timerStr = NSAttributedString(string: formatElapsed(elapsed), attributes: [
                .font:            UIFont.monospacedSystemFont(ofSize: 52, weight: .black),
                .foregroundColor: UIColor.white
            ])
            let timerSize = timerStr.size()
            timerStr.draw(at: CGPoint(x: (size.width - timerSize.width) / 2, y: 28))

            // Status line
            let statusText  = paused ? "Paused" : "Workout in Progress"
            let statusColor: UIColor = paused
                ? .orange
                : UIColor(red: 0.30, green: 0.90, blue: 0.55, alpha: 1)
            let statusStr = NSAttributedString(string: statusText, attributes: [
                .font:            UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: statusColor
            ])
            let statusSize = statusStr.size()
            statusStr.draw(at: CGPoint(x: (size.width - statusSize.width) / 2, y: 122))

            // Hint
            let hintStr = NSAttributedString(string: "Tap to open app", attributes: [
                .font:            UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.white.withAlphaComponent(0.35)
            ])
            let hintSize = hintStr.size()
            hintStr.draw(at: CGPoint(x: (size.width - hintSize.width) / 2, y: 152))
        }

        enqueue(image: image)
    }

    private func enqueue(image: UIImage) {
        guard let pixelBuffer = image.toPixelBuffer() else { return }

        var timing = CMSampleTimingInfo(
            duration:               CMTime(value: 1, timescale: 1),
            presentationTimeStamp:  CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp:        .invalid
        )
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDesc)
        guard let fd = formatDesc else { return }

        var sb: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer,
            dataReady: true, makeDataReadyCallback: nil, refcon: nil,
            formatDescription: fd, sampleTiming: &timing, sampleBufferOut: &sb)
        guard let sampleBuffer = sb else { return }

        if displayLayer.status == .failed { displayLayer.flush() }
        displayLayer.enqueue(sampleBuffer)
    }

    // MARK: - Helpers

    private func formatElapsed(_ seconds: Double) -> String {
        let s = Int(seconds), h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }
}

// MARK: - Playback delegate (required, no-ops for a static timer)

extension WorkoutPiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(
        _ c: AVPictureInPictureController, setPlaying playing: Bool) {}
    func pictureInPictureControllerTimeRangeForPlayback(
        _ c: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }
    func pictureInPictureControllerIsPlaybackPaused(
        _ c: AVPictureInPictureController) -> Bool { false }
    func pictureInPictureController(
        _ c: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    func pictureInPictureController(
        _ c: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion handler: @escaping () -> Void) { handler() }
}

// MARK: - PiP delegate

extension WorkoutPiPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureController(
        _ c: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error) {
        print("[WorkoutPiP] Failed to start: \(error.localizedDescription)")
    }
}

// MARK: - UIImage → CVPixelBuffer

private extension UIImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        let attrs: CFDictionary = [
            kCVPixelBufferCGImageCompatibilityKey:        kCFBooleanTrue as Any,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as Any,
            kCVPixelBufferIOSurfacePropertiesKey:          [:] as CFDictionary
        ] as CFDictionary
        var pb: CVPixelBuffer?
        guard CVPixelBufferCreate(kCFAllocatorDefault,
                                  Int(size.width), Int(size.height),
                                  kCVPixelFormatType_32BGRA, attrs, &pb) == kCVReturnSuccess,
              let buffer = pb else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let ctx = CGContext(
            data:             CVPixelBufferGetBaseAddress(buffer),
            width:            Int(size.width),
            height:           Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow:      CVPixelBufferGetBytesPerRow(buffer),
            space:            CGColorSpaceCreateDeviceRGB(),
            bitmapInfo:       CGBitmapInfo.byteOrder32Little.rawValue |
                              CGImageAlphaInfo.premultipliedFirst.rawValue)
        guard let c = ctx, let cg = cgImage else { return nil }
        c.draw(cg, in: CGRect(origin: .zero, size: size))
        return buffer
    }
}
