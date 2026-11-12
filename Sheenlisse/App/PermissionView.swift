import SwiftUI

struct PermissionView: View {
    var noCamera: Bool
    var onBrowse: () -> Void
    var onSettings: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.ivory, Theme.champagne, Theme.blush.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    Ellipse()
                        .stroke(Theme.gold, lineWidth: 2)
                        .frame(width: 132, height: 168)
                    Ellipse()
                        .fill(Theme.rose.opacity(0.85))
                        .frame(width: 46, height: 18)
                        .offset(y: 28)
                }
                .padding(.bottom, 8)
                Text("Sheenlisse")
                    .font(Theme.serif(40, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(noCamera ? "This device has no front camera" : "The mirror needs your camera")
                    .font(Theme.serif(26, weight: .regular))
                    .foregroundStyle(Theme.plum)
                    .multilineTextAlignment(.center)
                Text(explanation)
                    .font(Theme.sans(16))
                    .foregroundStyle(Theme.plum.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Spacer()
                if !noCamera {
                    Button(action: onSettings) {
                        Text("Open Settings")
                            .font(Theme.sans(17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.rose))
                    }
                    .buttonStyle(.plain)
                }
                Button(action: onBrowse) {
                    Text("Browse shades without the camera")
                        .font(Theme.sans(16, weight: .semibold))
                        .foregroundStyle(Theme.plum)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Theme.gold, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)
        }
    }

    private var explanation: String {
        if noCamera {
            return "You can still choose shades, save a look, and read the suggestion notes. Nothing leaves this device."
        }
        return "Sheenlisse uses the front camera to place color on your face. The picture stays on this device. It is not uploaded, and there is no account. You can turn the camera on in Settings."
    }
}

struct LaunchHold: View {
    var body: some View {
        ZStack {
            Theme.ivory.ignoresSafeArea()
            VStack(spacing: 8) {
                Text("Sheenlisse")
                    .font(Theme.serif(42, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("A mirror for color.")
                    .font(Theme.sans(16))
                    .foregroundStyle(Theme.plum.opacity(0.7))
            }
        }
    }
}
