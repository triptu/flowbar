import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) var appState
    @Environment(PopoverManager.self) var popoverManager

    var body: some View {
        VStack(spacing: 0) {
            // Header bar — in floating mode, sits right of traffic lights
            HStack(spacing: 8) {
                Button(action: { appState.toggleSidebar() }) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            // In floating mode, push past traffic lights (~76px from left edge)
            .padding(.leading, popoverManager.isFloating ? 76 : 20)
            .padding(.trailing, 20)
            .padding(.top, popoverManager.isFloating ? 6 : 10)
            .padding(.bottom, 4)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(appState.noteFiles) { file in
                        SidebarFileRow(file: file, isSelected: appState.selectedFile?.id == file.id)
                            .onTapGesture { appState.selectFile(file) }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }

            Spacer()
            SidebarFooter()
        }
        .frame(maxHeight: .infinity)
        .background(FlowbarColors.sidebarBg)
    }
}

struct SidebarFileRow: View {
    let file: NoteFile
    let isSelected: Bool

    var body: some View {
        Text(file.name)
            .font(.system(size: 15))
            .foregroundStyle(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? FlowbarColors.accent.opacity(0.4) : Color.clear)
            )
            .contentShape(Rectangle())
    }
}
