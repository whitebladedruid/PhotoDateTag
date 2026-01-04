import SwiftUI
import MapKit

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

