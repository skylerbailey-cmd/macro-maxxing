//
//  LocalMealDatabase.swift
//  Wellness
//
//  Static database of meals and snacks organized by macro profile.
//  Used by MacroRecommendationEngine to surface suggestions without
//  calling any external API.
//

import Foundation

// MARK: - Types

enum MealProfile {
    case balanced          // Good mix of all three macros
    case highProtein       // Primarily protein
    case highCarb          // Primarily carbs
    case highFat           // Primarily fat
    case highProteinCarb   // High in protein + carbs, low fat
    case highProteinFat    // High in protein + fat, low carbs
    case highCarbFat       // High in carbs + fat, low protein
}

enum PrimaryMacro { case protein, carbs, fat }

struct LocalMeal {
    let name:      String
    let portion:   String
    let calories:  Int
    let protein:   Int
    let carbs:     Int
    let fat:       Int
    let profile:   MealProfile
    let isSnack:   Bool
    let hasDairy:  Bool
    let hasGluten: Bool

    init(_ name: String, _ portion: String,
         cal: Int, pro: Int, carb: Int, fat: Int,
         profile: MealProfile, snack: Bool = false,
         dairy: Bool = false, gluten: Bool = false) {
        self.name      = name;    self.portion  = portion
        self.calories  = cal;     self.protein  = pro
        self.carbs     = carb;    self.fat      = fat
        self.profile   = profile; self.isSnack  = snack
        self.hasDairy  = dairy;   self.hasGluten = gluten
    }
}

struct FoodComponent {
    let name:        String
    let portion:     String
    let calories:    Int
    let protein:     Int
    let carbs:       Int
    let fat:         Int
    let primaryMacro: PrimaryMacro
    let hasDairy:    Bool
    let hasGluten:   Bool

    init(_ name: String, _ portion: String,
         cal: Int, pro: Int, carb: Int, fat: Int,
         macro: PrimaryMacro, dairy: Bool = false, gluten: Bool = false) {
        self.name = name; self.portion = portion
        self.calories = cal; self.protein = pro; self.carbs = carb; self.fat = fat
        self.primaryMacro = macro; self.hasDairy = dairy; self.hasGluten = gluten
    }
}

// MARK: - Database

struct LocalMealDatabase {

    // MARK: Balanced (all three macros)

