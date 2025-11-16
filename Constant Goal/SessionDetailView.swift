import SwiftUI

struct SessionDetailView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    let goalID: UUID
    let sessionIndex: Int   // 0-based
    
    var body: some View {
        if let goal = viewModel.goals.first(where: { $0.id == goalID }) {
            let sessions = splitIntoSessionsByEnd(responses: goal.responses)
            
            if sessionIndex < sessions.count {
                let session = sessions[sessionIndex]
                let title = sessionTitle(for: goal, index: sessionIndex, session: session)
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title2)
                        .padding(.top)
                    
                    Text("Detailed stats coming soon…")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Session \(sessionIndex + 1)")
            } else {
                Text("Session not found")
                    .foregroundColor(.secondary)
            }
        } else {
            Text("Goal not found")
                .foregroundColor(.secondary)
        }
    }
    
    // Same splitter as in GoalSessionsView
    private func splitIntoSessionsByEnd(
        responses: [GoalResponse]
    ) -> [[GoalResponse]] {
        var sessions: [[GoalResponse]] = []
        var current: [GoalResponse] = []
        
        for r in responses.sorted(by: { $0.timestamp < $1.timestamp }) {
            if r.answer == .sessionEnd {
                if !current.isEmpty {
                    sessions.append(current)
                    current.removeAll()
                }
            } else {
                current.append(r)
            }
        }
        
        if !current.isEmpty {
            sessions.append(current)
        }
        
        return sessions
    }
    
    private func sessionTitle(for goal: Goal, index: Int, session: [GoalResponse]) -> String {
        let yes = session.filter { $0.answer == .yes }.count
        let no  = session.filter { $0.answer == .no }.count
        let denom = yes + no
        
        if denom > 0 {
            let ratio = Double(yes) / Double(denom)
            return String(
                format: "%@ — Session %d (%.0f%% Yes)",
                goal.title,
                index + 1,
                ratio * 100
            )
        } else {
            return "\(goal.title) — Session \(index + 1)"
        }
    }
}
