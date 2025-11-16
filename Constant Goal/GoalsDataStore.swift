import Foundation

final class GoalsDataStore {
    static let shared = GoalsDataStore()
    private init() {}
    
    weak var viewModel: GoalsViewModel?
    
    func recordResponse(
        goalId: UUID,
        answer: GoalAnswer,
        timestamp: Date
    ) {
        guard let viewModel = viewModel else { return }
        
        if let index = viewModel.goals.firstIndex(where: { $0.id == goalId }) {
            let newResponse = GoalResponse(answer: answer, timestamp: timestamp)
            viewModel.goals[index].responses.append(newResponse)
            
            DispatchQueue.main.async {
                viewModel.objectWillChange.send()
                viewModel.didUpdateResponses()
            }
        }
    }
    
    func handleNotificationFired(for goalId: UUID) {
        guard let viewModel = viewModel else { return }
        
        if let index = viewModel.goals.firstIndex(where: { $0.id == goalId }) {
            let interval = viewModel.goals[index].intervalMinutes
            let oldNext = viewModel.goals[index].nextFireDate ?? Date()
            
            // Move nextFireDate forward by one interval
            let newNext = oldNext.addingTimeInterval(TimeInterval(interval * 60))
            viewModel.goals[index].nextFireDate = newNext
            
            DispatchQueue.main.async {
                viewModel.objectWillChange.send()
                viewModel.didUpdateResponses()   // this calls saveGoals()
            }
        }
    }

}
