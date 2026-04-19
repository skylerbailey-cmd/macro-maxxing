//
//  PhotoMarkupView.swift
//  Wellness
//
//  Full-screen photo markup editor. Lets the user draw on the image with
//  PencilKit and place/edit draggable text labels. The final composite
//  (image + drawings + text) is flattened into a single UIImage on save.
//

import SwiftUI
import PencilKit

struct PhotoMarkupView: View {

    let image: UIImage
    let onSave:   (UIImage) -> Void
    let onCancel: () -> Void

    // MARK: - Drawing

    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()

    // MARK: - Text overlays

    @State private var textItems: [TextItem] = []
    @State private var editingItemID: UUID?  = nil
    @State private var editText: String      = ""

    struct TextItem: Identifiable {
        let id = UUID()
        var text: String
        var position: CGSize    // offset from center
        var color: Color = .white
        var fontSize: CGFloat = 28
    }

    // MARK: - Display

    @State private var imageSize: CGSize = .zero

    private let pageBg = Color.black

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            GeometryReader { geo in
                let fitted = fittedSize(in: geo.size)
                let origin = CGPoint(
                    x: (geo.size.width  - fitted.width)  / 2,
                    y: (geo.size.height - fitted.height) / 2
                )

                ZStack {
                    // Base image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: fitted.width, height: fitted.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    // PencilKit canvas (transparent, overlays the image)
                    CanvasRepresentable(canvasView: $canvasView, toolPicker: $toolPicker)
                        .frame(width: fitted.width, height: fitted.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    // Draggable text items
                    ForEach($textItems) { $item in
                        DraggableTextView(
                            item: $item,
                            onTap: {
                                editingItemID = item.id
                                editText = item.text
                            },
                            onDelete: {
                                textItems.removeAll { $0.id == item.id }
                            }
                        )
                        .position(
                            x: geo.size.width  / 2 + item.position.width,
                            y: geo.size.height / 2 + item.position.height
                        )
                    }
                }
                .onAppear {
                    imageSize = fitted
                }
            }

            // Toolbar
            toolbar

            // Text edit sheet
            if editingItemID != nil {
                textEditOverlay
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        VStack {
            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }

                Spacer()

                // Add text
                Button {
                    let newItem = TextItem(
                        text: "Text",
                        position: .zero
                    )
                    textItems.append(newItem)
                    editingItemID = newItem.id
                    editText = newItem.text
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "textformat")
                            .font(.system(size: 14, weight: .bold))
                        Text("Text")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                Spacer()

                // Undo
                Button {
                    canvasView.undoManager?.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }

                Button(action: saveComposite) {
                    Text("Done")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(ThemeStore.shared.accent)
                        .clipShape(Capsule())
                }
                .padding(.trailing, 8)
            }
            .padding(.top, 56)

            Spacer()

            Text("Draw with your finger · Tap text to edit · Drag to reposition")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.40))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Text edit overlay

    private static let colorOptions: [Color] = [
        .white, .black, .yellow, .red, .green, .cyan, .orange, .pink
    ]

    private var textEditOverlay: some View {
        ZStack {
            Color.black.opacity(0.60)
                .ignoresSafeArea()
                .onTapGesture { commitTextEdit() }

            VStack(spacing: 16) {
                textEditField
                colorPicker
                textEditDoneButton
            }
        }
    }

    private var textEditField: some View {
        TextField("Enter text", text: $editText)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(16)
            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 40)
    }

    private var colorPicker: some View {
        HStack(spacing: 12) {
            ForEach(Self.colorOptions, id: \.self) { color in
                colorDot(color)
            }
        }
    }

    private func colorDot(_ color: Color) -> some View {
        let isSelected = currentEditItem?.color == color
        return Circle()
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(Color.white.opacity(isSelected ? 1 : 0.2), lineWidth: 2))
            .onTapGesture {
                if let idx = textItems.firstIndex(where: { $0.id == editingItemID }) {
                    textItems[idx].color = color
                }
            }
    }

    private var textEditDoneButton: some View {
        Button("Done") { commitTextEdit() }
            .font(.headline.weight(.bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(ThemeStore.shared.accent, in: Capsule())
    }

    private var currentEditItem: TextItem? {
        textItems.first { $0.id == editingItemID }
    }

    private func commitTextEdit() {
        if let idx = textItems.firstIndex(where: { $0.id == editingItemID }) {
            if editText.trimmingCharacters(in: .whitespaces).isEmpty {
                textItems.remove(at: idx)
            } else {
                textItems[idx].text = editText
            }
        }
        editingItemID = nil
        editText = ""
    }

    // MARK: - Composite render

    private func saveComposite() {
        // Hide tool picker before rendering
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        canvasView.resignFirstResponder()

        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let composite = renderer.image { ctx in
            // Draw base image
            image.draw(in: CGRect(origin: .zero, size: size))

            // Scale factor from display to image pixels
            let scaleX = size.width  / imageSize.width
            let scaleY = size.height / imageSize.height

            // Draw PencilKit strokes
            let drawing = canvasView.drawing
            let drawingImage = drawing.image(from: CGRect(origin: .zero, size: imageSize), scale: UIScreen.main.scale)
            drawingImage.draw(in: CGRect(origin: .zero, size: size))

            // Draw text items
            for item in textItems {
                let uiColor = UIColor(item.color)
                let scaledFontSize = item.fontSize * scaleX
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: scaledFontSize, weight: .bold),
                    .foregroundColor: uiColor,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -3.0
                ]
                let str = NSAttributedString(string: item.text, attributes: attrs)
                let textSize = str.size()
                let x = size.width  / 2 + item.position.width  * scaleX - textSize.width  / 2
                let y = size.height / 2 + item.position.height * scaleY - textSize.height / 2
                str.draw(at: CGPoint(x: x, y: y))
            }
        }
        onSave(composite)
    }

    // MARK: - Helpers

    private func fittedSize(in container: CGSize) -> CGSize {
        let avW = container.width
        let avH = container.height - 140 // clearance for toolbars
        guard avW > 0, avH > 0 else { return CGSize(width: 300, height: 300) }
        let aspect = image.size.width / image.size.height
        if aspect > avW / avH {
            return CGSize(width: avW, height: avW / aspect)
        } else {
            return CGSize(width: avH * aspect, height: avH)
        }
    }
}

// MARK: - PencilKit UIViewRepresentable

private struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .white, width: 5)

        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// MARK: - Draggable Text View

private struct DraggableTextView: View {
    @Binding var item: PhotoMarkupView.TextItem
    let onTap:    () -> Void
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Text(item.text)
            .font(.system(size: item.fontSize, weight: .bold))
            .foregroundStyle(item.color)
            .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .topTrailing) {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .offset(x: 8, y: -8)
            }
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { val in
                        dragOffset = val.translation
                    }
                    .onEnded { val in
                        item.position.width  += val.translation.width
                        item.position.height += val.translation.height
                        dragOffset = .zero
                    }
            )
            .onTapGesture { onTap() }
    }
}