    static let balanced: [LocalMeal] = [
        LocalMeal("Grilled Chicken + Brown Rice + Broccoli",
                  "5 oz chicken · 1 cup rice · 1 cup broccoli",
                  cal: 420, pro: 42, carb: 45, fat: 8, profile: .balanced),
        LocalMeal("Baked Salmon + Quinoa + Roasted Asparagus",
                  "5 oz salmon · ¾ cup quinoa · 6 spears",
                  cal: 460, pro: 40, carb: 38, fat: 14, profile: .balanced),
        LocalMeal("Ground Turkey + Sweet Potato + Green Beans",
                  "5 oz turkey · 1 medium sweet potato · 1 cup beans",
                  cal: 440, pro: 38, carb: 46, fat: 10, profile: .balanced),
        LocalMeal("Lean Beef Stir Fry + Jasmine Rice",
                  "4 oz beef · 1 cup rice · mixed veggies",
                  cal: 450, pro: 36, carb: 48, fat: 12, profile: .balanced),
        LocalMeal("Shrimp + Brown Rice + Edamame",
                  "5 oz shrimp · 1 cup rice · ½ cup edamame",
                  cal: 420, pro: 38, carb: 50, fat: 8, profile: .balanced),
        LocalMeal("Chicken + Whole Wheat Pasta + Marinara",
                  "4 oz chicken · 1.5 cups pasta · ½ cup sauce",
                  cal: 490, pro: 38, carb: 58, fat: 9, profile: .balanced, gluten: true),
        LocalMeal("Tuna Poke Bowl",
                  "4 oz tuna · 1 cup brown rice · cucumber · edamame",
                  cal: 430, pro: 36, carb: 52, fat: 8, profile: .balanced),
        LocalMeal("Pork Tenderloin + Roasted Potatoes + Mixed Veggies",
                  "5 oz pork · 1 cup potatoes · 1 cup veggies",
                  cal: 450, pro: 38, carb: 42, fat: 11, profile: .balanced),
        LocalMeal("Chicken Burrito Bowl",
                  "4 oz chicken · ½ cup black beans · ¾ cup rice · salsa",
                  cal: 510, pro: 38, carb: 58, fat: 10, profile: .balanced),
        LocalMeal("Turkey Meatballs + Zucchini Noodles + Marinara",
                  "5 meatballs · 2 cups zucchini noodles · ½ cup sauce",
                  cal: 380, pro: 34, carb: 30, fat: 12, profile: .balanced),
        LocalMeal("Baked Cod + Sweet Potato + Green Beans",
                  "6 oz cod · 1 medium sweet potato · 1 cup beans",
                  cal: 360, pro: 38, carb: 42, fat: 5, profile: .balanced),
        LocalMeal("Grilled Swordfish + Quinoa + Roasted Peppers",
                  "5 oz swordfish · ¾ cup quinoa · 1 cup peppers",
                  cal: 430, pro: 40, carb: 36, fat: 13, profile: .balanced),
        LocalMeal("Chicken Fried Rice (light)",
                  "2 cups — egg, veggies, minimal oil",
                  cal: 420, pro: 30, carb: 52, fat: 10, profile: .balanced),
        LocalMeal("Grilled Tilapia + Rice Pilaf + Mixed Greens",
                  "6 oz tilapia · 1 cup rice · 2 cups greens",
                  cal: 390, pro: 38, carb: 42, fat: 8, profile: .balanced),
        LocalMeal("Turkey Wrap + Hummus + Cucumber",
                  "whole wheat tortilla · 3 oz turkey · 2 tbsp hummus",
                  cal: 400, pro: 30, carb: 42, fat: 11, profile: .balanced, gluten: true),
        LocalMeal("Skinless Chicken Thigh + Mashed Cauliflower + Roasted Carrots",
                  "5 oz chicken · 1 cup cauliflower · 1 cup carrots",
                  cal: 380, pro: 38, carb: 28, fat: 12, profile: .balanced),
        LocalMeal("Seared Tuna + Bok Choy + Sesame Brown Rice",
                  "5 oz tuna · 2 cups bok choy · ¾ cup rice",
                  cal: 420, pro: 42, carb: 40, fat: 9, profile: .balanced),
        LocalMeal("Chicken Satay + Peanut Sauce + Jasmine Rice",
                  "4 oz chicken · 2 tbsp peanut sauce · ¾ cup rice",
                  cal: 460, pro: 36, carb: 44, fat: 14, profile: .balanced),
        LocalMeal("Grilled Halibut + Brussels Sprouts + Brown Rice",
                  "5 oz halibut · 1 cup sprouts · ¾ cup rice",
                  cal: 400, pro: 38, carb: 42, fat: 9, profile: .balanced),
        LocalMeal("Slow Cooker Beef + Sweet Potato + Kale",
                  "4 oz beef · 1 medium potato · 1 cup kale",
                  cal: 420, pro: 34, carb: 40, fat: 12, profile: .balanced),
        LocalMeal("Ground Turkey Taco Bowl + Corn Tortillas",
                  "4 oz turkey · 2 corn tortillas · salsa · peppers",
                  cal: 420, pro: 34, carb: 44, fat: 12, profile: .balanced),
        LocalMeal("Baked Chicken Breast + Sweet Potato + Spinach",
                  "6 oz chicken · 1 medium potato · 2 cups spinach",
                  cal: 420, pro: 46, carb: 42, fat: 6, profile: .balanced),
        LocalMeal("Shrimp Stir Fry + Brown Rice + Broccoli",
                  "5 oz shrimp · ¾ cup rice · 1.5 cups broccoli",
                  cal: 400, pro: 36, carb: 46, fat: 8, profile: .balanced),
        LocalMeal("Turkey Stuffed Peppers",
                  "2 peppers · 4 oz turkey · ½ cup rice filling",
                  cal: 420, pro: 34, carb: 46, fat: 10, profile: .balanced),
        LocalMeal("Chicken + Lentil Dal + Cauliflower Rice",
                  "4 oz chicken · ½ cup lentil dal · 1.5 cups cauliflower rice",
                  cal: 400, pro: 36, carb: 36, fat: 10, profile: .balanced),
        LocalMeal("Asian Chicken Lettuce Wraps + Brown Rice",
                  "4 oz chicken · 4 lettuce cups · ½ cup rice",
                  cal: 380, pro: 32, carb: 40, fat: 10, profile: .balanced),
        LocalMeal("Tofu Stir Fry + Brown Rice + Snap Peas",
                  "6 oz firm tofu · 1 cup rice · 1 cup snap peas",
                  cal: 400, pro: 22, carb: 52, fat: 10, profile: .balanced),
        LocalMeal("Edamame + Quinoa + Avocado Bowl",
                  "½ cup edamame · 1 cup quinoa · ½ avocado",
                  cal: 440, pro: 22, carb: 46, fat: 18, profile: .balanced),
        LocalMeal("Grilled Chicken Fajita Bowl (no tortilla)",
                  "4 oz chicken · ¾ cup rice · peppers · onions",
                  cal: 400, pro: 34, carb: 46, fat: 10, profile: .balanced),
        LocalMeal("Spicy Turkey + Sweet Potato + Kale Skillet",
                  "5 oz turkey · 1 medium potato · 1 cup kale",
                  cal: 420, pro: 38, carb: 40, fat: 12, profile: .balanced),
        LocalMeal("Grilled Shrimp Tacos + Corn Tortillas + Slaw",
                  "5 oz shrimp · 3 corn tortillas · 1 cup slaw",
                  cal: 420, pro: 34, carb: 48, fat: 10, profile: .balanced),
        LocalMeal("Turkey + Black Bean Chili",
                  "2 cups — no sour cream or cheese toppings",
                  cal: 380, pro: 30, carb: 42, fat: 8, profile: .balanced),
        LocalMeal("Bison Burger (no bun) + Sweet Potato + Greens",
                  "4 oz bison patty · 1 medium potato · 2 cups greens",
                  cal: 430, pro: 34, carb: 44, fat: 12, profile: .balanced),
        LocalMeal("Smoked Salmon + Brown Rice + Cucumber Salad",
                  "4 oz smoked salmon · 1 cup rice · 1 cup cucumber",
                  cal: 390, pro: 30, carb: 48, fat: 10, profile: .balanced),
        LocalMeal("Grilled Chicken + Barley + Roasted Veggies",
                  "5 oz chicken · ¾ cup barley · 1 cup veggies",
                  cal: 430, pro: 40, carb: 44, fat: 8, profile: .balanced, gluten: true),
        LocalMeal("Ground Beef (93% lean) Bowl + Brown Rice + Salsa",
                  "4 oz beef · 1 cup rice · ¼ cup salsa",
                  cal: 440, pro: 34, carb: 48, fat: 12, profile: .balanced),
        LocalMeal("Chicken Soup + Brown Rice + Vegetables",
                  "2 cups soup · ½ cup rice",
                  cal: 370, pro: 28, carb: 44, fat: 8, profile: .balanced),
        LocalMeal("White Fish Tacos + Corn Tortillas + Avocado",
                  "5 oz white fish · 2 corn tortillas · ¼ avocado",
                  cal: 420, pro: 34, carb: 40, fat: 14, profile: .balanced),
        LocalMeal("Lentil Soup + Whole Grain Roll",
                  "2 cups soup · 1 small roll",
                  cal: 380, pro: 20, carb: 60, fat: 6, profile: .balanced, gluten: true),
        LocalMeal("Egg White Omelette + Whole Grain Toast + Salsa",
                  "6 egg whites · 2 slices toast · ¼ cup salsa",
                  cal: 340, pro: 28, carb: 40, fat: 5, profile: .balanced, gluten: true),
        LocalMeal("Grilled Mahi Mahi + Couscous + Roasted Peppers",
                  "5 oz mahi mahi · ¾ cup couscous · 1 cup peppers",
                  cal: 400, pro: 36, carb: 42, fat: 8, profile: .balanced, gluten: true),
        LocalMeal("Chicken + Wild Rice + Roasted Mushrooms",
                  "5 oz chicken · ¾ cup wild rice · 1 cup mushrooms",
                  cal: 420, pro: 40, carb: 42, fat: 8, profile: .balanced),
        LocalMeal("Turkey Meatloaf + Roasted Potatoes",
                  "5 oz meatloaf · 1 cup potatoes",
                  cal: 440, pro: 36, carb: 44, fat: 12, profile: .balanced),
        LocalMeal("Ground Chicken + Buckwheat + Roasted Zucchini",
                  "5 oz chicken · ¾ cup buckwheat · 1 cup zucchini",
                  cal: 400, pro: 36, carb: 42, fat: 9, profile: .balanced),
        LocalMeal("Lamb + Brown Rice + Roasted Eggplant",
                  "4 oz lamb · ¾ cup rice · 1 cup eggplant",
                  cal: 440, pro: 34, carb: 46, fat: 14, profile: .balanced),
        LocalMeal("Beef and Vegetable Soup + Whole Grain Bread",
                  "2 cups soup · 1 slice whole grain bread",
                  cal: 380, pro: 28, carb: 44, fat: 10, profile: .balanced, gluten: true),
        LocalMeal("Grilled Chicken Caesar Salad + Croutons",
                  "4 oz chicken · 3 cups romaine · 2 tbsp light dressing",
                  cal: 380, pro: 34, carb: 24, fat: 14, profile: .balanced, gluten: true),
        LocalMeal("Beef Fajita Bowl + Brown Rice (no tortilla)",
                  "4 oz beef · ¾ cup rice · peppers · onions",
                  cal: 420, pro: 34, carb: 46, fat: 12, profile: .balanced),
        LocalMeal("Chicken + Chickpea Stew",
                  "4 oz chicken · ½ cup chickpeas · tomato broth · spinach",
                  cal: 400, pro: 36, carb: 38, fat: 10, profile: .balanced),
        LocalMeal("Baked Salmon + Lemon Herb Rice + Green Beans",
                  "5 oz salmon · ¾ cup rice · 1 cup beans",
                  cal: 450, pro: 38, carb: 42, fat: 14, profile: .balanced),
    ]

