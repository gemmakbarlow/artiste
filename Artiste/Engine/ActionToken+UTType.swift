import UniformTypeIdentifiers

extension UTType {
    static let artisteActionToken = UTType(exportedAs: "com.gemmakbarlow.artiste.action-token")
    /// Also carried by drags that start on a slot, so the trash can tell them apart from tray drags.
    static let artistePlacedToken = UTType(exportedAs: "com.gemmakbarlow.artiste.placed-token")
}
