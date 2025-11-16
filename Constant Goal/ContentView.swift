import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @State private var isPresentingForm = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.goals.isEmpty {
                    Text("No goals yet.\nTap \"Add Goal\" to get started.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.goals) { goal in
                            GoalRow(goal: goal)
                        }
                        .onDelete(perform: viewModel.deleteGoal)
                    }
                }
            }
            .navigationTitle("My Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Goal") {
                        viewModel.editingGoal = nil
                        isPresentingForm = true
                    }
                }
            }
            .sheet(isPresented: $isPresentingForm) {
                GoalFormView(isPresented: $isPresentingForm)
                    .environmentObject(viewModel)
            }
        }
    }
}

struct GoalRow: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    let goal: Goal
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "h:mm:ss a"
        return df
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(goal.title)
                    .font(.headline)
                
                Text("Every \(goal.intervalMinutes) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let next = goal.nextFireDate {
                    Text("Next: \(Self.timeFormatter.string(from: next))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not scheduled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.editingGoal = goal
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 4)
            
            Button {
                viewModel.toggleGoalActive(goal)
            } label: {
                Image(systemName: goal.isActive ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 4)
            
            Button(role: .destructive) {
                viewModel.delete(goal: goal)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