    // MARK: High Protein — Meals

    static let highProteinMeals: [LocalMeal] = [
        LocalMeal("Grilled Chicken Breast + Steamed Broccoli",
                  "7 oz chicken · 2 cups broccoli",
                  cal: 300, pro: 56, carb: 14, fat: 5, profile: .highProtein),
        LocalMeal("Baked Cod + Steamed Asparagus",
                  "8 oz cod · 10 spears asparagus",
                  cal: 250, pro: 50, carb: 8, fat: 3, profile: .highProtein),
        LocalMeal("Canned Tuna + Celery + Mustard",
                  "2 cans (5 oz each) · 3 stalks celery · mustard",
                  cal: 220, pro: 48, carb: 6, fat: 3, profile: .highProtein),
        LocalMeal("Grilled Tilapia + Cucumber Salad",
                  "7 oz tilapia · 1.5 cups cucumber",
                  cal: 230, pro: 46, carb: 8, fat: 3, profile: .highProtein),
        LocalMeal("Rotisserie Chicken Breast (no skin)",
                  "7 oz skinless breast",
                  cal: 280, pro: 54, carb: 0, fat: 6, profile: .highProtein),
        LocalMeal("Lean Ground Turkey + Cauliflower Rice",
                  "5 oz turkey · 2 cups riced cauliflower",
                  cal: 280, pro: 42, carb: 12, fat: 8, profile: .highProtein),
        LocalMeal("Grilled Shrimp + Zucchini Noodles",
                  "6 oz shrimp · 2 cups zucchini noodles",
                  cal: 220, pro: 38, carb: 10, fat: 4, profile: .highProtein),
        LocalMeal("Baked Chicken Thigh (skinless) + Roasted Mushrooms",
                  "5 oz skinless thigh · 2 cups mushrooms",
                  cal: 290, pro: 44, carb: 10, fat: 10, profile: .highProtein),
        LocalMeal("Lean Ground Beef + Cabbage Stir Fry",
                  "4 oz 95% lean beef · 2 cups cabbage",
                  cal: 280, pro: 38, carb: 10, fat: 9, profile: .highProtein),
        LocalMeal("Egg White Scramble + Spinach + Turkey",
                  "8 egg whites · 2 cups spinach · 2 oz turkey",
                  cal: 250, pro: 44, carb: 6, fat: 3, profile: .highProtein),
    ]

