//
//  MacroFieldView.swift
//  Wellness
//

import SwiftUI

struct MacroFieldView: View {
    let label: String
    let unit: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            TextField("0", text: $value)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            Text(unit)
                .foregroundStyle(.secondary)
        }
        .keyboardDoneToolbar()
    }
}

#Preview {
    @Previewable @State var value = "150"
    MacroFieldView(label: "Calories", unit: "kcal", value: $value)
        .padding()
}
