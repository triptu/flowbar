import SwiftUI

struct TimerContainerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var timerService: TimerService
    @State private var showingTodos = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with toggle
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showingTodos.toggle()
                    }
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(showingTodos ? FlowbarColors.timerActive : Color.secondary.opacity(0.15))
                        )
                        .foregroundStyle(showingTodos ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Content
            ZStack {
                if showingTodos {
                    TimerTodosView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    TimerHomeView()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.25), value: showingTodos)
    }
}
