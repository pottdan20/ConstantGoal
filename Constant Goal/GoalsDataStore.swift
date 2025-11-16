import Foundation

final class GoalsDataStore {
    static let shared = GoalsDataStore()
    private init() {}
    
    // Hook into the live SwiftUI view model, set in Constant_GoalApp.init
    weak var viewModel: GoalsViewModel?
    
    // MARK: - Public API
    
    func recordResponse(
        goalId: UUID,
        answer: GoalAnswer,
        timestamp: Date
    ) {
        print("📝 recordResponse called for \(goalId), answer=\(answer) at \(timestamp)")
        
        guard let viewModel = viewModel else {
            print("⚠️ viewModel is nil in GoalsDataStore.recordResponse")
            return
        }
        
        guard let index = viewModel.goals.firstIndex(where: { $0.id == goalId }) else {
            print("⚠️ No goal found with id \(goalId) in viewModel.goals")
            print("   Current goals: \(viewModel.goals.map { $0.id })")
            return
        }
        
        let newResponse = GoalResponse(answer: answer, timestamp: timestamp)
        viewModel.goals[index].responses.append(newResponse)
        
        print("✅ Added response to goal '\(viewModel.goals[index].title)'")
        print("   Total responses for this goal now: \(viewModel.goals[index].responses.count)")
        
        DispatchQueue.main.async {
            viewModel.objectWillChange.send()
            viewModel.didUpdateResponses()   // will save to UserDefaults
        }
    }
    
    func handleNotificationFired(for goalId: UUID) {
        print("⏰ handleNotificationFired(for: \(goalId))")
        
        guard let viewModel = viewModel else {
            print("⚠️ viewModel is nil in handleNotificationFired")
            return
        }
        
        guard let index = viewModel.goals.firstIndex(where: { $0.id == goalId }) else {
            print("⚠️ No goal found with id \(goalId) when updating nextFireDate")
            return
        }
        
        let interval = viewModel.goals[index].intervalMinutes
        let base = viewModel.goals[index].nextFireDate ?? Date()
        let newNext = base.addingTimeInterval(TimeInterval(interval * 60))
        viewModel.goals[index].nextFireDate = newNext
        
        print("✅ Updated nextFireDate for goal '\(viewModel.goals[index].title)' to \(newNext)")
        
        DispatchQueue.main.async {
            viewModel.objectWillChange.send()
            viewModel.didUpdateResponses()
        }
    }
}
