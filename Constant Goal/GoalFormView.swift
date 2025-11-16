import SwiftUI

struct GoalFormView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var selectedIntervalIndex: Int = 1  // default to 15 min
    
    private let intervals = [1 ,5, 15, 30, 60, 120]
    
    private var editingGoal: Goal? {
        viewModel.editingGoal
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Goal title", text: $title)
                }
                
                Section("Reminder every") {
                    Picker("Interval", selection: $selectedIntervalIndex) {
                        ForEach(intervals.indices, id: \.self) { idx in
                            Text("\(intervals[idx]) minutes")
                                .tag(idx)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 150)
                }
            }
            .navigationTitle(editingGoal == nil ? "Add Goal" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        isPresented = false
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadEditingGoalIfNeeded)
        }
    }
    
    private func loadEditingGoalIfNeeded() {
        guard let goal = editingGoal else { return }
        title = goal.title
        
        if let idx = intervals.firstIndex(of: goal.intervalMinutes) {
            selectedIntervalIndex = idx
        } else if let closestIdx = intervals.enumerated()
                    .min(by: { abs($0.element - goal.intervalMinutes) < abs($1.element - goal.intervalMinutes) })?
                    .offset {
            selectedIntervalIndex = closestIdx
        }
    }
    
    private func save() {
        let minutes = intervals[selectedIntervalIndex]
        
        if var goal = editingGoal {
            goal.title = title
            goal.intervalMinutes = minutes
            viewModel.updateGoal(goal)
        } else {
            viewModel.addGoal(title: title, intervalMinutes: minutes)
        }
    }
}