    // MARK: High Protein — Snacks

    static let highProteinSnacks: [LocalMeal] = [
        LocalMeal("Non-fat Greek Yogurt",
                  "1 cup (227g)",
                  cal: 120, pro: 20, carb: 9, fat: 0, profile: .highProtein, snack: true, dairy: true),
        LocalMeal("Canned Tuna Pouch",
                  "1 pouch (2.6 oz), plain",
                  cal: 90, pro: 20, carb: 0, fat: 1, profile: .highProtein, snack: true),
        LocalMeal("Hard Boiled Eggs",
                  "3 large eggs",
                  cal: 210, pro: 18, carb: 2, fat: 14, profile: .highProtein, snack: true),
        LocalMeal("Non-fat Cottage Cheese",
                  "1 cup",
                  cal: 160, pro: 28, carb: 8, fat: 2, profile: .highProtein, snack: true, dairy: true),
        LocalMeal("Deli Turkey Roll-Ups",
                  "4 oz sliced turkey, no bread",
                  cal: 120, pro: 24, carb: 2, fat: 2, profile: .highProtein, snack: true),
        LocalMeal("Protein Bar",
                  "1 bar (~60g)",
                  cal: 200, pro: 20, carb: 22, fat: 7, profile: .highProtein, snack: true),
        LocalMeal("Shrimp Cocktail",
                  "4 oz shrimp + cocktail sauce",
                  cal: 130, pro: 22, carb: 8, fat: 1, profile: .highProtein, snack: true),
        LocalMeal("Edamame",
                  "1 cup shelled",
                  cal: 190, pro: 17, carb: 14, fat: 8, profile: .highProtein, snack: true),
        LocalMeal("Whey Protein Shake",
                  "1 scoop + water",
                  cal: 130, pro: 25, carb: 4, fat: 2, profile: .highProtein, snack: true, dairy: true),
        LocalMeal("Beef Jerky",
                  "1.5 oz",
                  cal: 160, pro: 22, carb: 6, fat: 6, profile: .highProtein, snack: true),
    ]

    // MARK: High Carb — Meals

    static let highCarbMeals: [LocalMeal] = [
        LocalMeal("Oatmeal + Banana + Honey",
                  "1.5 cups cooked oats · 1 banana · 1 tsp honey",
                  cal: 380, pro: 10, carb: 78, fat: 5, profile: .highCarb, gluten: true),
        LocalMeal("Large Sweet Potato + Cinnamon",
                  "1 large sweet potato · 1 tsp maple syrup",
                  cal: 280, pro: 5, carb: 64, fat: 1, profile: .highCarb),
        LocalMeal("Brown Rice + Roasted Vegetables",
                  "2 cups cooked rice · 1 cup roasted veggies",
                  cal: 380, pro: 9, carb: 80, fat: 3, profile: .highCarb),
        LocalMeal("Pasta + Light Marinara",
                  "2 cups cooked pasta · ½ cup marinara",
                  cal: 440, pro: 14, carb: 86, fat: 5, profile: .highCarb, gluten: true),
        LocalMeal("Baked Potato + Salsa",
                  "1 large potato · ¼ cup salsa",
                  cal: 280, pro: 7, carb: 62, fat: 1, profile: .highCarb),
        LocalMeal("Acai Bowl + Granola + Banana",
                  "acai base · ½ cup granola · 1 banana · berries",
                  cal: 400, pro: 6, carb: 80, fat: 8, profile: .highCarb, gluten: true),
        LocalMeal("Whole Grain Toast + Jam + Banana",
                  "3 slices toast · 2 tbsp jam · 1 banana",
                  cal: 380, pro: 10, carb: 80, fat: 3, profile: .highCarb, gluten: true),
        LocalMeal("Lentils + Brown Rice",
                  "½ cup lentils · 1.5 cups brown rice",
                  cal: 380, pro: 18, carb: 72, fat: 3, profile: .highCarb),
    ]

