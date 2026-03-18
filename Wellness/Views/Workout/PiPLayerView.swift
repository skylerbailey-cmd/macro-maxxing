//
//  PiPLayerView.swift
//  Wellness
//
//  A 1×1 hidden UIView that hosts WorkoutPiPManager's AVSampleBufferDisplayLayer.
//  AVPictureInPictureController requires its layer to be in the live view
//  hierarchy — this satisfies that requirement without occupying any visible space.
//

import SwiftUI
import AVKit

struct PiPLayerView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view  = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        view.isHidden = true
        let layer = WorkoutPiPManager.shared.displayLayer
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
