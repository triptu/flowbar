import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // File list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(appState.noteFiles) { file in
                        SidebarFileRow(file: file, isSelected: appState.selectedFile?.id == file.id)
                            .onTapGesture {
                                appState.showingSettings = false
                                appState.showingTimer = false
                                appState.selectFile(file)
                            }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }

            Spacer()

            // Footer
            SidebarFooter()
        }
        .frame(maxHeight: .infinity)
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
                    .fill(isSelected ? FlowbarColors.accent.opacity(0.35) : Color.clear)
            )
            .contentShape(Rectangle())
    }
}
