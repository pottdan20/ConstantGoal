import SwiftUI

struct GoalSessionsView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    let goalID: UUID
    
    var body: some View {
        guard let goal = viewModel.goals.first(where: { $0.id == goalID }) else {
            return AnyView(
                Text("Goal not found")
                    .foregroundColor(.secondary)
            )
        }
        
        // 🔍 DEBUG: see what this screen thinks the responses are
        let _ = debugPrint(
            "📊 GoalSessionsView for '\(goal.title)': " +
            "responses=\(goal.responses.count), " +
            "answers=\(goal.responses.map { $0.answer })"
        )
        
        let sessions = buildSessionSummaries(for: goal)
        
        return AnyView(
            List {
                if sessions.isEmpty {
                    Text("No sessions yet.\nStart and pause this goal to create sessions.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(sessions) { summary in
                        NavigationLink {
                            SessionDetailView(
                                goalID: goalID,
                                sessionIndex: summary.index
                            )
                        } label: {
                            SessionRowView(summary: summary)
                        }
                    }
                }
            }
            .navigationTitle("Sessions")
        )
    }
    
    // MARK: - Session summary model
    
    struct SessionSummary: Identifiable {
        let id = UUID()
        let index: Int      // Session number (1 = oldest, N = newest)
        let start: Date
        let end: Date
        let duration: TimeInterval
        let yesCount: Int
        let noCount: Int
        let totalResponses: Int
        let isActive: Bool  // 👈 whether this is the current active session
        
        var yesNoDenominator: Int {
            yesCount + noCount
        }
        
        var yesRatio: Double {
            guard yesNoDenominator > 0 else { return 0 }
            return Double(yesCount) / Double(yesNoDenominator)
        }
    }

    
    // MARK: - Build sessions from responses
    private func buildSessionSummaries(for goal: Goal) -> [SessionSummary] {
        let chronological = splitIntoSessionsByEnd(responses: goal.responses)
        let reversed = Array(chronological.reversed())
        let total = chronological.count
        
        return reversed.enumerated().compactMap { (reversedIndex, session) in
            guard let first = session.first, let last = session.last else { return nil }
            
            let yes = session.filter { $0.answer == .yes }.count
            let no  = session.filter { $0.answer == .no }.count
            
            // Session number: 1 = oldest, N = newest
            let sessionNumber = total - reversedIndex
            
            // Chronological index (0 = oldest, total-1 = newest)
            let chronologicalIndex = total - 1 - reversedIndex
            
            // Active session = newest session AND goal is active
            let isNewestSession = (chronologicalIndex == total - 1)
            let isActiveSession = goal.isActive && isNewestSession
            
            return SessionSummary(
                index: sessionNumber,
                start: first.timestamp,
                end: last.timestamp,
                duration: max(0, last.timestamp.timeIntervalSince(first.timestamp)),
                yesCount: yes,
                noCount: no,
                totalResponses: session.count,   // all responses in this session
                isActive: isActiveSession
            )
        }
    }



    
    /// Split responses into sessions using `.sessionEnd` as explicit boundary.
    /// `.sessionEnd` itself is NOT included in any session.
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
        
        debugPrint("🔎 splitIntoSessionsByEnd → \(sessions.count) sessions")
        return sessions
    }
}

// MARK: - Session row UI

private struct SessionRowView: View {
    let summary: GoalSessionsView.SessionSummary
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top line: Session N — 87% Yes — [ACTIVE]
            HStack {
                Text("Session \(summary.index)")
                    .font(.headline)
                
                Spacer()
                
                if summary.yesNoDenominator > 0 {
                    Text(String(format: "%.0f%% Yes", summary.yesRatio * 100))
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("No Yes/No data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if summary.isActive {
                    Text("ACTIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }
            
            // Second line: Responses + Duration
            HStack {
                Text("Responses: \(summary.totalResponses)")
                Spacer()
                Text("Duration: \(formattedDuration(summary.duration))")
            }
            .font(.subheadline)
            
            // Start / End times
            Text("Start: \(Self.dateFormatter.string(from: summary.start))")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("End:   \(Self.dateFormatter.string(from: summary.end))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(summary.isActive ? Color.green.opacity(0.08) : Color.clear) // subtle highlight
        .cornerRadius(8)
    }
    
    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, secs)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }
}
