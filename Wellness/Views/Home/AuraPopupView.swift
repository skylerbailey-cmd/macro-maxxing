//
//  AuraPopupView.swift
//  Wellness
//

import SwiftUI
import SwiftData

struct AuraPopupView: View {
    let award:       UserSettings.AuraAward
    let auraLevel:   Int
    let auraTitle:   String
    let totalPoints: Int
    let userSettings: UserSettings
    let onDismiss:   () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var scale:           CGFloat = 0.3
    @State private var opacity:         Double  = 0
    @State private var bgOpacity:       Double  = 0
    @State private var postedToFeed     = false
    @State private var showingEditor    = false

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity * 0.60)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("⭐")
                    .font(.system(size: 60))

                Text("+\(award.points) Aura")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.2),
                                     Color(red: 1.0, green: 0.55, blue: 0.15)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Text(award.reason)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                // Current standing
                VStack(spacing: 4) {
                    Text("Level \(auraLevel)\(auraTitle.isEmpty ? "" : " · \(auraTitle)")")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                    Text("\(totalPoints) total aura pts")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.40))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(Color(red: 0.13, green: 0.10, blue: 0.22))
                .cornerRadius(10)

                // Hype message
                Text(award.message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                // Post to Feed button
                Button {
                    showingEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: postedToFeed ? "checkmark.circle.fill" : "person.2.fill")
                        Text(postedToFeed ? "Posted!" : "Post to Feed")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        postedToFeed
                            ? Color.green.opacity(0.30)
                            : Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.35)
                    )
                    .cornerRadius(14)
                }
                .disabled(postedToFeed)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.16, green: 0.10, blue: 0.28),
                                 Color(red: 0.07, green: 0.04, blue: 0.14)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.35), radius: 30)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.40), lineWidth: 1.5)
            )
            .padding(.horizontal, 28)
            .overlay(alignment: .topTrailing) {
                Button(action: animatedDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.50))
                        .padding(14)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.15)) { bgOpacity = 1 }
            withAnimation(.spring(duration: 0.50, bounce: 0.40).delay(0.05)) {
                scale = 1.0; opacity = 1.0
            }
        }
        .sheet(isPresented: $showingEditor) {
            AuraPostEditorView(
                defaultTitle:   award.reason,
                defaultMessage: "\(award.message) +\(award.points) aura pts"
            ) { title, message, image in
                postToFeed(title: title, message: message, image: image)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func postToFeed(title: String, message: String, image: UIImage? = nil) {
        guard !postedToFeed else { return }
        let post = SocialPost(
            authorID:          userSettings.userID,
            authorUsername:    userSettings.username.isEmpty ? "me" : userSettings.username,
            authorDisplayName: userSettings.name,
            memeEmoji:         "⭐ +\(award.points)",
            memeHeadline:      title,
            memeSub:           message,
            macroDate:         Date(),
            totalCalories: 0, goalCalories: 0,
            totalProtein:  0, goalProtein:  0,
            totalCarbs:    0, goalCarbs:    0,
            totalFat:      0, goalFat:      0
        )
        post.isCustomPost     = false
        post.authorAuraLevel  = userSettings.auraLevel
        post.authorAuraPoints = userSettings.auraPoints
        post.authorProfileImageData = userSettings.profileImageData
        post.imageData        = image?.jpegData(compressionQuality: 0.8)
        modelContext.insert(post)
        withAnimation { postedToFeed = true }
    }

    // MARK: - Dismiss

    private func animatedDismiss() {
        withAnimation(.easeIn(duration: 0.15)) {
            scale = 0.85; opacity = 0; bgOpacity = 0
        }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            onDismiss()
        }
    }
}

// MARK: - Aura Post Editor

private struct AuraPostEditorView: View {
    let defaultTitle:   String
    let defaultMessage: String
    let onPost: (String, String, UIImage?) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?
    @State private var titleText:    String  = ""
    @State private var messageText:  String  = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera    = false
    @State private var showError     = false

    private enum Field: Hashable { case title, message }

    private let pageBg = Color(red: 0.07, green: 0.05, blue: 0.12)
    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)
    private let gold   = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Title field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.50))
                            TextField("", text: $titleText, prompt:
                                Text("e.g. \"sigma streak unlocked fr 🔥\"")
                                    .foregroundStyle(.white.opacity(0.28))
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(cardBg)
                            .cornerRadius(12)
                            .focused($focus, equals: .title)
                            .submitLabel(.next)
                            .onSubmit { focus = .message }
                            .onChange(of: titleText) { _, _ in if showError { showError = false } }
                        }

                        // Message field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.50))
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty {
                                    Text("tell the feed what you did, no cap. the mewing paid off, the grind was real, whatever…")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.28))
                                        .padding(14)
                                }
                                TextEditor(text: $messageText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 110)
                                    .padding(10)
                                    .focused($focus, equals: .message)
                            }
                            .background(cardBg)
                            .cornerRadius(12)
                            .onChange(of: messageText) { _, _ in if showError { showError = false } }
                        }

                        // Photo
                        if let img = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .clipped()
                                    .cornerRadius(12)
                                Button { selectedImage = nil } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .shadow(radius: 4)
                                        .padding(8)
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
                                .padding(.vertical, 12)
                                .background(cardBg)
                                .cornerRadius(12)
                            }
                            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        }

                        // Error
                        if showError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text("Both fields are required before you can post, bro.")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.10))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Write Your Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        let t = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let m = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if t.isEmpty || m.isEmpty {
                            showError = true
                        } else {
                            onPost(t, m, selectedImage)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(gold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focus = nil }.fontWeight(.semibold)
                }
            }
            .onAppear {
                titleText   = defaultTitle
                messageText = defaultMessage
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $selectedImage)
        }
    }
}
