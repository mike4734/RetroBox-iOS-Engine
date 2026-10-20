import SwiftUI
import UniformTypeIdentifiers

struct RetroSystem: Identifiable, Hashable {
    let name: String
    let folder: String
    let extensions: Set<String>
    var id: String { folder }
}

struct GameFile: Identifiable {
    let url: URL
    var id: String { url.path }
    var name: String { url.deletingPathExtension().lastPathComponent }
}

struct GameSelection: Identifiable { let url: URL; var id: String { url.path } }

struct ContentView: View {
    private let systems = [
        RetroSystem(name: "ATARI 2600", folder: "Atari", extensions: ["a26", "bin"]),
        RetroSystem(name: "NES", folder: "NES", extensions: ["nes"]),
        RetroSystem(name: "SUPER NES", folder: "SNES", extensions: ["sfc", "smc"]),
        RetroSystem(name: "SEGA GENESIS", folder: "SEGA", extensions: ["gen", "md", "bin"]),
        RetroSystem(name: "ARCADE", folder: "ARCADE", extensions: ["zip"])
    ]
    @State private var selection = 0
    @State private var games: [GameFile] = []
    @State private var importing = false
    @State private var message: String?
    @State private var selectedGame: URL?

    private var current: RetroSystem { systems[selection] }
    private var root: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("roms", isDirectory: true) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.035, green: 0.05, blue: 0.10).ignoresSafeArea()
                VStack(spacing: 18) {
                    Text("RETROBOX").font(.system(size: 38, weight: .black, design: .rounded)).foregroundStyle(.cyan)
                    Text("i1  •  LIBRETRO").font(.caption.bold()).foregroundStyle(.white.opacity(0.65))
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(systems.indices, id: \.self) { index in
                                Button(systems[index].name) { selection = index; refresh() }
                                    .font(.caption.bold()).padding(12)
                                    .foregroundStyle(selection == index ? .black : .white)
                                    .background(selection == index ? Color.cyan : Color.white.opacity(0.13))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }.padding(.horizontal)
                    }
                    Text(current.name).font(.title2.bold()).foregroundStyle(.white)
                    if games.isEmpty {
                        Spacer()
                        Image(systemName: "gamecontroller.fill").font(.system(size: 64)).foregroundStyle(.cyan.opacity(0.7))
                        Text("No hay juegos importados").foregroundStyle(.white)
                        Spacer()
                    } else {
                        List(games) { game in
                            Button { selectedGame = game.url } label: {
                                HStack { Image(systemName: "gamecontroller"); Text(game.name); Spacer(); Image(systemName: "play.fill") }
                            }.listRowBackground(Color.white.opacity(0.09)).foregroundStyle(.white)
                        }.scrollContentBackground(.hidden)
                    }
                    Button { importing = true } label: {
                        Label("AGREGAR JUEGOS", systemImage: "plus.circle.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(16)
                    }.buttonStyle(.borderedProminent).tint(.cyan).padding(.horizontal)
                    Text("Versión de prueba NES. Audio y otros sistemas pendientes.")
                        .font(.caption2).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.55)).padding(.horizontal)
                }.padding(.vertical)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { refresh() }
            .fullScreenCover(item: Binding(get: { selectedGame.map { GameSelection(url: $0) } }, set: { selectedGame = $0?.url })) { item in EmulatorView(game: item.url) }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.data, .archive], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    var count = 0
                    for url in urls {
                        guard current.extensions.contains(url.pathExtension.lowercased()) else { continue }
                        let accessed = url.startAccessingSecurityScopedResource()
                        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                        let destination = root.appendingPathComponent(current.folder, isDirectory: true).appendingPathComponent(url.lastPathComponent)
                        do {
                            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                            if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
                            try FileManager.default.copyItem(at: url, to: destination)
                            count += 1
                        } catch { message = "No se pudo importar: \(error.localizedDescription)" }
                    }
                    refresh()
                    if count > 0 { message = "Se importaron \(count) archivo(s) a \(current.name)." }
                    else if message == nil { message = "Ningún archivo corresponde a \(current.name)." }
                case .failure(let error): message = error.localizedDescription
                }
            }
            .alert("RetroBox i1", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("Entendido", role: .cancel) { message = nil }
            } message: { Text(message ?? "") }
        }
    }

    private func refresh() {
        let folder = root.appendingPathComponent(current.folder, isDirectory: true)
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        games = urls.filter { current.extensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map { GameFile(url: $0) }
    }
}
