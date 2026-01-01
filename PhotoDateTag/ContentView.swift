//
//  ContentView.swift
//  PhotoDateTag
//
//  Created by WhiteBlade on 12/28/25.
//

import SwiftUI
import MapKit
import AVKit
import ImageIO
import CoreLocation

struct FileItem: Identifiable {
    let id = UUID()
    var url: URL
    var name: String
    let path: String
    let creationDate: Date?
    let exifDate: Date?
    var location: CLLocationCoordinate2D?
    var status: RenameStatus = .pending
    var newName: String?
}

enum RenameStatus {
    case pending, success, failure
}

struct RenameAction {
    let oldURL: URL
    let newURL: URL
    let fileID: UUID
}

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct ContentView: View {
    @State private var files: [FileItem] = []
    @State private var selectedFolder: URL?
    @State private var isRecursive = false
    @State private var selectedFiles: Set<FileItem.ID> = []
    @State private var copyToFolder: URL?
    @State private var currentPreviewIndex = 0
    @State private var showMapPopover = false
    @State private var editingLocationFor: FileItem?
    @State private var renameHistory: [RenameAction] = []
    @State private var mapRegion: MKCoordinateRegion?

    let supportedExtensions = ["jpg", "jpeg", "png", "gif", "mov", "mp4", "avi", "m4v"]
    let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f
    }()
    let renameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy_MMdd_HHmmss"
        return f
    }()

    var body: some View {
        HStack {
            // Left side: File list
            VStack {
                HStack {
                    Button("Select Folder") {
                        selectFolder()
                    }
                    Toggle("Recursive", isOn: $isRecursive)
                }
                .padding()

                HStack {
                    Text("").font(.headline).frame(width: 20)
                    VStack(alignment: .leading) {
                        Text("File Name").font(.headline)
                    }
                    Spacer()
                    Text("Create Date").font(.headline)
                    Text("Taken Date").font(.headline)
                    Text("Location").font(.headline)
                }
                .padding(.horizontal)

                List(files, selection: $selectedFiles) { file in
                    HStack {
                        statusIcon(for: file.status)
                        VStack(alignment: .leading) {
                            Text(file.name)
                            Text(file.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .help(file.path)
                        Spacer()
                        Text(file.creationDate.map { dateFormatter.string(from: $0) } ?? "N/A")
                        Text(file.exifDate.map { dateFormatter.string(from: $0) } ?? "N/A")
                        Text(file.location != nil ? "Yes" : "No")
                    }
                    .contextMenu {
                        Button("Rename Selected") {
                            renameSelected()
                        }
                        if selectedFiles.contains(file.id) {
                            Button("Change Location") {
                                editingLocationFor = file
                                showMapPopover = true
                            }
                        }
                    }
                }
                .onChange(of: selectedFolder) { 
                    scanFolder()
                }
                .onChange(of: isRecursive) { 
                    if selectedFolder != nil {
                        scanFolder()
                    }
                }
                .onChange(of: selectedFiles) { 
                    updateMapRegion()
                }

                HStack {
                    TextField("Copy to folder", text: .constant(copyToFolder?.path ?? ""))
                    Button("Select") {
                        selectCopyFolder()
                    }
                }
                .padding()

                Button("Rename Selected") {
                    renameSelected()
                }

                Button("Undo Last Rename") {
                    undoLastRename()
                }
            }
            .frame(minWidth: 300)

            // Right side: Previews
            VStack {
                let selectedItems = files.filter { selectedFiles.contains($0.id) }
                if !selectedItems.isEmpty {
                    let currentFile = selectedItems[currentPreviewIndex]
                    // Image/Video preview
                    if supportedExtensions.contains(currentFile.url.pathExtension.lowercased()) {
                        if ["mov", "mp4", "avi", "m4v"].contains(currentFile.url.pathExtension.lowercased()) {
                            VideoPlayer(player: AVPlayer(playerItem: AVPlayerItem(asset: AVURLAsset(url: currentFile.url))))
                                .frame(minHeight: 200, maxHeight: .infinity)
                        } else {
                            if let image = NSImage(contentsOf: currentFile.url) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minHeight: 200, maxHeight: .infinity)
                            }
                        }
                    }
                    if selectedItems.count > 1 {
                        HStack {
                            Button("<") {
                                if currentPreviewIndex > 0 {
                                    currentPreviewIndex -= 1
                                }
                            }
                            Text("\(currentPreviewIndex + 1) of \(selectedItems.count)")
                            Button(">") {
                                if currentPreviewIndex < selectedItems.count - 1 {
                                    currentPreviewIndex += 1
                                }
                            }
                        }
                    }
                } else {
                    Text("Select a file to preview")
                        .frame(minHeight: 200, maxHeight: .infinity)
                }

                // Map preview
                let locations = selectedItems.compactMap { $0.location }
                if mapRegion != nil {
                    Map(coordinateRegion: Binding(
                        get: { mapRegion! },
                        set: { mapRegion = $0 }
                    ), annotationItems: locations.map { IdentifiableCoordinate(coordinate: $0) }) { item in
                        MapPin(coordinate: item.coordinate)
                    }
                    .frame(minHeight: 200, maxHeight: .infinity)
                } else {
                    Text("No location data")
                        .frame(minHeight: 200, maxHeight: .infinity)
                }
            }
        }
        .sheet(isPresented: $showMapPopover) {
            if let file = editingLocationFor {
                LocationEditorView(file: file, onSave: { newLocation in
                    // Update location
                    if let index = files.firstIndex(where: { $0.id == file.id }) {
                        files[index].location = newLocation
                    }
                    updateMapRegion()
                    showMapPopover = false
                })
            }
        }
    }

    private func updateMapRegion() {
        let locations = files.filter { selectedFiles.contains($0.id) }.compactMap { $0.location }
        if let first = locations.first {
            mapRegion = MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        } else {
            mapRegion = nil
        }
    }

    private func statusIcon(for status: RenameStatus) -> some View {
        switch status {
        case .pending:
            Circle().fill(Color.gray).frame(width: 10, height: 10)
        case .success:
            Circle().fill(Color.green).frame(width: 10, height: 10)
        case .failure:
            Circle().fill(Color.red).frame(width: 10, height: 10)
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
        }
    }

    private func selectCopyFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            copyToFolder = url
        }
    }

    private func scanFolder() {
        guard let folder = selectedFolder else { return }
        files = []
        let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.creationDateKey], options: isRecursive ? [] : .skipsSubdirectoryDescendants)
        while let url = enumerator?.nextObject() as? URL {
            if supportedExtensions.contains(url.pathExtension.lowercased()) {
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date
                let exifData = extractMetadata(from: url)
                let relativePath = String(url.path.dropFirst(folder.path.count + (folder.path.hasSuffix("/") ? 0 : 1)))
                let displayPath = relativePath.isEmpty ? "." : "./\(relativePath)"
                let fileItem = FileItem(url: url, name: url.lastPathComponent, path: displayPath, creationDate: creationDate, exifDate: exifData.date, location: exifData.location)
                files.append(fileItem)
            }
        }
        files.sort { $0.name < $1.name }
    }

    private func extractMetadata(from url: URL) -> (date: Date?, location: CLLocationCoordinate2D?) {
        let ext = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "gif"].contains(ext) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return (nil, nil) }
            guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return (nil, nil) }
            
            var date: Date?
            if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
               let dateTime = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                date = formatter.date(from: dateTime)
            }
            
            var location: CLLocationCoordinate2D?
            if let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any],
               let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
               let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
                let latitude = latRef == "N" ? lat : -lat
                let longitude = lonRef == "E" ? lon : -lon
                location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            
            return (date, location)
        } else if ["mov", "mp4", "avi", "m4v"].contains(ext) {
            let asset = AVAsset(url: url)
            
            var date: Date?
            if let creationDate = asset.creationDate?.dateValue {
                date = creationDate
            }
            
            var location: CLLocationCoordinate2D?
            let metadata = asset.metadata(forFormat: .quickTimeMetadata)
            for item in metadata {
                if item.key as? String == "com.apple.quicktime.location.ISO6709",
                   let value = item.stringValue {
                    // Parse ISO6709 string like "+37.7749-122.4194/"
                    let start = value.index(after: value.startIndex)
                    if let lonStart = value[start...].firstIndex(where: { $0 == "+" || $0 == "-" }) {
                        let latStr = String(value[..<lonStart])
                        let lonStr = String(value[lonStart..<value.index(before: value.endIndex)]) // remove /
                        if let lat = Double(latStr), let lon = Double(lonStr) {
                            location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        }
                    }
                }
            }
            
            return (date, location)
        }
        return (nil, nil)
    }

    private func renameSelected() {
        let selectedItems = files.filter { selectedFiles.contains($0.id) }
        for var item in selectedItems {
            if let exifDate = item.exifDate {
                let prefix = renameFormatter.string(from: exifDate)
                let newName = "\(prefix)_\(item.name)"
                item.newName = newName
                let destinationFolder = copyToFolder ?? item.url.deletingLastPathComponent()
                let newURL = destinationFolder.appendingPathComponent(newName)
                do {
                    if copyToFolder != nil {
                        try FileManager.default.copyItem(at: item.url, to: newURL)
                    } else {
                        try FileManager.default.moveItem(at: item.url, to: newURL)
                    }
                    renameHistory.append(RenameAction(oldURL: item.url, newURL: newURL, fileID: item.id))
                    if let index = files.firstIndex(where: { $0.id == item.id }) {
                        files[index].status = .success
                        files[index].newName = newName
                        files[index].url = newURL // update url if moved
                        files[index].name = newURL.lastPathComponent // update name to reflect new filename
                    }
                } catch {
                    if let index = files.firstIndex(where: { $0.id == item.id }) {
                        files[index].status = .failure
                    }
                }
            } else {
                if let index = files.firstIndex(where: { $0.id == item.id }) {
                    files[index].status = .failure
                }
            }
        }
    }

    private func undoLastRename() {
        guard let lastAction = renameHistory.popLast() else { return }
        do {
            try FileManager.default.moveItem(at: lastAction.newURL, to: lastAction.oldURL)
            if let index = files.firstIndex(where: { $0.id == lastAction.fileID }) {
                files[index].status = .pending
                files[index].url = lastAction.oldURL
                files[index].name = lastAction.oldURL.lastPathComponent // update name back to original
                files[index].newName = nil
            }
        } catch {
            // Handle error, perhaps show alert
        }
    }
}

struct LocationEditorView: View {
    let file: FileItem
    let onSave: (CLLocationCoordinate2D?) -> Void
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    @State private var selectedLocation: CLLocationCoordinate2D?

    var body: some View {
        VStack {
            Text("Select location for \(file.name)")
            TextField("Enter location", text: $searchText)
                .padding()
            Button("Search") {
                geocodeLocation()
            }
            Map(coordinateRegion: $region, annotationItems: selectedLocation != nil ? [selectedLocation!] : []) { coord in
                MapPin(coordinate: coord)
            }
            .frame(height: 300)
            HStack {
                Button("Save") {
                    onSave(selectedLocation)
                }
                Button("Cancel") {
                    onSave(nil)
                }
            }
        }
        .frame(width: 400, height: 500)
    }

    private func geocodeLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                selectedLocation = location.coordinate
                region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
    }
}

extension CLLocationCoordinate2D: @retroactive Identifiable {
    public var id: String {
        "\(latitude),\(longitude)"
    }
}

#Preview {
    ContentView()
}
