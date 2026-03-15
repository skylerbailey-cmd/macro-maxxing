//
//  MultiPhotoSection.swift
//  Wellness
//

import SwiftUI

// MARK: - PostPhoto

struct PostPhoto: Identifiable {
    let id    = UUID()
    let image: UIImage
}

// MARK: - MultiPhotoSection

/// Reusable photo-picker section for post editors. Up to 4 photos per post.
struct MultiPhotoSection: View {
    @Binding var photos: [PostPhoto]

    @State private var newImage:      UIImage?   = nil
    @State private var showCamera     = false
    @State private var showLibrary    = false
    @State private var croppingPhoto: PostPhoto? = nil

    private let cardBg = Color(red: 0.13, green: 0.10, blue: 0.22)

    private var canAddMore: Bool { photos.count < 4 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnails
            if !photos.isEmpty {
                thumbnailStrip
            }

            // Action buttons
            if canAddMore {
                HStack(spacing: 10) {
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(photos.isEmpty ? "Take Photo" : "Add Photo")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white.opacity(0.70))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(cardBg)
                        .cornerRadius(12)
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    Button {
                        showLibrary = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Library")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white.opacity(0.70))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(cardBg)
                        .cornerRadius(12)
                    }
                }
            }

            if photos.count >= 4 {
                Text("Max 4 photos reached")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.30))
            }
        }
        .onChange(of: newImage) { _, img in
            guard let img else { return }
            photos.append(PostPhoto(image: img))
            newImage = nil
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $newImage)
        }
        .sheet(isPresented: $showLibrary) {
            ImagePickerView(sourceType: .photoLibrary, selectedImage: $newImage)
        }
        .fullScreenCover(item: $croppingPhoto) { photo in
            CropImageView(
                image: photo.image,
                onCrop: { cropped in
                    if let idx = photos.firstIndex(where: { $0.id == photo.id }) {
                        photos[idx] = PostPhoto(image: cropped)
                    }
                    croppingPhoto = nil
                },
                onCancel: { croppingPhoto = nil }
            )
        }
    }

    // MARK: Thumbnail strip

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos) { photo in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)

                        // Delete button (top-right)
                        Button {
                            photos.removeAll { $0.id == photo.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)
                                .padding(4)
                        }

                        // Crop button (bottom-left)
                        Button {
                            croppingPhoto = photo
                        } label: {
                            Image(systemName: "crop")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                .padding(4)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

// MARK: - PostImagesView

/// Renders 1–4 images in a responsive grid layout for feed/detail display.
struct PostImagesView: View {
    let imageDatas: [Data]

    private var images: [UIImage] {
        imageDatas.compactMap { UIImage(data: $0) }
    }

    var body: some View {
        let imgs = images
        switch imgs.count {
        case 1:
            singleImage(imgs[0])
        case 2:
            doubleImages(imgs[0], imgs[1])
        case 3:
            tripleImages(imgs[0], imgs[1], imgs[2])
        default:
            if imgs.count >= 4 {
                quadImages(imgs[0], imgs[1], imgs[2], imgs[3])
            }
        }
    }

    private func singleImage(_ img: UIImage) -> some View {
        Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .cornerRadius(10)
    }

    private func doubleImages(_ a: UIImage, _ b: UIImage) -> some View {
        HStack(spacing: 3) {
            ForEach([a, b], id: \.self) { img in
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
            }
        }
        .cornerRadius(10)
    }

    private func tripleImages(_ a: UIImage, _ b: UIImage, _ c: UIImage) -> some View {
        VStack(spacing: 3) {
            Image(uiImage: a)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()
            HStack(spacing: 3) {
                ForEach([b, c], id: \.self) { img in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .clipped()
                }
            }
        }
        .cornerRadius(10)
    }

    private func quadImages(_ a: UIImage, _ b: UIImage, _ c: UIImage, _ d: UIImage) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                ForEach([a, b], id: \.self) { img in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 110)
                        .clipped()
                }
            }
            HStack(spacing: 3) {
                ForEach([c, d], id: \.self) { img in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 110)
                        .clipped()
                }
            }
        }
        .cornerRadius(10)
    }
}