    // MARK: High Carb — Snacks

    static let highCarbSnacks: [LocalMeal] = [
        LocalMeal("Banana + Dates",
                  "1 large banana · 3 medjool dates",
                  cal: 200, pro: 2, carb: 50, fat: 1, profile: .highCarb, snack: true),
        LocalMeal("Rice Cakes + Jam",
                  "4 rice cakes · 2 tbsp jam",
                  cal: 200, pro: 3, carb: 44, fat: 1, profile: .highCarb, snack: true),
        LocalMeal("Apple + Grapes",
                  "1 medium apple · 1 cup grapes",
                  cal: 150, pro: 1, carb: 38, fat: 0, profile: .highCarb, snack: true),
        LocalMeal("Medjool Dates",
                  "4 dates",
                  cal: 280, pro: 2, carb: 74, fat: 0, profile: .highCarb, snack: true),
        LocalMeal("Orange + Pineapple Chunks",
                  "1 orange · 1 cup pineapple",
                  cal: 140, pro: 2, carb: 36, fat: 0, profile: .highCarb, snack: true),
        LocalMeal("Air-Popped Popcorn",
                  "4 cups",
                  cal: 120, pro: 4, carb: 24, fat: 1, profile: .highCarb, snack: true),
        LocalMeal("Whole Grain Crackers + Salsa",
                  "12 crackers · ½ cup salsa",
                  cal: 200, pro: 4, carb: 38, fat: 3, profile: .highCarb, snack: true, gluten: true),
        LocalMeal("Dried Mango + Raisins Mix",
                  "¼ cup",
                  cal: 130, pro: 1, carb: 32, fat: 0, profile: .highCarb, snack: true),
    ]

    // MARK: High Fat — Meals

    static let highFatMeals: [LocalMeal] = [
        LocalMeal("Salmon + Avocado Mixed Greens Salad",
                  "5 oz salmon · ½ avocado · 3 cups mixed greens",
                  cal: 400, pro: 36, carb: 8, fat: 26, profile: .highFat),
        LocalMeal("Whole Egg Omelette + Avocado",
                  "3 whole eggs · ½ avocado · mushrooms · peppers",
                  cal: 380, pro: 22, carb: 10, fat: 30, profile: .highFat),
        LocalMeal("Sardines in Olive Oil + Roasted Veggies",
                  "1 can sardines · 1 cup roasted veggies",
                  cal: 300, pro: 20, carb: 10, fat: 20, profile: .highFat),
        LocalMeal("Mackerel + Olive Oil + Roasted Zucchini",
                  "5 oz mackerel · 1 tbsp olive oil · 1 cup zucchini",
                  cal: 360, pro: 32, carb: 8, fat: 24, profile: .highFat),
        LocalMeal("Chicken + Almond Butter Sauce + Stir Fry Veggies",
                  "4 oz chicken · 2 tbsp almond butter sauce · veggies",
                  cal: 380, pro: 34, carb: 12, fat: 24, profile: .highFat),
        LocalMeal("Egg + Avocado + Turkey Bacon Skillet",
                  "2 whole eggs · ½ avocado · 2 turkey bacon strips",
                  cal: 360, pro: 22, carb: 8, fat: 28, profile: .highFat),
        LocalMeal("Grilled Salmon + Walnut Pesto + Zucchini",
                  "5 oz salmon · 2 tbsp walnut pesto · 1 cup zucchini",
                  cal: 420, pro: 38, carb: 6, fat: 28, profile: .highFat),
        LocalMeal("Keto Chicken Bowl + Cheese + Olive Oil",
                  "4 oz chicken · 1 oz cheese · 1 tbsp olive oil · salad",
                  cal: 400, pro: 34, carb: 6, fat: 28, profile: .highFat, dairy: true),
    ]

    // MARK: High Fat — Snacks

    static let highFatSnacks: [LocalMeal] = [
        LocalMeal("Mixed Nuts",
                  "¼ cup",
                  cal: 200, pro: 5, carb: 8, fat: 18, profile: .highFat, snack: true),
        LocalMeal("Half Avocado",
                  "½ avocado, salt + lime",
                  cal: 120, pro: 1, carb: 6, fat: 11, profile: .highFat, snack: true),
        LocalMeal("Almond Butter",
                  "2 tbsp, plain",
                  cal: 200, pro: 7, carb: 6, fat: 18, profile: .highFat, snack: true),
        LocalMeal("Olives",
                  "20 olives",
                  cal: 100, pro: 1, carb: 4, fat: 10, profile: .highFat, snack: true),
        LocalMeal("Macadamia Nuts",
                  "¼ cup",
                  cal: 250, pro: 3, carb: 5, fat: 26, profile: .highFat, snack: true),
        LocalMeal("Peanut Butter + Celery",
                  "2 tbsp peanut butter · 4 celery stalks",
                  cal: 210, pro: 8, carb: 8, fat: 17, profile: .highFat, snack: true),
        LocalMeal("Dark Chocolate + Almonds",
                  "1 oz dark chocolate · 12 almonds",
                  cal: 250, pro: 5, carb: 18, fat: 18, profile: .highFat, snack: true),
        LocalMeal("Tahini + Cucumber",
                  "2 tbsp tahini · 1 cup cucumber slices",
                  cal: 180, pro: 5, carb: 8, fat: 14, profile: .highFat, snack: true),
    ]

