import UIKit

/// Optional tube and swatch pictures live in the app's private folder. Nothing is uploaded.
struct PhotoCabinet {
    let directory: URL

    func fileURL(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    func image(named fileName: String?) -> UIImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        return UIImage(contentsOfFile: fileURL(for: fileName).path)
    }

    func writeJPEG(_ data: Data, fileName: String) throws {
        guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.86) else {
            throw PhotoCabinetError.unreadable
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try jpeg.write(to: fileURL(for: fileName), options: .atomic)
    }

    func delete(_ fileName: String?) {
        guard let fileName, !fileName.isEmpty else { return }
        try? FileManager.default.removeItem(at: fileURL(for: fileName))
    }
}

enum PhotoCabinetError: Error {
    case unreadable

    var message: String {
        "That photo could not be read. Choose another picture from your library."
    }
}
