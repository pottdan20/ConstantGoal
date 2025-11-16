import Foundation

final class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var editingGoal: Goal? = nil

    private let storageKey = "savedGoals"

    init() {
        loadGoals()
    }
    
    // MARK: - Public API
    
    func addGoal(title: String, intervalMinutes: Int) {
        let goal = Goal(title: title, intervalMinutes: intervalMinutes)
        goals.append(goal)
        saveGoals()
    }
    
    func delete(goal: Goal) {
        if let index = goals.firstIndex(of: goal) {
            deleteGoal(at: IndexSet(integer: index))
        }
    }
    
    func updateGoal(_ updated: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == updated.id }) else { return }
        let wasActive = goals[index].isActive
        goals[index] = updated
        
        if wasActive {
            NotificationManager.shared.cancelGoalNotification(goal: updated)
            
            let seconds = TimeInterval(max(updated.intervalMinutes * 60, 1))
            goals[index].nextFireDate = Date().addingTimeInterval(seconds)
            
            NotificationManager.shared.scheduleNotification(for: goals[index])
        }
        
        saveGoals()
    }
    
    func toggleGoalActive(_ goal: Goal) {
        guard let index = goals.firstIndex(of: goal) else { return }
        goals[index].isActive.toggle()

        if goals[index].isActive {
            // Start / resume: schedule and set nextFireDate
            let seconds = TimeInterval(max(goals[index].intervalMinutes * 60, 1))
            let newNext = Date().addingTimeInterval(seconds)
            goals[index].nextFireDate = newNext
            print("🚀 Starting goal '\(goals[index].title)', nextFireDate = \(newNext)")

            NotificationManager.shared.scheduleNotification(for: goals[index])
        } else {
            // Pause: record a session end marker + clear nextFireDate
            print("🛑 Pausing goal '\(goals[index].title)' – inserting sessionEnd")

            let endResponse = GoalResponse(
                answer: .sessionEnd,
                timestamp: Date()
            )
            goals[index].responses.append(endResponse)

            goals[index].nextFireDate = nil
            NotificationManager.shared.cancelGoalNotification(goal: goals[index])
        }

        saveGoals()
    }


    func deleteGoal(at offsets: IndexSet) {
        for index in offsets {
            let goal = goals[index]
            NotificationManager.shared.cancelGoalNotification(goal: goal)
        }
        goals.remove(atOffsets: offsets)
        saveGoals()
    }
    
    // Called from GoalsDataStore when a Yes/No is recorded
    func didUpdateResponses() {
        saveGoals()
    }
    
    // MARK: - Persistence
    
    private func saveGoals() {
        do {
            let data = try JSONEncoder().encode(goals)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save goals: \(error)")
        }
    }
    
    private func loadGoals() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        do {
            let decoded = try JSONDecoder().decode([Goal].self, from: data)
            goals = decoded
        } catch {
            print("❌ Failed to load goals: \(error)")
        }
    }
}
