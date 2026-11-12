import UIKit

enum PhotoStore {
    static func save(_ image: UIImage) -> String? {
        let scaled = image.scaledDown(maxSide: 1600)
        guard let data = scaled.jpegData(compressionQuality: 0.86) else { return nil }
        let id = UUID()
        let url = directory().appendingPathComponent("\(id.uuidString).jpg")
        do {
            try FileManager.default.createDirectory(at: directory(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            return "photo:\(id.uuidString)"
        } catch {
            return nil
        }
    }

    static func image(for token: String) -> UIImage? {
        guard let url = fileURL(for: token), let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(token: String) {
        guard let url = fileURL(for: token) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func uiImage(for token: String) -> UIImage? {
        if token.hasPrefix("seed-") {
            return UIImage(named: token)
        }
        return image(for: token)
    }

    private static func directory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Quillisse/photos", isDirectory: true)
    }

    private static func fileURL(for token: String) -> URL? {
        guard token.hasPrefix("photo:") else { return nil }
        let name = String(token.dropFirst("photo:".count))
        guard !name.isEmpty else { return nil }
        return directory().appendingPathComponent("\(name).jpg")
    }
}

extension UIImage {
    func scaledDown(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide, longest > 0 else { return self }
        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
