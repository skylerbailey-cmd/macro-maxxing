//
//  View+KeyboardToolbar.swift
//  Wellness
//
//  Adds a "Done" button above the keyboard so users can always dismiss it.
//

import SwiftUI
import UIKit

extension View {
    /// Adds a "Done" button to the keyboard accessory view that resigns the
    /// first responder when tapped. Apply to any screen that contains a
    /// `TextField`, `TextEditor`, or `SecureField`.
    func keyboardDoneToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
                .font(.system(size: 16, weight: .semibold))
            }
        }
    }
}
