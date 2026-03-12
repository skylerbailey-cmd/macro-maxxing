//
//  FoodLogView.swift
//  Wellness
//

import SwiftUI
import SwiftData

// MARK: - Color palette (matches HomeView)

private extension Color {
    static let pageBg    = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let cardBg    = Color(red: 0.13, green: 0.10, blue: 0.22)
    static let purpleHi  = Color(red: 0.65, green: 0.45, blue: 1.00)
    static let macroBlue = Color(red: 0.35, green: 0.75, blue: 1.00)
}

// MARK: - FoodLogView

struct FoodLogView: View {
    @State private var viewModel: FoodLogViewModel
    @Binding var selectedDate: Date
    @State private var showingAnalysisSheet = false

    init(modelContext: ModelContext, selectedDate: Binding<Date>) {
        _viewModel    = State(wrappedValue: FoodLogViewModel(
            modelContext: modelContext,
            selectedDate: selectedDate.wrappedValue
        ))
        _selectedDate = selectedDate
    }

    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                DateNavigatorView(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                if viewModel.todayEntries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.todayEntries) { entry in
                                FoodEntryRow(entry: entry) {
                                    viewModel.deleteEntry(entry)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 100)
                    }
                }
            }

            // FABs — photo library bottom-left, camera bottom-right
            VStack {
                Spacer()
                HStack {
                    CircleFAB(icon: "photo.on.rectangle", color: .macroBlue) {
                        viewModel.showingPhotoLibrary = true
                    }
                    Spacer()
                    CircleFAB(
                        icon: "camera.fill",
                        color: .purpleHi,
                        disabled: !UIImagePickerController.isSourceTypeAvailable(.camera)
                    ) {
                        viewModel.showingCamera = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.selectedDate = selectedDate
            Task { viewModel.loadTodayEntries() }
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.selectedDate = newDate
        }
        .onChange(of: viewModel.selectedImage) { _, newValue in
            if newValue != nil { showingAnalysisSheet = true }
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $viewModel.selectedImage)
        }
        .sheet(isPresented: $viewModel.showingPhotoLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $viewModel.selectedImage)
        }
        .sheet(isPresented: $showingAnalysisSheet, onDismiss: {
            viewModel.discardEntry()
        }) {
            AnalysisSheet(viewModel: viewModel, onSaved: {
                showingAnalysisSheet = false
            })
            .presentationDetents([.large])
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.15))
            Text("No food logged")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.35))
            Text("Tap the camera or photo button below\nto log a meal.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.22))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Analysis Sheet

private struct AnalysisSheet: View {
    @Bindable var viewModel: FoodLogViewModel
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(14)
                            .padding(.horizontal)
                    }

                    switch viewModel.analysisState {
                    case .idle:
                        analyzePrompt
                    case .analyzing:
                        ProgressView("Analyzing food...")
                            .padding(.vertical, 32)
                    case .result, .error:
                        entryFields
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var analyzePrompt: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Analyze this photo?")
                    .font(.headline)
                Text("Claude will identify the food and estimate macros.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                Task { await viewModel.analyzeImage() }
            } label: {
                Text("Analyze")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Button("Enter manually instead") {
                viewModel.analysisState = .result
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var entryFields: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Food")
                    .frame(width: 80, alignment: .leading)
                TextField("Food name", text: $viewModel.foodName)
                    .textFieldStyle(.roundedBorder)
            }
            MacroFieldView(label: "Calories", unit: "kcal", value: $viewModel.caloriesText)
            MacroFieldView(label: "Protein",  unit: "g",    value: $viewModel.proteinText)
            MacroFieldView(label: "Carbs",    unit: "g",    value: $viewModel.carbsText)
            MacroFieldView(label: "Fat",      unit: "g",    value: $viewModel.fatText)

            if case .error(let message) = viewModel.analysisState {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                .padding(.horizontal)
                Button {
                    Task { await viewModel.analyzeImage() }
                } label: {
                    Label("Retry Analysis", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button("Discard") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button("Save") {
                    if viewModel.saveEntry() { onSaved() }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.caloriesText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }
}

// MARK: - Food Entry Row

private struct FoodEntryRow: View {
    let entry: FoodEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let data = entry.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipped()
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.white.opacity(0.30))
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(Int(entry.calories)) kcal  ·  \(Int(entry.protein))g P  ·  \(Int(entry.carbs))g C  ·  \(Int(entry.fat))g F")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(entry.loggedAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.30))

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(14)
    }
}

// MARK: - Circle FAB

private struct CircleFAB: View {
    let icon: String
    let color: Color
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(disabled ? Color.white.opacity(0.15) : color)
                .clipShape(Circle())
                .shadow(color: disabled ? .clear : color.opacity(0.55), radius: 10, y: 4)
        }
        .disabled(disabled)
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    return NavigationStack {
        FoodLogView(
            modelContext: container.mainContext,
            selectedDate: .constant(Calendar.current.startOfDay(for: Date()))
        )
        .navigationTitle("Food Log")
    }
}
