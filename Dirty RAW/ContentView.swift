//
//  ContentView.swift
//  Dirty RAW
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var images: [RAWImage] = []
    @State private var selectedImage: RAWImage?
    @State private var isImportingFile = false
    @State private var isImportingFolder = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isDropTargeted = false
    @State private var selectedTab = 0  // 0 = EXIF, 1 = Adjustments

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar with image list
            List(images, id: \.id, selection: $selectedImage) { image in
                HStack {
                    if let thumb = image.thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipped()
                            .cornerRadius(4)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .cornerRadius(4)
                    }
                    Text(image.url.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .tag(image)
                .contextMenu {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([image.url])
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                }
            }
            .navigationTitle("Images (\(images.count))")
        } detail: {
            HStack(spacing: 0) {
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                detailView
                    .frame(width: 280)
                    .background(.regularMaterial)
            }
        }
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: [UTType(filenameExtension: "nef")!],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .fileImporter(
            isPresented: $isImportingFolder,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFolderImport(result)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onChange(of: selectedImage) { _, newImage in
            newImage?.load()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { isImportingFile = true }) {
                    Label("Open Files", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("o", modifiers: .command)

                Button(action: { isImportingFolder = true }) {
                    Label("Open Folder", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                if let image = selectedImage {
                    ExportButton(rawImage: image, exportAction: exportTIFF)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileURL)) { notification in
            if let url = notification.object as? URL {
                loadURLs([url])
            }
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 3)
                    .background(Color.accentColor.opacity(0.1))
                    .padding(4)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    defer { group.leave() }
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else {
                        return
                    }
                    urls.append(url)
                }
            }
        }

        group.notify(queue: .main) {
            loadURLs(urls)
        }

        return true
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            loadURLs(urls)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleFolderImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let folderURL = urls.first else { return }
            loadURLs([folderURL])
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func loadURLs(_ urls: [URL]) {
        var nefFiles: [URL] = []

        for url in urls {
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Scan folder for NEF files
                    if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
                        for case let fileURL as URL in enumerator {
                            if isNEFFile(fileURL) {
                                nefFiles.append(fileURL)
                            }
                        }
                    }
                } else if isNEFFile(url) {
                    nefFiles.append(url)
                }
            }
        }

        if nefFiles.isEmpty {
            errorMessage = "No NEF files found"
            showError = true
            return
        }

        // Sort by filename
        nefFiles.sort { $0.lastPathComponent < $1.lastPathComponent }

        // Create RAWImage objects
        let newImages = nefFiles.map { RAWImage(url: $0) }
        images = newImages

        // Select first image
        if let first = images.first {
            selectedImage = first
        }

        // Show/hide sidebar based on number of files
        if images.count > 1 {
            columnVisibility = .all
        } else {
            columnVisibility = .detailOnly
        }
    }

    private func isNEFFile(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "nef"
    }
    
    private func exportTIFF() {
        guard let image = selectedImage?.processedImage ?? selectedImage?.image else {
            errorMessage = "No image to export"
            showError = true
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.tiff]
        panel.nameFieldStringValue = selectedImage?.url.deletingPathExtension().lastPathComponent ?? "export"
        panel.canCreateDirectories = true
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            do {
                try saveTIFF(image: image, to: url)
            } catch {
                errorMessage = "Failed to export TIFF: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func saveTIFF(image: NSImage, to url: URL) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "DirtyRAW", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.tiff.identifier as CFString,
            1,
            nil
        ) else {
            throw NSError(domain: "DirtyRAW", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create TIFF destination"])
        }
        
        let options: [CFString: Any] = [
            kCGImagePropertyTIFFCompression: 1, // No compression
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "DirtyRAW", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize TIFF"])
        }
        
        try data.write(to: url, options: .atomic)
    }

    // MARK: - View Components

    @ViewBuilder
    private var contentView: some View {
        if let selectedImage = selectedImage {
            ImagePreviewView(rawImage: selectedImage)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "photo")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                Text("No Image Loaded")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Open NEF files or a folder, or drag and drop here")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button("Open Files") {
                        isImportingFile = true
                    }
                    Button("Open Folder") {
                        isImportingFolder = true
                    }
                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var detailView: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Info").tag(0)
                Text("Adjust").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            // Tab content
            if selectedTab == 0 {
                EXIFSidebarView(rawImage: selectedImage)
            } else {
                if let image = selectedImage {
                    AdjustmentsView(
                        adjustments: Binding(
                            get: { image.adjustments },
                            set: { newValue in
                                image.adjustments = newValue
                                image.applyAdjustments()
                            }
                        ),
                        imageSize: image.image?.size,
                        onReset: {
                            image.resetAdjustments()
                        }
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Image Loaded")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Open a file to adjust")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

struct ImagePreviewView: View {
    @ObservedObject var rawImage: RAWImage
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showControls = true
    
    private let minScale: CGFloat = 0.1
    private let maxScale: CGFloat = 10.0

    var body: some View {
        Group {
            if rawImage.isLoading {
                ProgressView("Decoding RAW...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let image = rawImage.processedImage ?? rawImage.image {
                ZStack(alignment: .bottom) {
                    // Image with zoom and pan
                    GeometryReader { geometry in
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = scale * value
                                        self.scale = min(max(newScale, minScale), maxScale)
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring(response: 0.3)) {
                                    if scale == 1.0 {
                                        scale = 2.0
                                    } else {
                                        resetView()
                                    }
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    
                    // Processing indicator
                    if rawImage.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }

                    // Control panel
                    if showControls {
                        HStack(spacing: 16) {
                            // Zoom out
                            Button(action: { zoomOut() }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.borderless)
                            .help("Zoom Out")
                            
                            // Zoom percentage
                            Text("\(Int(scale * 100))%")
                                .font(.system(.caption, design: .monospaced))
                                .frame(minWidth: 50)
                                .help("Current Zoom Level")
                            
                            // Zoom in
                            Button(action: { zoomIn() }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.borderless)
                            .help("Zoom In")
                            
                            Divider()
                                .frame(height: 20)
                            
                            // Fit to window
                            Button(action: { resetView() }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.borderless)
                            .help("Fit to Window (Double-click image)")
                            
                            Divider()
                                .frame(height: 20)
                            
                            // Image info
                            Text("\(Int(image.size.width)) × \(Int(image.size.height))")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .help("Image Dimensions")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        .padding(.bottom, 16)
                    }
                }
            } else if let error = rawImage.error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            resetView()
        }
    }
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = min(scale * 1.2, maxScale)
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = max(scale / 1.2, minScale)
        }
    }
    
    private func resetView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    private func actualSize() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}

struct ExportButton: View {
    @ObservedObject var rawImage: RAWImage
    let exportAction: () -> Void

    var body: some View {
        Button(action: exportAction) {
            if rawImage.isLoading {
                Label("Loading...", systemImage: "arrow.clockwise")
            } else {
                Label("Export TIFF", systemImage: "square.and.arrow.up")
            }
        }
        .disabled(rawImage.isLoading || rawImage.image == nil)
    }
}

#Preview {
    ContentView()
}
