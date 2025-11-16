import Foundation

struct Goal: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var intervalMinutes: Int
    var isActive: Bool
    var responses: [GoalResponse] = []
    var nextFireDate: Date? = nil          // 👈 NEW
    
    init(
        id: UUID = UUID(),
        title: String,
        intervalMinutes: Int,
        isActive: Bool = false,
        responses: [GoalResponse] = [],
        nextFireDate: Date? = nil          // 👈 NEW
    ) {
        self.id = id
        self.title = title
        self.intervalMinutes = intervalMinutes
        self.isActive = isActive
        self.responses = responses
        self.nextFireDate = nextFireDate
    }
}
