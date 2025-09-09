//
//  ContentView.swift
//  com.IYA.clickerapp.kenyaramirez
//
//  Created by Kenya Ramirez on 9/4/25.
//

import SwiftUI
import UIKit

// MARK: - Models

struct Award: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let emoji: String
    let threshold: Int
}

private struct Particle: Identifiable {
    let id = UUID()
    let birth: Date
    let lifetime: TimeInterval
    let angle: CGFloat
    let speed: CGFloat
    let startRadius: CGFloat
    let color: Color
}

// MARK: - Content

struct ContentView: View {
    @AppStorage("tapCount") private var tapCount: Int = 0
    @State private var earnedAward: Award? = nil
    @State private var showAwards: Bool = false
    @State private var spin: Int = 0                 // drives pitchfork animation
    @State private var burstTrigger: Int = 0         // drives particle bursts

    // Set your pickaxe icon size once (particles will scale with it)
    private let iconSize: CGFloat = 120

    // Mining-themed awards & thresholds
    private let awards: [Award] = [
        Award(name: "Bronze",   emoji: "🥉", threshold: 10),
        Award(name: "Silver",   emoji: "🥈", threshold: 50),
        Award(name: "Gold",     emoji: "🥇", threshold: 100),
        Award(name: "Emerald",  emoji: "🟢", threshold: 200),
        Award(name: "Sapphire", emoji: "🔷", threshold: 350),
        Award(name: "Ruby",     emoji: "🔴", threshold: 600),
        Award(name: "Diamond",  emoji: "💎", threshold: 1000)
    ].sorted { $0.threshold < $1.threshold }

    var body: some View {
        NavigationStack {
            ZStack {
                caveBackground(depth: tapCount).ignoresSafeArea()

                VStack(spacing: 22) {
                    // Depth readout
                    VStack(spacing: 6) {
                        Text("Depth")
                            .font(.title3)
                            .foregroundStyle(.white)
                        Text("\(tapCount) m")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .shadow(radius: 8)
                    }
                    .padding(.top, 8)

                    // Mine button (rock image)
                    Button(action: handleTap) {
                        ZStack {
                            RockBackground() // image of a rock as the button itself
                                .frame(height: max(190, iconSize + 70))

                            VStack(spacing: 10) {
                                ToolIcon(spin: spin, size: iconSize)

                                Text("ROCK ON")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 6)
                            }

                            // Particle burst overlay (centered on the tool), scale-aware
                            ParticleBurst(trigger: burstTrigger, scale: iconSize / 72)
                                .allowsHitTesting(false)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Progress
                    if let next = nextThreshold(after: tapCount) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Next vein at \(next) m")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            ProgressView(value: progress(to: next)).tint(.red)
                        }
                        .padding(.horizontal)
                    } else {
                        Text("You reached the deepest vein. Diamond miner! 💎")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    // Awards summary
                    HStack {
                        let earnedCount = awards.filter { tapCount >= $0.threshold }.count
                        Label("\(earnedCount)/\(awards.count) Veins", systemImage: "rosette")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("View Awards") { showAwards = true }
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(role: .destructive) { tapCount = 0 } label: {
                        Label("Reset Depth", systemImage: "arrow.counterclockwise")
                    }
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("YOU ROCK")
            .toolbarColorScheme(.dark, for: .navigationBar)   // white title/buttons
            .toolbarBackground(.clear, for: .navigationBar)   // transparent bar over gradient
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(.white)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAwards = true } label: { Image(systemName: "rosette") }
                        .accessibilityLabel("Show awards")
                }
            }
            .sheet(isPresented: $showAwards) {
                AwardsListView(tapCount: tapCount, awards: awards)
            }
            .alert(item: $earnedAward) { award in
                Alert(
                    title: Text("New Vein! \(award.emoji)"),
                    message: Text("You hit \(award.name) at \(award.threshold) m."),
                    dismissButton: .default(Text("Nice!"))
                )
            }
        }
    }

    // MARK: - Actions & Helpers

    private func handleTap() {
        let newValue = tapCount + 1
        tapCount = newValue

        // Spin the tool + trigger particles
        withAnimation(.interpolatingSpring(stiffness: 220, damping: 18)) {
            spin += 1
        }
        burstTrigger += 1

        if let award = awards.first(where: { $0.threshold == newValue }) {
            earnedAward = award
            hapticCelebrate()
        }
    }

    private func nextThreshold(after value: Int) -> Int? {
        awards.first(where: { $0.threshold > value })?.threshold
    }

    private func progress(to next: Int) -> Double {
        guard let previous = awards.last(where: { $0.threshold <= tapCount })?.threshold else {
            return Double(tapCount) / Double(max(next, 1))
        }
        let span = max(next - previous, 1)
        let delta = tapCount - previous
        return Double(min(max(delta, 0), span)) / Double(span)
    }

