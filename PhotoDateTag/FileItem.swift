import SwiftUI
import CoreLocation

/// File meta data that is stored in the list view item.
///
/// id is a UUID that is randomly generated when the struct is created.
/// url is the path of the file.
/// 
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