    // MARK: High Protein + Carb (low fat)

    static let highProteinCarb: [LocalMeal] = [
        LocalMeal("Chicken + White Rice Bowl",
                  "5 oz chicken · 1.5 cups cooked white rice",
                  cal: 450, pro: 42, carb: 54, fat: 6, profile: .highProteinCarb),
        LocalMeal("Turkey Sandwich on Whole Grain",
                  "4 oz turkey · 2 slices bread · mustard · lettuce",
                  cal: 380, pro: 36, carb: 40, fat: 8, profile: .highProteinCarb, gluten: true),
        LocalMeal("Shrimp + Rice Noodles + Stir Fry Veggies",
                  "5 oz shrimp · 1.5 cups rice noodles · veggies",
                  cal: 420, pro: 36, carb: 54, fat: 6, profile: .highProteinCarb),
        LocalMeal("Tuna + Rice Cakes + Cucumber",
                  "1 can tuna · 6 rice cakes · 1 cup cucumber",
                  cal: 300, pro: 32, carb: 38, fat: 4, profile: .highProteinCarb),
        LocalMeal("Chicken + Corn Tortillas + Salsa",
                  "4 oz chicken · 3 corn tortillas · ½ cup salsa",
                  cal: 360, pro: 34, carb: 40, fat: 8, profile: .highProteinCarb),
        LocalMeal("Egg Whites + Sweet Potato Hash",
                  "6 egg whites · 1 medium sweet potato",
                  cal: 320, pro: 30, carb: 44, fat: 2, profile: .highProteinCarb),
        LocalMeal("White Rice + Black Beans + Salsa",
                  "1 cup rice · ½ cup black beans · ¼ cup salsa",
                  cal: 360, pro: 16, carb: 72, fat: 2, profile: .highProteinCarb),
        LocalMeal("Ground Turkey + Lentils + Brown Rice",
                  "3 oz turkey · ¼ cup lentils · ½ cup rice",
                  cal: 380, pro: 34, carb: 46, fat: 8, profile: .highProteinCarb),
        LocalMeal("Non-fat Greek Yogurt + Oats + Honey",
                  "1 cup yogurt · ½ cup oats · 1 tsp honey",
                  cal: 370, pro: 24, carb: 58, fat: 4, profile: .highProteinCarb, dairy: true, gluten: true),
        LocalMeal("Protein Oatmeal (whey + oats + berries)",
                  "1 cup oats · 1 scoop whey · ½ cup berries",
                  cal: 420, pro: 34, carb: 58, fat: 6, profile: .highProteinCarb, dairy: true, gluten: true),
        LocalMeal("Baked Cod + Quinoa + Roasted Tomatoes",
                  "6 oz cod · ¾ cup quinoa · ½ cup tomatoes",
                  cal: 360, pro: 38, carb: 38, fat: 5, profile: .highProteinCarb),
        LocalMeal("Chicken + Chickpeas + Brown Rice",
                  "4 oz chicken · ½ cup chickpeas · ½ cup rice",
                  cal: 440, pro: 38, carb: 52, fat: 6, profile: .highProteinCarb),
    ]

    // MARK: High Protein + Fat (low carb)

