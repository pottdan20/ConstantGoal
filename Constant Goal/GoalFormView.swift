import SwiftUI

struct GoalFormView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var selectedIntervalIndex: Int = 1  // default to 15 min
    @State private var successThreshold: Int = 80      // 👈 NEW
    
    private let intervals = [1 ,5, 15, 30, 60, 120]
    
    private var editingGoal: Goal? {
        viewModel.editingGoal
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // -------------------------------
                // Goal Title
                // -------------------------------
                Section("Goal") {
                    TextField("Goal title", text: $title)
                }
                
                // -------------------------------
                // Interval Picker
                // -------------------------------
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
                
                // -------------------------------
                // Success % Threshold (NEW)
                // -------------------------------
                Section("Success Target") {
                    Stepper(
                        "\(successThreshold)% Yes required",
                        value: $successThreshold,
                        in: 1...100
                    )
                    
                    Text("Sessions with at least this Yes% will be shown in green.\nBelow it will be red.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
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
        
        // Load interval picker
        if let idx = intervals.firstIndex(of: goal.intervalMinutes) {
            selectedIntervalIndex = idx
        } else if let closestIdx = intervals.enumerated()
                    .min(by: { abs($0.element - goal.intervalMinutes) < abs($1.element - goal.intervalMinutes) })?
                    .offset {
            selectedIntervalIndex = closestIdx
        }
        
        // Load success % (NEW)
        successThreshold = goal.successThreshold
    }
    
    private func save() {
        let minutes = intervals[selectedIntervalIndex]
        
        if var goal = editingGoal {
            goal.title = title
            goal.intervalMinutes = minutes
            goal.successThreshold = successThreshold     // 👈 NEW
            viewModel.updateGoal(goal)
        } else {
            viewModel.addGoal(
                title: title,
                intervalMinutes: minutes,
                successThreshold: successThreshold        // 👈 NEW
            )
        }
    }
}
