import Foundation

enum GoalAnswer: String, Codable, Equatable {
    case yes
    case no
    case none
    case sessionEnd
}

struct GoalResponse: Identifiable, Codable, Equatable {
    let id = UUID()
    let answer: GoalAnswer
    let timestamp: Date
}
