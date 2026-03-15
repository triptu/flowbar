import SwiftUI

struct NoteContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        @Bindable var appState = appState
        VStack(alignment: .leading, spacing: 0) {
            noteHeader
            Divider().opacity(0.2)

            TextEditor(text: $appState.editorContent)
                .font(.system(size: appState.typography.bodySize))
                .scrollContentBackground(.hidden)
                .padding(16)
                .onChange(of: appState.editorContent) { _, _ in
                    appState.saveFileContent()
                }
        }
    }

    private var noteHeader: some View {
        HStack(spacing: 10) {
            if !appState.sidebarVisible {
                SidebarToggleButton { appState.toggleSidebar() }
            }

            Text(appState.selectedFile?.name ?? "")
                .font(.system(size: appState.typography.titleSize, weight: .bold))

            Spacer()

            Button(action: { appState.openInObsidian() }) {
                ObsidianIcon()
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .help("Open in Obsidian")
        }
        .padding(.leading, appState.sidebarVisible ? 20 : FloatingPanel.trafficLightWidth)
        .padding(.trailing, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

// Obsidian logo from SVG path
struct ObsidianIcon: View {
    var body: some View {
        ObsidianShape()
            .fill(Color(hex: "6C31E3"))
    }
}

struct ObsidianShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Original viewBox: 0 0 512 512
        let scale = min(rect.width / 512, rect.height / 512)
        let xOff = (rect.width - 512 * scale) / 2
        let yOff = (rect.height - 512 * scale) / 2

        var path = Path()
        // Simplified crystal shape approximating the Obsidian logo
        let points: [(CGFloat, CGFloat)] = [
            (248, 9), (143, 104), (131, 209), (118, 211),
            (61, 342), (156, 480), (230, 486),
            (334, 511), (383, 476), (407, 403),
            (452, 332), (451, 313), (407, 241),
            (394, 148), (386, 126), (298, 13)
        ]
        if let first = points.first {
            path.move(to: CGPoint(x: first.0 * scale + xOff, y: first.1 * scale + yOff))
            for pt in points.dropFirst() {
                path.addLine(to: CGPoint(x: pt.0 * scale + xOff, y: pt.1 * scale + yOff))
            }
            path.closeSubpath()
        }
        return path
    }
}
