//
//  CropImageView.swift
//  Wellness
//
//  Full-screen interactive crop tool.
//  • Drag corner handles to resize both dimensions simultaneously.
//  • Drag edge handles to resize one dimension.
//  • Drag the image (anywhere outside handles) to reposition it.
//  • Pinch to zoom the image within the crop frame.
//  • Image always fills the crop frame — no black gaps.
//  • Releasing a handle snaps the image to fill the new frame (spring animation).
//

import SwiftUI

struct CropImageView: View {

    let image:    UIImage
    let onCrop:   (UIImage) -> Void
    let onCancel: () -> Void

    // MARK: - Crop frame  (view coordinate space, origin = view top-left)
    @State private var cropRect: CGRect = .zero

    // MARK: - Image transform  (offset from view center)
    @State private var imageScale:  CGFloat = 1.0
    @State private var imageOffset: CGSize  = .zero
    @GestureState private var pinchDelta: CGFloat = 1.0   // live pinch multiplier

    // MARK: - Single-gesture state
    @State private var dragMode: DragMode? = nil
    @State private var cropAtDragStart:   CGRect = .zero
    @State private var offsetAtDragStart: CGSize  = .zero

    // MARK: - View size (captured from GeometryReader)
    @State private var viewSize: CGSize = .zero
    @State private var isInitialized = false

    private let minCropDim: CGFloat = 80
    private let handleHitR: CGFloat = 30   // touch radius for handle detection

    // One gesture either drags a crop handle or pans the image.
    enum DragMode: Equatable {
        case handle(HandleID)
        case pan
    }

    enum HandleID: Equatable {
        case tl, tr, bl, br           // corners
        case top, bottom, left, right // edges
    }

    // MARK: - Image base size (scaledToFit inside available area)

    private func baseSize(for v: CGSize) -> CGSize {
        let avW = v.width  - 48    // side padding for handles
        let avH = v.height - 200   // top + bottom toolbar clearance
        guard avW > 0, avH > 0 else { return CGSize(width: 200, height: 200) }
        let a = image.size.width / image.size.height
        return a > avW / avH
            ? CGSize(width: avW,      height: avW / a)
            : CGSize(width: avH * a,  height: avH)
    }

