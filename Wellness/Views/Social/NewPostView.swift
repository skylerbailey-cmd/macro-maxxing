//
//  NewPostView.swift
//  Wellness
//

import SwiftUI
import SwiftData

struct NewPostView: View {
    let userSettings: UserSettings

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var titleText  = ""
    @State private var bodyText   = ""
    @State private var image: UIImage?
    @State private var showCamera = false
    @FocusState private var focus: Field?

    private enum Field: Hashable { case title, body }

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Title
                        TextField("Title", text: $titleText)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(cardBg)
                            .cornerRadius(12)
                            .focused($focus, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { focus = .body }

                        // Body
                        ZStack(alignment: .topLeading) {
                            if bodyText.isEmpty {
                                Text("What's on your mind?")
                                    .foregroundStyle(.white.opacity(0.30))
                                    .padding(18)
                            }
                            TextEditor(text: $bodyText)
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 130)
                                .padding(10)
                                .focused($focus, equals: .body)
                        }
                        .background(cardBg)
                        .cornerRadius(12)

                        // Photo
                        if let img = image {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                Button { image = nil } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .shadow(radius: 4)
                                        .padding(10)
                                }
                            }
                        } else {
                            Button { showCamera = true } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                    Text("Add Photo")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(.white.opacity(0.65))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(cardBg)
                                .cornerRadius(12)
                            }
                            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { submit() }
                        .fontWeight(.bold)
                        .disabled(titleText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focus = nil }.fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $image)
        }
    }

    private func submit() {
        let t = titleText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "",
            memeHeadline:      t,
            memeSub:           bodyText.trimmingCharacters(in: .whitespaces),
            macroDate:         Date(),
            totalCalories: 0, goalCalories: 0,
            totalProtein:  0, goalProtein:  0,
            totalCarbs:    0, goalCarbs:    0,
            totalFat:      0, goalFat:      0
        )
        post.isCustomPost    = true
        post.authorAuraLevel = userSettings.auraLevel
        post.authorAuraPoints = userSettings.auraPoints
        post.authorProfileImageData = userSettings.profileImageData
        post.imageData       = image?.jpegData(compressionQuality: 0.8)
        modelContext.insert(post)
        dismiss()
    }
}
