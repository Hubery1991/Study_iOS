import UIKit

enum PhotoFiles {
    static var folder: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = support.appendingPathComponent("Nimvelle/photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func url(fileName: String) -> URL {
        folder.appendingPathComponent(fileName)
    }

    static func image(fileName: String) -> UIImage? {
        let path = url(fileName: fileName)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    @discardableResult
    static func save(_ image: UIImage) -> String? {
        let name = UUID().uuidString + ".jpg"
        let flattened = render(image, maxSide: 1600)
        guard let data = flattened.jpegData(compressionQuality: 0.86) else { return nil }
        do {
            try data.write(to: url(fileName: name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func remove(fileName: String) {
        try? FileManager.default.removeItem(at: url(fileName: fileName))
    }

    private static func render(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxSide && longest > 0 ? maxSide / longest : 1
        let target = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