    // Live display scale (imageScale × in-flight pinch delta)
    private var liveScale: CGFloat { imageScale * pinchDelta }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    imageLayer(v: geo.size)
                    overlayLayer
                    handleLayer
                }
                .onAppear {
                    viewSize = geo.size
                    if !isInitialized, geo.size.width > 0, geo.size.height > 0 {
                        isInitialized = true
                        setupInitialState(in: geo.size)
                    }
                }
                .onChange(of: geo.size) { _, s in
                    viewSize = s
                    guard !isInitialized, s.width > 0, s.height > 0 else { return }
                    isInitialized = true
                    setupInitialState(in: s)
                }
                // Single drag — decides handle vs pan based on start position
                .gesture(mainDragGesture)
                // Pinch zoom (two-finger — never conflicts with one-finger drag)
                .simultaneousGesture(pinchGesture)
            }

            toolbarLayer
        }
    }

    // MARK: - Image

    @ViewBuilder
    private func imageLayer(v: CGSize) -> some View {
        let bs = baseSize(for: v)
        Image(uiImage: image)
            .resizable()
            .frame(width:  bs.width  * liveScale,
                   height: bs.height * liveScale)
            .offset(imageOffset)
    }

    // MARK: - Overlay (dark surround + border + grid)
    //  Uses Canvas to draw four dark rectangles around the crop area —
    //  simpler and more reliable than compositingGroup / destinationOut.

    private var overlayLayer: some View {
        Canvas { ctx, size in
            let r = cropRect

            // Four dark bands
            let top    = CGRect(x: 0,      y: 0,      width: size.width,        height: max(0, r.minY))
            let bottom = CGRect(x: 0,      y: r.maxY, width: size.width,        height: max(0, size.height - r.maxY))
            let left   = CGRect(x: 0,      y: r.minY, width: max(0, r.minX),    height: r.height)
            let right  = CGRect(x: r.maxX, y: r.minY, width: max(0, size.width - r.maxX), height: r.height)

            for band in [top, bottom, left, right] {
                ctx.fill(Path(band), with: .color(.black.opacity(0.60)))
            }

            // Crop frame border
            ctx.stroke(Path(r), with: .color(.white.opacity(0.75)), lineWidth: 1.5)

            // Rule-of-thirds grid
            var grid = Path()
            grid.move(to: CGPoint(x: r.minX + r.width / 3,     y: r.minY))
            grid.addLine(to: CGPoint(x: r.minX + r.width / 3,     y: r.maxY))
            grid.move(to: CGPoint(x: r.minX + r.width * 2 / 3, y: r.minY))
            grid.addLine(to: CGPoint(x: r.minX + r.width * 2 / 3, y: r.maxY))
            grid.move(to: CGPoint(x: r.minX, y: r.minY + r.height / 3))
            grid.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height / 3))
            grid.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 2 / 3))
            grid.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 2 / 3))
            ctx.stroke(grid, with: .color(.white.opacity(0.20)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Handle visuals  (drawn in Canvas — no interactive views needed)

    private var handleLayer: some View {
        Canvas { ctx, _ in
            let r   = cropRect
            let len: CGFloat = 22
            let t:   CGFloat = 3

            // Corner L-handles
            let corners: [(CGPoint, Bool, Bool)] = [
                (CGPoint(x: r.minX, y: r.minY), false, false),
                (CGPoint(x: r.maxX, y: r.minY), true,  false),
                (CGPoint(x: r.minX, y: r.maxY), false, true),
                (CGPoint(x: r.maxX, y: r.maxY), true,  true),
            ]
            for (pt, fH, fV) in corners {
                let hBar = CGRect(x: fH ? pt.x - len : pt.x, y: pt.y - t / 2, width: len, height: t)
                let vBar = CGRect(x: pt.x - t / 2, y: fV ? pt.y - len : pt.y, width: t, height: len)
                ctx.fill(Path(hBar), with: .color(.white))
                ctx.fill(Path(vBar), with: .color(.white))
            }

            // Edge bar-handles
            let edges: [(CGPoint, Bool)] = [
                (CGPoint(x: r.midX, y: r.minY), true),
                (CGPoint(x: r.midX, y: r.maxY), true),
                (CGPoint(x: r.minX, y: r.midY), false),
                (CGPoint(x: r.maxX, y: r.midY), false),
            ]
            for (pt, isH) in edges {
                let ew: CGFloat = isH ? 28 : t
                let eh: CGFloat = isH ? t : 28
                let bar = CGRect(x: pt.x - ew / 2, y: pt.y - eh / 2, width: ew, height: eh)
                let path = RoundedRectangle(cornerRadius: 2).path(in: bar)
                ctx.fill(path, with: .color(.white))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Single unified drag gesture

    private var mainDragGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { val in
                // On first call: record starting state and decide what's being dragged.
                if dragMode == nil {
                    cropAtDragStart   = cropRect
                    offsetAtDragStart = imageOffset
                    dragMode = nearestHandle(to: val.startLocation)
                        .map { .handle($0) } ?? .pan
                }

                let d = val.translation

                switch dragMode {
                case .handle(let id):
                    cropRect = adjustedCropRect(handle: id, delta: d)
                    // Keep image covering the (potentially larger) new crop frame in real-time.
                    let minS = minScaleToFill()
                    if imageScale < minS {
                        imageScale  = minS
                        imageOffset = centeredOffset()
                    } else {
                        imageOffset = clampedOffset(imageOffset, scale: imageScale)
                    }

                case .pan:
                    let raw = CGSize(width:  offsetAtDragStart.width  + d.width,
                                    height: offsetAtDragStart.height + d.height)
                    imageOffset = clampedOffset(raw, scale: imageScale)

                case .none:
                    break
                }
            }
            .onEnded { _ in
                // After resizing the crop frame, snap image to fill with a spring animation.
                if case .handle = dragMode {
                    withAnimation(.easeOut(duration: 0.22)) {
                        snapImageToCropFrame()
                    }
                }
                dragMode = nil
            }
    }

    // MARK: - Pinch gesture

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .updating($pinchDelta) { val, state, _ in state = val }
            .onEnded { val in
                let minS     = minScaleToFill()
                let newScale = clamp(imageScale * val, lo: minS, hi: 8.0)
                imageScale   = newScale
                imageOffset  = clampedOffset(imageOffset, scale: newScale)
            }
    }

    // MARK: - Handle hit detection

    private func nearestHandle(to pt: CGPoint) -> HandleID? {
        let r = cropRect
        let candidates: [(CGPoint, HandleID)] = [
            (CGPoint(x: r.minX, y: r.minY), .tl),
            (CGPoint(x: r.maxX, y: r.minY), .tr),
            (CGPoint(x: r.minX, y: r.maxY), .bl),
            (CGPoint(x: r.maxX, y: r.maxY), .br),
            (CGPoint(x: r.midX, y: r.minY), .top),
            (CGPoint(x: r.midX, y: r.maxY), .bottom),
            (CGPoint(x: r.minX, y: r.midY), .left),
            (CGPoint(x: r.maxX, y: r.midY), .right),
        ]
        for (pos, id) in candidates {
            if hypot(pt.x - pos.x, pt.y - pos.y) <= handleHitR { return id }
        }
        return nil
    }

    // MARK: - Crop rect adjustment (per handle)

    private func adjustedCropRect(handle id: HandleID, delta: CGSize) -> CGRect {
        let dx = delta.width, dy = delta.height
        let b  = cropAtDragStart
        let vw = viewSize.width, vh = viewSize.height

        var x0 = b.minX, y0 = b.minY
        var x1 = b.maxX, y1 = b.maxY

        switch id {
        case .tl:
            x0 = clamp(b.minX + dx, lo: 0,             hi: x1 - minCropDim)
            y0 = clamp(b.minY + dy, lo: 0,             hi: y1 - minCropDim)
        case .tr:
            x1 = clamp(b.maxX + dx, lo: x0 + minCropDim, hi: vw)
            y0 = clamp(b.minY + dy, lo: 0,             hi: y1 - minCropDim)
        case .bl:
            x0 = clamp(b.minX + dx, lo: 0,             hi: x1 - minCropDim)
            y1 = clamp(b.maxY + dy, lo: y0 + minCropDim, hi: vh)
        case .br:
            x1 = clamp(b.maxX + dx, lo: x0 + minCropDim, hi: vw)
            y1 = clamp(b.maxY + dy, lo: y0 + minCropDim, hi: vh)
        case .top:
            y0 = clamp(b.minY + dy, lo: 0,             hi: y1 - minCropDim)
        case .bottom:
            y1 = clamp(b.maxY + dy, lo: y0 + minCropDim, hi: vh)
        case .left:
            x0 = clamp(b.minX + dx, lo: 0,             hi: x1 - minCropDim)
        case .right:
            x1 = clamp(b.maxX + dx, lo: x0 + minCropDim, hi: vw)
        }

        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    // MARK: - Image fitting

    /// Minimum image scale required so the image covers the current crop frame.
    private func minScaleToFill() -> CGFloat {
        let bs = baseSize(for: viewSize)
        guard bs.width > 0, bs.height > 0 else { return 1 }
        return max(cropRect.width / bs.width, cropRect.height / bs.height)
    }

    /// Offset that places the image center at the crop frame center.
    private func centeredOffset() -> CGSize {
        CGSize(width:  cropRect.midX - viewSize.width  / 2,
               height: cropRect.midY - viewSize.height / 2)
    }

    /// Adjusts imageScale (if too small) and clamps offset so image always covers crop frame.
    private func snapImageToCropFrame() {
        let minS = minScaleToFill()
        if imageScale < minS {
            imageScale  = minS
            imageOffset = centeredOffset()
        } else {
            imageOffset = clampedOffset(imageOffset, scale: imageScale)
        }
    }

    /// Clamps `offset` so the image (at `scale`) covers the entire crop frame.
    ///
    /// Derivation (x-axis; y mirrors):
    ///   imageCenter.x = vw/2 + offset.x
    ///   imageLeft     = imageCenter.x - dispW/2  must be ≤ cropRect.minX
    ///   imageRight    = imageCenter.x + dispW/2  must be ≥ cropRect.maxX
    ///   → lower bound on offset.x:  cropRect.maxX − vw/2 − dispW/2
    ///   → upper bound on offset.x:  cropRect.minX − vw/2 + dispW/2
    private func clampedOffset(_ offset: CGSize, scale: CGFloat) -> CGSize {
        let bs    = baseSize(for: viewSize)
        let dispW = bs.width  * scale
        let dispH = bs.height * scale
        let vw    = viewSize.width
        let vh    = viewSize.height

        let minOx = cropRect.maxX - vw / 2 - dispW / 2
        let maxOx = cropRect.minX - vw / 2 + dispW / 2
        let minOy = cropRect.maxY - vh / 2 - dispH / 2
        let maxOy = cropRect.minY - vh / 2 + dispH / 2

        return CGSize(
            width:  clamp(offset.width,  lo: minOx, hi: maxOx),
            height: clamp(offset.height, lo: minOy, hi: maxOy)
        )
    }

    // MARK: - Utility

    private func clamp(_ v: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        Swift.max(lo, Swift.min(hi, v))
    }

    // MARK: - Setup

    private func setupInitialState(in v: CGSize) {
        let bs = baseSize(for: v)

        // Crop frame = image display bounds centered in the view.
        cropRect = CGRect(
            x: (v.width  - bs.width)  / 2,
            y: (v.height - bs.height) / 2,
            width:  bs.width,
            height: bs.height
        )

        // Image fits exactly inside the initial crop frame (scale = 1, offset = 0).
        imageScale  = 1.0
        imageOffset = .zero
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarLayer: some View {
        VStack {
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                Spacer()
                Button(action: performCrop) {
                    Text("Done")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(ThemeStore.shared.accent)
                        .clipShape(Capsule())
                }
                .padding(.trailing, 8)
            }
            .padding(.top, 56)

            Spacer()

            Text("Drag handles to resize · Drag image to reposition · Pinch to zoom")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.40))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Perform crop

    private func performCrop() {
        let v     = viewSize != .zero ? viewSize : CGSize(width: 390, height: 844)
        let bs    = baseSize(for: v)
        let dispW = bs.width  * imageScale
        let dispH = bs.height * imageScale

        // Image origin (top-left) in view coordinates.
        //   image center = (v.width/2 + offset.x, v.height/2 + offset.y)
        let imgOriginX = v.width  / 2 + imageOffset.width  - dispW / 2
        let imgOriginY = v.height / 2 + imageOffset.height - dispH / 2

        // Crop rect expressed in image-display coordinates (from image top-left).
        let cropInDispX = cropRect.origin.x - imgOriginX
        let cropInDispY = cropRect.origin.y - imgOriginY

        // Scale from display coords to original pixel coords.
        let pxScaleX = image.size.width  / dispW
        let pxScaleY = image.size.height / dispH

        let pxX = cropInDispX * pxScaleX
        let pxY = cropInDispY * pxScaleY
        let pxW = cropRect.width  * pxScaleX
        let pxH = cropRect.height * pxScaleY

        let unclamped  = CGRect(x: pxX, y: pxY, width: pxW, height: pxH)
        let imageBounds = CGRect(origin: .zero, size: image.size)
        let pxRect     = unclamped.intersection(imageBounds)

        guard pxRect.width > 0, pxRect.height > 0 else { onCrop(image); return }

        UIGraphicsBeginImageContextWithOptions(pxRect.size, false, image.scale)
        image.draw(at: CGPoint(x: -pxRect.origin.x, y: -pxRect.origin.y))
        let cropped = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        onCrop(cropped)
    }
}
