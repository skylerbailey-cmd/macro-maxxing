//
//  CropCircleView.swift
//  Wellness
//
//  Full-screen circular crop editor.
//  The user pinches to zoom and drags to reposition the image inside the circle.
//  Tapping Save renders the visible crop region to a 400×400 UIImage.
//

import SwiftUI

struct CropCircleView: View {
    let sourceImage: UIImage
    let onSave:      (UIImage) -> Void
    let onCancel:    () -> Void

    @State private var scale:  CGFloat = 1.0
    @State private var offset: CGSize  = .zero

    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureDrag:  CGSize  = .zero

    private let cropDiameter: CGFloat = 280
    private let gold = Color(red: 1.00, green: 0.80, blue: 0.20)

    // Base display size so the image fills the crop circle at scale = 1
    private var baseSize: CGSize {
        let w = sourceImage.size.width
        let h = sourceImage.size.height
        guard w > 0, h > 0 else { return CGSize(width: cropDiameter, height: cropDiameter) }
        let s = max(cropDiameter / w, cropDiameter / h)
        return CGSize(width: w * s, height: h * s)
    }

    private var liveScale:  CGFloat { max(1.0, scale * gestureScale) }
    private var liveOffset: CGSize {
        CGSize(width:  offset.width  + gestureDrag.width,
               height: offset.height + gestureDrag.height)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Image layer
                Image(uiImage: sourceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: baseSize.width, height: baseSize.height)
                    .scaleEffect(liveScale)
                    .offset(liveOffset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .updating($gestureScale) { v, state, _ in state = v }
                                .onEnded { v in
                                    let next = max(1.0, scale * v)
                                    scale  = next
                                    offset = clampOffset(offset, scale: next)
                                },
                            DragGesture()
                                .updating($gestureDrag) { v, state, _ in state = v.translation }
                                .onEnded { v in
                                    offset = clampOffset(
                                        CGSize(width:  offset.width  + v.translation.width,
                                               height: offset.height + v.translation.height),
                                        scale: scale
                                    )
                                }
                        )
                    )

                // Dimmed overlay with a circular hole using even-odd fill
                GeometryReader { inner in
                    Path { p in
                        p.addRect(CGRect(origin: .zero, size: inner.size))
                        p.addEllipse(in: CGRect(
                            x: (inner.size.width  - cropDiameter) / 2,
                            y: (inner.size.height - cropDiameter) / 2,
                            width:  cropDiameter,
                            height: cropDiameter
                        ))
                    }
                    .fill(.black.opacity(0.60), style: FillStyle(eoFill: true))
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // Circle border
                Circle()
                    .strokeBorder(.white.opacity(0.75), lineWidth: 1.5)
                    .frame(width: cropDiameter, height: cropDiameter)
                    .allowsHitTesting(false)

                // Cancel / Save buttons
                VStack {
                    HStack {
                        Button("Cancel") { onCancel() }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(16)
                        Spacer()
                        Button {
                            onSave(renderCrop(screenSize: geo.size))
                        } label: {
                            Text("Save")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(gold)
                        }
                        .padding(16)
                    }
                    Spacer()
                    Text("Pinch to zoom  ·  Drag to reposition")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                        .padding(.bottom, 48)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Offset clamping
    // Keeps the image fully covering the crop circle at all times.

    private func clampOffset(_ proposed: CGSize, scale: CGFloat) -> CGSize {
        let dispW = baseSize.width  * scale
        let dispH = baseSize.height * scale
        let maxX  = max(0, (dispW - cropDiameter) / 2)
        let maxY  = max(0, (dispH - cropDiameter) / 2)
        return CGSize(
            width:  min(maxX, max(-maxX, proposed.width)),
            height: min(maxY, max(-maxY, proposed.height))
        )
    }

    // MARK: - Crop rendering

    private func renderCrop(screenSize: CGSize) -> UIImage {
        let dispW = baseSize.width  * scale
        let dispH = baseSize.height * scale

        // Image center in screen coordinates (after offset)
        let imgCX = screenSize.width  / 2 + offset.width
        let imgCY = screenSize.height / 2 + offset.height

        // Top-left of image display rect in screen space
        let imgLeft = imgCX - dispW / 2
        let imgTop  = imgCY - dispH / 2

        // Top-left of the crop circle in screen space
        let cropLeft = (screenSize.width  - cropDiameter) / 2
        let cropTop  = (screenSize.height - cropDiameter) / 2

        // Map the crop circle rect into the source image's coordinate space
        let srcX = (cropLeft - imgLeft) / dispW * sourceImage.size.width
        let srcY = (cropTop  - imgTop)  / dispH * sourceImage.size.height
        let srcW = cropDiameter         / dispW * sourceImage.size.width
        let srcH = cropDiameter         / dispH * sourceImage.size.height

        // Render the cropped region at a fixed 400×400 output size
        let outputSize = CGSize(width: 400, height: 400)
        let renderer   = UIGraphicsImageRenderer(size: outputSize)
        return renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: outputSize)).addClip()
            // Position the full image so that srcRect maps exactly onto outputSize
            let scaleX = outputSize.width  / srcW
            let scaleY = outputSize.height / srcH
            sourceImage.draw(in: CGRect(
                x:      -srcX * scaleX,
                y:      -srcY * scaleY,
                width:  sourceImage.size.width  * scaleX,
                height: sourceImage.size.height * scaleY
            ))
        }
    }
}
