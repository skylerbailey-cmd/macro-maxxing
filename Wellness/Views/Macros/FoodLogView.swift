//
//  FoodLogView.swift
//  Wellness
//

import SwiftUI
import SwiftData

struct FoodLogView: View {
    @Bindable var viewModel: FoodLogViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Source buttons
                HStack(spacing: 12) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            viewModel.showingCamera = true
                        }
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    Button {
                        viewModel.showingPhotoLibrary = true
                    } label: {
                        Label("Photo Library", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                // Image preview
                Group {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 250)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }

                // Analyze button
                Button {
                    Task { await viewModel.analyzeImage() }
                } label: {
                    Text("Analyze")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedImage == nil || viewModel.analysisState == .analyzing)

                // Progress / results
                switch viewModel.analysisState {
                case .analyzing:
                    ProgressView("Analyzing food...")
                        .padding()

                case .result, .error:
                    VStack(spacing: 10) {
                        HStack {
                            Text("Food")
                                .frame(width: 80, alignment: .leading)
                            TextField("Food name", text: $viewModel.foodName)
                                .textFieldStyle(.roundedBorder)
                        }
                        MacroFieldView(label: "Calories", unit: "kcal", value: $viewModel.caloriesText)
                        MacroFieldView(label: "Protein", unit: "g", value: $viewModel.proteinText)
                        MacroFieldView(label: "Carbs", unit: "g", value: $viewModel.carbsText)
                        MacroFieldView(label: "Fat", unit: "g", value: $viewModel.fatText)

                        if case .error(let message) = viewModel.analysisState {
                            Text(message)
                                .foregroundStyle(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }

                        HStack(spacing: 12) {
                            Button("Discard") {
                                viewModel.discardEntry()
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)

                            Button("Save") {
                                viewModel.saveEntry()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 4)
                    }

                case .idle:
                    EmptyView()
                }
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $viewModel.selectedImage)
        }
        .sheet(isPresented: $viewModel.showingPhotoLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $viewModel.selectedImage)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodEntry.self, configurations: config)
    let vm = FoodLogViewModel(modelContext: container.mainContext)
    return NavigationStack {
        FoodLogView(viewModel: vm)
            .navigationTitle("Food Log")
    }
}
