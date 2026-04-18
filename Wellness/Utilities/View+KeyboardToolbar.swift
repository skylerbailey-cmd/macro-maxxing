//
//  View+KeyboardToolbar.swift
//  Wellness
//
//  Adds a checkmark button above the keyboard so users can always dismiss it.
//

import SwiftUI
import UIKit

extension View {
    /// Adds an accent-colored checkmark button to the keyboard accessory view
    /// that resigns the first responder when tapped. Apply to any screen that
    /// contains a `TextField`, `TextEditor`, or `SecureField`.
    func keyboardDoneToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(ThemeStore.shared.accent)
                }
            }
        }
    }
}
