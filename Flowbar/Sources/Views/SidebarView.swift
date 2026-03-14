import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) var appState
    @Environment(PopoverManager.self) var popoverManager

    var body: some View {
        VStack(spacing: 0) {
            // Top area
            HStack {
                if !popoverManager.isFloating {
                    Button(action: { appState.toggleSidebar() }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, popoverManager.isFloating ? 4 : 10)
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