    private func hapticCelebrate() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func caveBackground(depth: Int) -> some View {
        let t = min(1.0, Double(depth) / 1000.0)
        let top = Color(red: 0.25 + 0.15 * (1 - t), green: 0.22 + 0.08 * (1 - t), blue: 0.20 + 0.05 * (1 - t))
        let bottom = Color(red: 0.07, green: 0.08, blue: 0.10 + 0.15 * t)
        return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
            .overlay(
                VStack(spacing: 0) {
                    ForEach(0..<30, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.02 + Double(i % 3) * 0.01))
                            .frame(height: 2)
                        Spacer(minLength: 8)
                    }
                }
                .padding(.vertical, 40)
                .blendMode(.overlay)
            )
    }
}

// MARK: - Rock background (button body)

private struct RockBackground: View {
    var body: some View {
        if UIImage(named: "rock") != nil {
            Image("rock")
                .resizable()
                .scaledToFill()
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.0), Color.black.opacity(0.35)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipped()
        } else {
            // Fallback “rocky” look if no asset yet
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.33, green: 0.33, blue: 0.35),
                                 Color(red: 0.18, green: 0.18, blue: 0.2)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

// MARK: - Pitchfork (or fallback ⛏️) icon with rotation

private struct ToolIcon: View {
    let spin: Int
    var size: CGFloat = 72   // default, overridden by caller

    var body: some View {
        Group {
            if UIImage(named: "pitchfork") != nil {
                Image("pitchfork")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.02) // tweak/remove to fill more
            } else {
                Text("⛏️")
                    .font(.system(size: size * 0.9))
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(Double(spin) * 360))
        .scaleEffect((spin % 2 == 1) ? 1.08 : 1.0)
        .animation(.interpolatingSpring(stiffness: 220, damping: 18), value: spin)
        .shadow(radius: 8)
    }
}

// MARK: - Particle system (dust + sparks), scale-aware

private struct ParticleBurst: View {
    let trigger: Int
    var scale: CGFloat = 1.0
    @State private var particles: [Particle] = []

    // Tuning
    private let countDust = 16
    private let countSparks = 10
    private let dustLifetime: ClosedRange<Double> = 0.6...1.0
    private let sparkLifetime: ClosedRange<Double> = 0.25...0.45

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let now = context.date

                // Cull expired
                particles.removeAll { now.timeIntervalSince($0.birth) > $0.lifetime }

                // Draw
                for p in particles {
                    let age = now.timeIntervalSince(p.birth)
                    let t = max(0, min(1, age / p.lifetime)) // 0..1
                    let distance = p.speed * CGFloat(age)
                    let dx = cos(p.angle) * distance
                    let dy = sin(p.angle) * distance

                    var x = size.width / 2 + dx
                    var y = size.height / 2 + dy

                    // Gravity for dust
                    if p.color != .yellow {
                        y += distance * 0.35
                    }

                    // Fade + shrink
                    let alpha = (1 - t) * 0.9
                    let radius = max(0.5, p.startRadius * (1 - t))

                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    ctx.opacity = alpha
                    ctx.fill(Path(ellipseIn: rect), with: .color(p.color))
                }
            }
            // when trigger changes, emit new particles
            .onChange(of: trigger) { _ in
                emitBurst()
            }
        }
    }

    private func emitBurst() {
        let now = Date()
        let s = max(scale, 0.5) // safety lower bound

        var newParticles: [Particle] = []

        // Dust (brown/gray) — scale radius/speed
        for _ in 0..<countDust {
            newParticles.append(
                Particle(
                    birth: now,
                    lifetime: Double.random(in: dustLifetime),
                    angle: CGFloat.random(in: (.pi * 0.9)...(.pi * 2.1)), // mainly sideways/outward
                    speed: CGFloat.random(in: 40...110) * s,          // scaled
                    startRadius: CGFloat.random(in: 3...8) * s,       // scaled
                    color: Color(red: 0.46, green: 0.38, blue: 0.30).opacity(0.9)
                )
            )
        }

        // Sparks (bright, faster, shorter life) — scaled
        for _ in 0..<countSparks {
            newParticles.append(
                Particle(
                    birth: now,
                    lifetime: Double.random(in: sparkLifetime),
                    angle: CGFloat.random(in: 0...(2 * .pi)),
                    speed: CGFloat.random(in: 120...220) * s,         // scaled
                    startRadius: CGFloat.random(in: 1.5...3.0) * s,   // scaled
                    color: .yellow
                )
            )
        }

        particles.append(contentsOf: newParticles)
    }
}

// MARK: - Awards List

struct AwardsListView: View {
    let tapCount: Int
    let awards: [Award]

    var body: some View {
        NavigationStack {
            List(awards) { award in
                HStack(spacing: 12) {
                    Text(award.emoji).font(.title2).frame(width: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(award.name).font(.headline)
                        Text("\(award.threshold) m").font(.caption).foregroundStyle(.secondary)
                    }

                    Spacer()

                    if tapCount >= award.threshold {
                        Image(systemName: "checkmark.seal.fill").imageScale(.large).foregroundStyle(.green)
                    } else {
                        Image(systemName: "lock.fill").imageScale(.medium).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Veins Discovered")
        }
    }
}


#Preview {
    ContentView()
}
