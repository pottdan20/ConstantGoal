import SwiftUI

struct SessionDetailView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    let goalID: UUID
    let sessionIndex: Int   // 0-based chronological index (0 = oldest)
    
    @State private var customTitle: String = ""
    @State private var didInitTitle = false
    
    var body: some View {
        if let goal = viewModel.goals.first(where: { $0.id == goalID }) {
            let sessions = splitIntoSessionsByEnd(responses: goal.responses)  // chronological
            guard sessionIndex < sessions.count else {
                return AnyView(
                    Text("Session not found")
                        .foregroundColor(.secondary)
                )
            }
            
            let session = sessions[sessionIndex]
            let sessionNumber = sessionIndex + 1   // 1 = oldest
            let stats = computeStats(for: session)
            
            return AnyView(
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // TITLE + EDITABLE NAME
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session \(sessionNumber)")
                                .font(.title2)
                                .bold()
                            
                            TextField("Optional session name", text: $customTitle)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Save Title") {
                                saveTitle(goal: goal, chronologicalIndex: sessionIndex)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // SUMMARY
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.headline)
                            
                            HStack {
                                Text("Responses: \(stats.totalResponses)")
                                Spacer()
                                Text("Yes: \(stats.yesCount)")
                                Text("No: \(stats.noCount)")
                            }
                            
                            if stats.yesNoDenominator > 0 {
                                let pct = stats.yesRatio * 100.0
                                let meets = pct >= Double(goal.successThreshold)
                                HStack {
                                    Text(String(format: "Yes ratio: %.1f%%", pct))
                                    Spacer()
                                    Text("Target: \(goal.successThreshold)%")
                                }
                                .foregroundColor(meets ? .green : .red)
                            } else {
                                Text("No Yes/No responses in this session.")
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Duration: \(formattedDuration(stats.duration))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // TIMELINE
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Response Timeline")
                                .font(.headline)
                            
                            let timelineEvents = buildTimeline(
                                for: session,
                                intervalMinutes: goal.intervalMinutes
                            )
                            
                            ForEach(timelineEvents.indices, id: \.self) { idx in
                                switch timelineEvents[idx] {
                                case .actual(let r):
                                    TimelineRow(response: r)
                                case .missed(let t):
                                    MissedTimelineRow(timestamp: t)
                                }
                            }
                            
                            // End marker still based on last actual response
                            if let last = stats.orderedResponses.last {
                                TimelineEndRow(endTime: last.timestamp)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Session \(sessionNumber)")
                .onAppear {
                    // ✅ SAFE PLACE TO INITIALIZE STATE
                    if !didInitTitle {
                        customTitle = goal.sessionTitles[sessionIndex] ?? ""
                        didInitTitle = true
                    }
                }
            )
        } else {
            return AnyView(
                Text("Goal not found")
                    .foregroundColor(.secondary)
            )
        }
    }
    
    // MARK: - Save title
    
    private func saveTitle(goal: Goal, chronologicalIndex: Int) {
        viewModel.setSessionTitle(
            goalId: goal.id,
            sessionIndex: chronologicalIndex,
            title: customTitle
        )
    }
    
    // MARK: - Session splitting
    
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
    
    // MARK: - Timeline events (actual + missed)

    private enum TimelineEvent {
        case actual(GoalResponse)
        case missed(Date)   // synthetic "missed response" at this time
    }

    private func buildTimeline(
        for session: [GoalResponse],
        intervalMinutes: Int
    ) -> [TimelineEvent] {
        let ordered = session.sorted { $0.timestamp < $1.timestamp }
        guard !ordered.isEmpty else { return [] }
        
        var events: [TimelineEvent] = []
        let interval = TimeInterval(intervalMinutes * 60)
        
        for i in 0..<ordered.count {
            let current = ordered[i]
            events.append(.actual(current))
            
            // Look ahead to next real response
            if i < ordered.count - 1 {
                let next = ordered[i + 1]
                let gap = next.timestamp.timeIntervalSince(current.timestamp)
                
                // If the gap is >= 2x interval, we treat it as a missed ping
                if gap >= interval * 2 {
                    // Place the "missed" event approximately at the first missed slot
                    let missedTime = current.timestamp.addingTimeInterval(interval)
                    events.append(.missed(missedTime))
                }
            }
        }
        
        return events
    }
    
    // MARK: - Stats
    
    private struct SessionStats {
        let orderedResponses: [GoalResponse]
        let totalResponses: Int
        let yesCount: Int
        let noCount: Int
        let noneCount: Int
        let yesRatio: Double
        let yesNoDenominator: Int
        let duration: TimeInterval
    }
    
    private func computeStats(for session: [GoalResponse]) -> SessionStats {
        let ordered = session.sorted { $0.timestamp < $1.timestamp }
        let total = ordered.count
        let yes = ordered.filter { $0.answer == .yes }.count
        let no  = ordered.filter { $0.answer == .no }.count
        let none = ordered.filter { $0.answer == .none }.count
        
        let denom = yes + no
        let ratio: Double = denom > 0 ? Double(yes) / Double(denom) : 0
        
        let duration: TimeInterval = {
            guard let first = ordered.first, let last = ordered.last else { return 0 }
            return max(0, last.timestamp.timeIntervalSince(first.timestamp))
        }()
        
        return SessionStats(
            orderedResponses: ordered,
            totalResponses: total,
            yesCount: yes,
            noCount: no,
            noneCount: none,
            yesRatio: ratio,
            yesNoDenominator: denom,
            duration: duration
        )
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


// MARK: - Timeline rows

private struct TimelineRow: View {
    let response: GoalResponse
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .medium
        return df
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Colored square
            RoundedRectangle(cornerRadius: 4)
                .fill(color(for: response.answer))
                .frame(width: 18, height: 18)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.timeFormatter.string(from: response.timestamp))
                    .font(.subheadline)
                Text(label(for: response.answer))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private func color(for answer: GoalAnswer) -> Color {
        switch answer {
        case .yes:         return .green
        case .no:          return .red
        case .none:        return .yellow
        case .sessionEnd:  return .gray
        }
    }
    
    private func label(for answer: GoalAnswer) -> String {
        switch answer {
        case .yes:         return "Yes"
        case .no:          return "No"
        case .none:        return "No response (none)"
        case .sessionEnd:  return "End"
        }
    }
}

private struct MissedTimelineRow: View {
    let timestamp: Date
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .medium
        return df
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Yellow square for missed response
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.yellow)
                .frame(width: 18, height: 18)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.timeFormatter.string(from: timestamp))
                    .font(.subheadline)
                Text("Missed response")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

private struct TimelineEndRow: View {
    let endTime: Date
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .medium
        return df
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 18, height: 18)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.timeFormatter.string(from: endTime))
                    .font(.subheadline)
                Text("Session ended")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
