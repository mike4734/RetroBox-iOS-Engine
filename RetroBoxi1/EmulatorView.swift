import SwiftUI
import CoreGraphics
import UIKit

@MainActor final class EmulatorSession: ObservableObject {
    @Published var image: UIImage?
    @Published var error: String?
    private var timer: Timer?
    func start(_ url: URL) {
        stop()
        error = nil
        guard rb_load_game(url.path) else { error = String(cString: rb_error()); return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }
    private func tick() {
        rb_run_frame()
        let width = Int(rb_width()), height = Int(rb_height())
        guard width > 0, height > 0, let source = rb_framebuffer() else { return }
        let data = Data(bytes: source, count: width * height * 4)
        guard let provider = CGDataProvider(data: data as CFData),
              let cg = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                 bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                 bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue).union(.byteOrder32Little),
                 provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return }
        image = UIImage(cgImage: cg)
    }
    func button(_ id: Int, down: Bool) {
        let bit = UInt16(1 << id)
        buttons = down ? (buttons | bit) : (buttons & ~bit)
        rb_set_buttons(buttons)
    }
    private var buttons: UInt16 = 0
    func stop() { timer?.invalidate(); timer = nil; rb_unload() }
}

struct EmulatorView: View {
    let game: URL
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = EmulatorSession()
    var body: some View {
        VStack(spacing: 16) {
            if let image = session.image {
                Image(uiImage: image).interpolation(.none).resizable().scaledToFit().frame(maxHeight: 360)
            } else { Text(session.error ?? "Iniciando motor Libretro...").foregroundStyle(.white) }
            HStack(spacing: 16) {
                VStack {
                    pad("↑", 4)
                    HStack { pad("←", 6); pad("↓", 5); pad("→", 7) }
                }
                Spacer()
                VStack {
                    HStack { pad("B", 0); pad("A", 8) }
                    HStack { pad("SELECT", 2); pad("START", 3) }
                }
            }.padding()
            Button("SALIR") { session.stop(); dismiss() }.foregroundStyle(.cyan)
        }
        .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear { session.start(game) }
        .onDisappear { session.stop() }
    }
    private func pad(_ label: String, _ id: Int) -> some View {
        Text(label).font(.caption.bold()).frame(minWidth: 48, minHeight: 48)
            .background(.white.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 10))
            .onLongPressGesture(minimumDuration: 0, maximumDistance: 40,
                pressing: { session.button(id, down: $0) }, perform: {})
    }
}
