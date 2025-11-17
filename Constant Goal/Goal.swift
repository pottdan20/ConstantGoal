import Foundation

struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var intervalMinutes: Int
    var isActive: Bool
    var nextFireDate: Date?
    var responses: [GoalResponse]
    var successThreshold: Int   // already added earlier
    var sessionTitles: [Int: String]   // 👈 NEW: keyed by chronological session index
    
    init(
        id: UUID = UUID(),
        title: String,
        intervalMinutes: Int,
        isActive: Bool = false,
        nextFireDate: Date? = nil,
        responses: [GoalResponse] = [],
        successThreshold: Int = 80,
        sessionTitles: [Int: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.intervalMinutes = intervalMinutes
        self.isActive = isActive
        self.nextFireDate = nextFireDate
        self.responses = responses
        self.successThreshold = successThreshold
        self.sessionTitles = sessionTitles
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case intervalMinutes
        case isActive
        case nextFireDate
        case responses
        case successThreshold
        case sessionTitles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        intervalMinutes = try container.decode(Int.self, forKey: .intervalMinutes)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        nextFireDate = try container.decodeIfPresent(Date.self, forKey: .nextFireDate)
        responses = try container.decodeIfPresent([GoalResponse].self, forKey: .responses) ?? []
        successThreshold = try container.decodeIfPresent(Int.self, forKey: .successThreshold) ?? 80
        sessionTitles = try container.decodeIfPresent([Int: String].self, forKey: .sessionTitles) ?? [:]
    }
}
