//
//  DietaryRestrictions.swift
//  Wellness
//
//  Shared helpers for translating the user's dietary-exclusion toggles
//  (stored in UserDefaults by UserSettings) into prompt fragments that
//  can be injected into AI calls — both meal-planning prompts and
//  photo-based macro recognition prompts.
//

import Foundation

enum DietaryRestrictions {

    /// Whether dairy is excluded (milk, cheese, yogurt, butter, cream, whey).
    static var excludesDairy: Bool {
        UserDefaults.standard.bool(forKey: "excludeDairy")
    }

    /// Whether gluten is excluded (wheat, bread, pasta, flour, barley, rye, soy sauce).
    static var excludesGluten: Bool {
        UserDefaults.standard.bool(forKey: "excludeGluten")
    }

    /// Prompt fragment used for photo-based macro recognition. Tells the
    /// model to assume the user's version of a visually-ambiguous food
    /// (e.g. a bowl of pasta is gluten-free pasta if gluten is excluded;
    /// a glass of milk is a plant-based alternative if dairy is excluded)
    /// and to calculate macros accordingly.
    static func visionPromptFragment() -> String {
        var lines: [String] = []

        if excludesGluten {
            lines.append(
                "Gluten-free: the user does not eat gluten (wheat, regular bread, regular pasta, flour, barley, rye, soy sauce). " +
                "If the photo shows something that looks like pasta, bread, a tortilla, pizza crust, noodles, cereal, or other " +
                "typically-wheat food, ASSUME it is the gluten-free version (e.g. rice pasta, chickpea pasta, gluten-free bread, " +
                "corn tortilla, rice noodles) and calculate macros for that version."
            )
        }

        if excludesDairy {
            lines.append(
                "Dairy-free: the user does not eat dairy (cow's milk, cheese, yogurt, butter, cream, whey). " +
                "If the photo shows something that looks like milk, yogurt, cheese, butter, cream, ice cream, or a latte, " +
                "ASSUME it is the plant-based alternative (e.g. oat/almond/soy milk, coconut yogurt, vegan cheese, " +
                "plant-based butter, oat creamer) and calculate macros for that version."
            )
        }

        guard !lines.isEmpty else { return "" }

        return "**User Dietary Preferences — apply when identifying foods:**\n" +
            lines.joined(separator: "\n") +
            "\nOnly override this assumption if the photo shows unmistakable evidence to the contrary " +
            "(e.g. a visible carton labeled \"whole milk\" or a bread bag labeled \"wheat\")."
    }
}
