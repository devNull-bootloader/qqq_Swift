import SwiftUI

struct GlobalKeyboardHandler: View {
    @State private var input: String = ""
    @EnvironmentObject var activeTab: ActiveTab // Assume this is defined elsewhere

    var body: some View {
        TextField("", text: $input)
            .onReceive(input.publisher.collect()) { value in
                handleKeyInput(value)
            }
            .hidden()
    }

    private func handleKeyInput(_ value: String) {
        // Routing key input logic to the active tab
        switch activeTab.tab { // Assuming activeTab.tab gives current tab
        case .calculator:
            print("Handling key input for Calculator: \(value)")
            // Add specific handling for Calculator
        // Add cases for other tabs if necessary
        default:
            break
        }
    }
}