import Foundation
import LookmiraCore
import UIKit

struct PhotoArchive {
    let folder: URL

    func prepare() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func installBundledSamples(bundle: Bundle = .main) {
        prepare()
        for name in SamplePhoto.fileNames {
            let stem = (name as NSString).deletingPathExtension
            let ext = (name as NSString).pathExtension
            guard let source = bundle.url(forResource: stem, withExtension: ext) else { continue }
            let destination = folder.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: destination.path) {
                try? FileManager.default.copyItem(at: source, to: destination)
            }
        }
    }

    func saveJPEG(_ data: Data) throws -> String {
        prepare()
        let name = UUID().uuidString + ".jpg"
        try data.write(to: folder.appendingPathComponent(name), options: .atomic)
        return name
    }

    func url(for name: String?) -> URL? {
        guard let name, LookDraft.isSafePhotoFileName(name) else { return nil }
        let url = folder.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func delete(_ name: String) {
        guard LookDraft.isSafePhotoFileName(name) else { return }
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }
}
