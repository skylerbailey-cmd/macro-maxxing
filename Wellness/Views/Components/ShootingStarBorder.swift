//
//  ShootingStarBorder.swift
//  Wellness
//
//  A rounded-rectangle border with an orbiting "shooting star" — a bright dot
//  that races along the perimeter with a short glowing tail behind it.
//  The rest of the border is rendered at reduced opacity to make the star pop.
//

import SwiftUI

struct ShootingStarBorder: View {
    /// Corner radius of the enclosing rounded rectangle.
    var cornerRadius: CGFloat = 16
    /// Main accent color (e.g. gold for meal planner, purple for coach).
    var color: Color = .yellow
    /// Stroke width of the dim base border.
    var lineWidth: CGFloat = 1.5
    /// How many seconds for one full orbit.
    var duration: Double = 2.8
    /// 0…1 fraction of the perimeter covered by the tail.
    var tailLength: CGFloat = 0.18
    /// When true the star travels counter-clockwise instead of clockwise.
    var reversed: Bool = false

    /// Anchor date so progress is calculated relative to when the view appeared.
    @State private var startDate: Date = .now

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let r = min(cornerRadius, min(w, h) / 2)

            ZStack {
                // ── Dim base border ──────────────────────────────────────────
                RoundedRectangle(cornerRadius: r)
                    .stroke(color.opacity(0.22), lineWidth: lineWidth)

                // ── Shooting star — driven by TimelineView for smooth Canvas redraw
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    let forward = CGFloat(elapsed.truncatingRemainder(dividingBy: duration) / duration)
                    let progress = reversed ? (1 - forward).truncatingRemainder(dividingBy: 1) : forward

                    Canvas { ctx, _ in
                        let perimeter = rectPerimeter(width: w, height: h, radius: r)
                        let steps = 48

                        // Build tail: extends behind the head in the direction of travel.
                        // Normal (clockwise):  tail spans [progress-tailLength … progress],
                        //                      head is points[steps].
                        // Reversed (counter-clockwise): tail spans [progress … progress+tailLength],
                        //                      head is points[0].
                        let tailStart: CGFloat = reversed
                            ? progress
                            : (progress - tailLength + 1).truncatingRemainder(dividingBy: 1)
                        var points: [CGPoint] = []
                        for i in 0...steps {
                            let t = (tailStart + tailLength * CGFloat(i) / CGFloat(steps))
                                .truncatingRemainder(dividingBy: 1)
                            points.append(pointOnRect(t: t, width: w, height: h,
                                                       radius: r, perimeter: perimeter))
                        }

                        // Glowing tail — fades from transparent (far end) to bright (head).
                        for i in 1..<points.count {
                            // reversed: head is points[0], so brightness decreases as i grows
                            let alpha: CGFloat = reversed
                                ? CGFloat(steps - i) / CGFloat(steps)
                                : CGFloat(i) / CGFloat(steps)
                            var path = Path()
                            path.move(to: points[i - 1])
                            path.addLine(to: points[i])
                            ctx.stroke(
                                path,
                                with: .color(color.opacity(Double(alpha) * 0.85)),
                                style: StrokeStyle(lineWidth: lineWidth * (0.5 + alpha * 0.9),
                                                   lineCap: .round)
                            )
                        }

                        // Bright head dot — first point when reversed, last when normal
                        let head = reversed ? points[0] : points[steps]
                        let dotR: CGFloat = lineWidth * 1.8
                        var dotPath = Path()
                        dotPath.addEllipse(in: CGRect(x: head.x - dotR, y: head.y - dotR,
                                                      width: dotR * 2, height: dotR * 2))
                        ctx.fill(dotPath, with: .color(Color.white))

                        // Soft glow halo
                        let glowR: CGFloat = dotR * 3.5
                        var glowPath = Path()
                        glowPath.addEllipse(in: CGRect(x: head.x - glowR, y: head.y - glowR,
                                                       width: glowR * 2, height: glowR * 2))
                        ctx.fill(glowPath, with: .color(color.opacity(0.40)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { startDate = .now }
    }

    // MARK: - Geometry helpers

    private func rectPerimeter(width: CGFloat, height: CGFloat, radius: CGFloat) -> CGFloat {
        let straight = 2 * ((width - 2 * radius) + (height - 2 * radius))
        let arcs = 2 * CGFloat.pi * radius
        return straight + arcs
    }

    /// Point at fractional position `t` (0…1) along the perimeter (clockwise from top-left).
    private func pointOnRect(
        t: CGFloat, width: CGFloat, height: CGFloat,
        radius: CGFloat, perimeter: CGFloat
    ) -> CGPoint {
        let r = radius
        let arcLen = (CGFloat.pi / 2) * r
        let segments: [CGFloat] = [
            width  - 2 * r, arcLen,   // 0: top edge,         1: top-right arc
            height - 2 * r, arcLen,   // 2: right edge,       3: bottom-right arc
            width  - 2 * r, arcLen,   // 4: bottom edge,      5: bottom-left arc
            height - 2 * r, arcLen,   // 6: left edge,        7: top-left arc
        ]

        var dist = (t * perimeter).truncatingRemainder(dividingBy: perimeter)
        for (idx, segLen) in segments.enumerated() {
            if dist <= segLen || idx == segments.count - 1 {
                let s = segLen > 0 ? min(dist / segLen, 1) : 0
                return pointInSegment(segment: idx, s: s, width: width, height: height, radius: r)
            }
            dist -= segLen
        }
        return CGPoint(x: r, y: 0)
    }

    private func pointInSegment(segment: Int, s: CGFloat,
                                 width: CGFloat, height: CGFloat, radius: CGFloat) -> CGPoint {
        let r = radius
        switch segment {
        case 0: return CGPoint(x: r + s * (width - 2 * r), y: 0)
        case 1: return pointOnArc(cx: width - r, cy: r,           startAngle: -.pi / 2, s: s, radius: r)
        case 2: return CGPoint(x: width, y: r + s * (height - 2 * r))
        case 3: return pointOnArc(cx: width - r, cy: height - r,  startAngle:  0,       s: s, radius: r)
        case 4: return CGPoint(x: width - r - s * (width - 2 * r), y: height)
        case 5: return pointOnArc(cx: r,         cy: height - r,  startAngle:  .pi / 2, s: s, radius: r)
        case 6: return CGPoint(x: 0, y: height - r - s * (height - 2 * r))
        default: return pointOnArc(cx: r,        cy: r,           startAngle:  .pi,     s: s, radius: r)
        }
    }

    /// Point on a 90° clockwise arc at fraction `s` (0…1).
    private func pointOnArc(cx: CGFloat, cy: CGFloat,
                             startAngle: CGFloat, s: CGFloat,
                             radius: CGFloat) -> CGPoint {
        let angle = startAngle + s * (.pi / 2)
        return CGPoint(x: cx + cos(angle) * radius, y: cy + sin(angle) * radius)
    }
}