    static let highProteinFat: [LocalMeal] = [
        LocalMeal("Grilled Salmon + Avocado + Mixed Greens",
                  "5 oz salmon · ½ avocado · 2 cups greens",
                  cal: 430, pro: 40, carb: 8, fat: 26, profile: .highProteinFat),
        LocalMeal("Whole Egg Scramble + Turkey Sausage",
                  "3 whole eggs · 2 turkey sausage links",
                  cal: 380, pro: 30, carb: 4, fat: 28, profile: .highProteinFat),
        LocalMeal("Tuna Salad (light mayo) + Cucumber",
                  "2 cans tuna · 2 tbsp light mayo · veggies",
                  cal: 300, pro: 40, carb: 6, fat: 14, profile: .highProteinFat),
        LocalMeal("Ground Beef (85/15) + Avocado + Salad",
                  "4 oz beef · ½ avocado · 2 cups mixed greens",
                  cal: 440, pro: 32, carb: 8, fat: 32, profile: .highProteinFat),
        LocalMeal("Salmon + Olive Oil Roasted Asparagus",
                  "6 oz salmon · 1 tbsp olive oil · 10 asparagus spears",
                  cal: 400, pro: 42, carb: 6, fat: 24, profile: .highProteinFat),
        LocalMeal("Chicken Breast + Almond Butter Sauce + Zucchini",
                  "5 oz chicken · 2 tbsp almond butter · 1 cup zucchini",
                  cal: 400, pro: 46, carb: 10, fat: 20, profile: .highProteinFat),
        LocalMeal("Egg Omelette + Avocado + Deli Turkey",
                  "3 whole eggs · ½ avocado · 2 oz turkey",
                  cal: 380, pro: 30, carb: 6, fat: 28, profile: .highProteinFat),
        LocalMeal("Mackerel + Hard Boiled Eggs + Spinach",
                  "4 oz mackerel · 2 eggs · 2 cups spinach",
                  cal: 360, pro: 36, carb: 4, fat: 22, profile: .highProteinFat),
        LocalMeal("Grilled Chicken + Mixed Nuts + Arugula Salad",
                  "4 oz chicken · 1 oz mixed nuts · 3 cups arugula",
                  cal: 380, pro: 40, carb: 8, fat: 22, profile: .highProteinFat),
        LocalMeal("Smoked Salmon + Cream Cheese + Cucumber",
                  "3 oz smoked salmon · 2 tbsp cream cheese · cucumber",
                  cal: 240, pro: 22, carb: 4, fat: 16, profile: .highProteinFat, dairy: true),
        LocalMeal("Sardines + Avocado + Cherry Tomatoes",
                  "1 can sardines · ½ avocado · ½ cup cherry tomatoes",
                  cal: 320, pro: 26, carb: 8, fat: 22, profile: .highProteinFat),
        LocalMeal("Chicken Thighs (skinless) + Walnut Salad",
                  "5 oz chicken · ¼ cup walnuts · 2 cups spinach",
                  cal: 420, pro: 42, carb: 6, fat: 26, profile: .highProteinFat),
    ]

    // MARK: High Carb + Fat (low protein)

    static let highCarbFat: [LocalMeal] = [
        LocalMeal("Avocado Toast on Whole Grain",
                  "2 slices whole grain · 1 avocado · lemon",
                  cal: 380, pro: 9, carb: 42, fat: 22, profile: .highCarbFat, gluten: true),
        LocalMeal("Peanut Butter + Banana Smoothie",
                  "2 tbsp PB · 2 bananas · almond milk",
                  cal: 420, pro: 10, carb: 56, fat: 18, profile: .highCarbFat),
        LocalMeal("Sweet Potato + Almond Butter",
                  "1 large sweet potato · 2 tbsp almond butter",
                  cal: 360, pro: 9, carb: 54, fat: 18, profile: .highCarbFat),
        LocalMeal("Trail Mix (nuts + dried fruit)",
                  "⅓ cup — almonds, cashews, dried mango",
                  cal: 280, pro: 7, carb: 30, fat: 16, profile: .highCarbFat),
        LocalMeal("Brown Rice + Tahini + Roasted Veggies",
                  "1 cup rice · 2 tbsp tahini · 1 cup roasted veggies",
                  cal: 420, pro: 12, carb: 60, fat: 16, profile: .highCarbFat),
        LocalMeal("Whole Grain Pasta + Pesto",
                  "1.5 cups pasta · 2 tbsp pesto",
                  cal: 440, pro: 12, carb: 62, fat: 18, profile: .highCarbFat, dairy: true, gluten: true),
        LocalMeal("Oatmeal + Peanut Butter + Banana",
                  "1 cup oats · 2 tbsp PB · 1 banana",
                  cal: 460, pro: 14, carb: 64, fat: 18, profile: .highCarbFat, gluten: true),
        LocalMeal("Banana + Almond Butter + Dark Chocolate",
                  "1 banana · 2 tbsp almond butter · ½ oz dark chocolate",
                  cal: 320, pro: 6, carb: 40, fat: 16, profile: .highCarbFat),
        LocalMeal("Granola + Coconut Milk + Berries",
                  "½ cup granola · ¾ cup coconut milk · ½ cup berries",
                  cal: 380, pro: 6, carb: 52, fat: 18, profile: .highCarbFat, gluten: true),
        LocalMeal("Whole Grain Waffles + Peanut Butter",
                  "2 waffles · 2 tbsp peanut butter",
                  cal: 380, pro: 10, carb: 50, fat: 16, profile: .highCarbFat, gluten: true),
    ]

    // MARK: Components (for dynamic combining)

