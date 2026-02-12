import SwiftUI
import MapKit
import CoreLocation

struct MapViewRepresentable: NSViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var selectedLocation: CLLocationCoordinate2D?
    var onLocationSelected: (CLLocationCoordinate2D) -> Void
    
    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        
        // Add tap gesture recognizer
        let tapGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Add initial annotation if location exists
        if let location = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }
    
    func updateNSView(_ nsView: MKMapView, context: Context) {
        // Update region if changed
        if abs(nsView.region.center.latitude - region.center.latitude) > 0.001 ||
           abs(nsView.region.center.longitude - region.center.longitude) > 0.001 {
            nsView.setRegion(region, animated: true)
        }
        
        // Update annotations
        nsView.removeAnnotations(nsView.annotations)
        if let location = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            nsView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(region: $region, onLocationSelected: onLocationSelected)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var region: MKCoordinateRegion
        var onLocationSelected: (CLLocationCoordinate2D) -> Void
        
        init(region: Binding<MKCoordinateRegion>, onLocationSelected: @escaping (CLLocationCoordinate2D) -> Void) {
            self._region = region
            self.onLocationSelected = onLocationSelected
        }
        
        @objc func handleTap(_ gesture: NSClickGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            onLocationSelected(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            region = mapView.region
        }
    }
}

struct LocationEditorView: View {
    let file: FileItem
    let onSave: (CLLocationCoordinate2D?) -> Void
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("Select location for \(file.name)")
                .font(.headline)
            
            HStack(spacing: 8) {
                TextField("Enter location (e.g., San Francisco, CA)", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                Button("Search") {
                    geocodeLocation()
                }
            }
            .padding()
            
            ZStack {
                MapViewRepresentable(
                    region: $region,
                    selectedLocation: selectedLocation,
                    onLocationSelected: { location in
                        selectedLocation = location
                    }
                )
                .frame(width: 450, height: 320)
                .border(Color.gray)
                
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Click to drop pin")
                                .font(.caption)
                            if let location = selectedLocation {
                                Text(String(format: "Lat: %.4f, Lon: %.4f", location.latitude, location.longitude))
                                    .font(.caption2)
                                    .monospaced()
                            }
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding()
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            
            HStack(spacing: 12) {
                Button("Save") {
                    onSave(selectedLocation)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedLocation == nil)
                
                Button("Cancel") {
                    onSave(nil)
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                if selectedLocation != nil {
                    Button("Clear") {
                        selectedLocation = nil
                    }
                }
            }
            .padding()
        }
        .frame(width: 500, height: 550)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func geocodeLocation() {
        guard !searchText.isEmpty else {
            errorMessage = "Please enter a location"
            showingError = true
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                selectedLocation = location.coordinate
                region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            } else {
                errorMessage = "Location not found. Try a different search term."
                showingError = true
            }
        }
    }
}

