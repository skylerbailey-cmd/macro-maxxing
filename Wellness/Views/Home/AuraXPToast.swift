//
//  AuraXPToast.swift
//  Wellness
//
//  Subtle bottom-left "+N XP" toast that slides in when aura points are earned.

import SwiftUI

struct AuraXPToast: View {
    let points: Int

    @State private var show = false

    private var accent: Color { ThemeStore.shared.accent }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accent)
            Text("\(points) XP")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(accent.opacity(0.30), lineWidth: 1))
        .scaleEffect(show ? 1.0 : 0.5)
        .opacity(show ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
                show = true
            }
        }
    }
}