    static let proteinComponents: [FoodComponent] = [
        FoodComponent("Grilled Chicken Breast",   "5 oz", cal: 250, pro: 46, carb: 0,  fat: 5,  macro: .protein),
        FoodComponent("Canned Tuna",              "1 can (5 oz)", cal: 110, pro: 25, carb: 0, fat: 1, macro: .protein),
        FoodComponent("Baked Salmon",             "4 oz", cal: 230, pro: 28, carb: 0,  fat: 12, macro: .protein),
        FoodComponent("Cooked Shrimp",            "5 oz", cal: 140, pro: 28, carb: 2,  fat: 2,  macro: .protein),
        FoodComponent("Lean Ground Turkey",       "4 oz", cal: 180, pro: 24, carb: 0,  fat: 9,  macro: .protein),
        FoodComponent("Rotisserie Chicken Breast","4 oz", cal: 180, pro: 34, carb: 0,  fat: 4,  macro: .protein),
        FoodComponent("Non-fat Greek Yogurt",     "¾ cup", cal: 90, pro: 16, carb: 7,  fat: 0,  macro: .protein, dairy: true),
        FoodComponent("Beef Jerky",               "1.5 oz", cal: 160, pro: 22, carb: 6, fat: 6, macro: .protein),
        FoodComponent("Deli Turkey",              "3 oz", cal: 90,  pro: 18, carb: 2,  fat: 1,  macro: .protein),
        FoodComponent("Non-fat Cottage Cheese",   "½ cup", cal: 90, pro: 14, carb: 5,  fat: 1,  macro: .protein, dairy: true),
        FoodComponent("Baked Cod",                "5 oz", cal: 130, pro: 28, carb: 0,  fat: 1,  macro: .protein),
        FoodComponent("Hard Boiled Eggs",         "3 eggs", cal: 210, pro: 18, carb: 2, fat: 14, macro: .protein),
        FoodComponent("Edamame",                  "¾ cup shelled", cal: 150, pro: 13, carb: 11, fat: 6, macro: .protein),
        FoodComponent("Protein Shake",            "1 scoop + water", cal: 130, pro: 25, carb: 4, fat: 2, macro: .protein, dairy: true),
        FoodComponent("Grilled Tilapia",          "5 oz", cal: 145, pro: 30, carb: 0,  fat: 3,  macro: .protein),
    ]

    static let carbComponents: [FoodComponent] = [
        FoodComponent("Brown Rice",        "1 cup cooked",  cal: 220, pro: 5, carb: 46, fat: 2, macro: .carbs),
        FoodComponent("Sweet Potato",      "1 medium",      cal: 180, pro: 4, carb: 42, fat: 0, macro: .carbs),
        FoodComponent("Cooked Quinoa",     "¾ cup",         cal: 170, pro: 6, carb: 30, fat: 3, macro: .carbs),
        FoodComponent("Banana",            "1 large",       cal: 120, pro: 1, carb: 30, fat: 0, macro: .carbs),
        FoodComponent("Whole Grain Toast", "2 slices",      cal: 160, pro: 6, carb: 30, fat: 2, macro: .carbs, gluten: true),
        FoodComponent("Oatmeal",           "1 cup cooked",  cal: 170, pro: 6, carb: 30, fat: 3, macro: .carbs, gluten: true),
        FoodComponent("Cooked Lentils",    "½ cup",         cal: 120, pro: 9, carb: 20, fat: 0, macro: .carbs),
        FoodComponent("Medjool Dates",     "3 dates",       cal: 200, pro: 2, carb: 54, fat: 0, macro: .carbs),
        FoodComponent("Rice Cakes",        "4 cakes",       cal: 140, pro: 2, carb: 30, fat: 1, macro: .carbs),
        FoodComponent("Corn Tortillas",    "2 tortillas",   cal: 120, pro: 3, carb: 24, fat: 2, macro: .carbs),
        FoodComponent("Baked Potato",      "1 medium",      cal: 160, pro: 4, carb: 36, fat: 0, macro: .carbs),
        FoodComponent("Apple",             "1 medium",      cal: 95,  pro: 0, carb: 25, fat: 0, macro: .carbs),
    ]

    static let fatComponents: [FoodComponent] = [
        FoodComponent("Half Avocado",     "½ fruit",       cal: 120, pro: 1, carb: 6, fat: 11, macro: .fat),
        FoodComponent("Mixed Nuts",       "¼ cup",         cal: 200, pro: 5, carb: 8, fat: 18, macro: .fat),
        FoodComponent("Olive Oil Drizzle","1 tbsp",        cal: 120, pro: 0, carb: 0, fat: 14, macro: .fat),
        FoodComponent("Almond Butter",    "2 tbsp",        cal: 200, pro: 7, carb: 6, fat: 18, macro: .fat),
        FoodComponent("Peanut Butter",    "2 tbsp",        cal: 190, pro: 8, carb: 6, fat: 16, macro: .fat),
        FoodComponent("Tahini",           "2 tbsp",        cal: 180, pro: 5, carb: 8, fat: 16, macro: .fat),
        FoodComponent("Olives",           "20 olives",     cal: 100, pro: 1, carb: 4, fat: 10, macro: .fat),
        FoodComponent("Walnut Halves",    "¼ cup",         cal: 190, pro: 4, carb: 4, fat: 18, macro: .fat),
        FoodComponent("Macadamia Nuts",   "3 tbsp",        cal: 190, pro: 2, carb: 4, fat: 20, macro: .fat),
        FoodComponent("Dark Chocolate",   "1 oz",          cal: 170, pro: 2, carb: 16, fat: 12, macro: .fat),
        FoodComponent("Coconut Flakes",   "3 tbsp",        cal: 100, pro: 1, carb: 6,  fat: 9, macro: .fat),
        FoodComponent("Shredded Cheddar", "1 oz",          cal: 110, pro: 7, carb: 0,  fat: 9, macro: .fat, dairy: true),
    ]
}
