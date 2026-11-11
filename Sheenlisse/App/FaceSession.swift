import ARKit
import AVFoundation
import CoreImage
import UIKit
import Vision

enum TrackingMode: Equatable {
    case starting
    case trueDepth
    case vision
    case searching
    case unavailable

    var label: String {
        switch self {
        case .starting: return "Starting"
        case .trueDepth: return "TrueDepth"
        case .vision: return "Vision"
        case .searching: return "Looking"
        case .unavailable: return "Studio"
        }
    }
}

final class FaceSession: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    let arSession = ARSession()

    @Published private(set) var authorization: AVAuthorizationStatus = .notDetermined
    @Published private(set) var mode: TrackingMode = .starting
    @Published private(set) var landmarks: FaceLandmarks?
    @Published private(set) var orientedImageSize: CGSize = .zero
    @Published private(set) var expression: FaceExpression = .neutral
    @Published private(set) var faceVisible = false
    @Published private(set) var faceShape: FaceShape?
    @Published private(set) var skinTone: SkinTone?
    @Published private(set) var usesTrueDepth = false
    @Published private(set) var hardwareMissing = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var preview: UIImage?

    private let videoQueue = DispatchQueue(label: "sheenlisse.camera", qos: .userInitiated)
    private let ciContext = CIContext(options: nil)
    private var running = false
    private var arFailed = false
    private var lastProcess = Date.distantPast
    private let stateLock = NSLock()
    private var pendingCapture: PendingCapture?

    func prepare() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorization = status
        switch status {
        case .authorized:
            start()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.authorization = granted ? .authorized : .denied
                    if granted {
                        self.start()
                    } else {
                        self.mode = .unavailable
                    }
                }
            }
        case .denied, .restricted:
            mode = .unavailable
        @unknown default:
            mode = .unavailable
        }
    }

    func start() {
        guard authorization == .authorized, !running else { return }
        if !arFailed, ARFaceTrackingConfiguration.isSupported {
            usesTrueDepth = true
            mode = .trueDepth
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            arSession.delegate = self
            arSession.delegateQueue = videoQueue
            arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            running = true
            return
        }
        startCapture()
    }

    func stop() {
        if usesTrueDepth {
            arSession.pause()
        }
        if captureSession.isRunning {
            videoQueue.async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
        running = false
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func capture(
        recipe: MakeupRecipe,
        expression: FaceExpression,
        compare: CompareSplit?,
        completion: @escaping (UIImage?) -> Void
    ) {
        let pending = PendingCapture(recipe: recipe, expression: expression, compare: compare, completion: completion)
        stateLock.lock()
        pendingCapture = pending
        stateLock.unlock()
        videoQueue.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.finishStaleCapture()
        }
    }

    private func startCapture() {
        usesTrueDepth = false
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.hardwareMissing = true
                self.mode = .unavailable
                self.running = false
                self.statusMessage = "This device has no front camera. You can still build a look and save it."
            }
            return
        }
        captureSession.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard captureSession.canAddOutput(output) else {
            captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.hardwareMissing = true
                self.mode = .unavailable
            }
            return
        }
        captureSession.addOutput(output)
        if let connection = output.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
        captureSession.commitConfiguration()
        running = true
        DispatchQueue.main.async { self.mode = .vision }
        videoQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func handle(
        buffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        expression: FaceExpression
    ) {
        let wantsCapture = peekCapture()
        let now = Date()
        if !wantsCapture, now.timeIntervalSince(lastProcess) < 1.0 / 15.0 { return }
        lastProcess = now

        let oriented = CIImage(cvPixelBuffer: buffer).oriented(orientation)
        let upright = oriented.transformed(by: CGAffineTransform(
            translationX: -oriented.extent.origin.x,
            y: -oriented.extent.origin.y
        ))
        let imageSize = upright.extent.size

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation, options: [:])
        try? handler.perform([request])
        let observation = (request.results ?? []).max { lhs, rhs in
            lhs.boundingBox.width * lhs.boundingBox.height < rhs.boundingBox.width * rhs.boundingBox.height
        }

        var found: FaceLandmarks?
        var shape: FaceShape?
        var tone: SkinTone?
        if let observation, let landmarks = Self.landmarks(from: observation) {
            found = landmarks
            shape = FaceShapeClassifier.shape(of: landmarks)
            tone = skinTone(from: upright, landmarks: landmarks)
        }

        stateLock.lock()
        let capture = pendingCapture
        if capture != nil { pendingCapture = nil }
        stateLock.unlock()

        if let capture {
            let image = render(upright: upright, landmarks: found, pending: capture)
            DispatchQueue.main.async { capture.completion(image) }
        }

        let previewImage = ciContext.createCGImage(upright, from: upright.extent).map { UIImage(cgImage: $0) }

        DispatchQueue.main.async {
            if let previewImage { self.preview = previewImage }
            self.orientedImageSize = imageSize
            self.expression = expression
            self.landmarks = found
            self.faceVisible = found != nil
            if let shape { self.faceShape = shape }
            if let tone { self.skinTone = tone }
            if self.hardwareMissing { return }
            if found != nil {
                self.mode = self.usesTrueDepth ? .trueDepth : .vision
            } else if self.mode != .unavailable {
                self.mode = .searching
            }
        }
    }

    private func render(upright: CIImage, landmarks: FaceLandmarks?, pending: PendingCapture) -> UIImage? {
        guard let landmarks else { return nil }
        guard let cgImage = ciContext.createCGImage(upright, from: upright.extent) else { return nil }
        let size = upright.extent.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
            MakeupDrawing.draw(
                in: context.cgContext,
                canvas: size,
                landmarks: landmarks,
                recipe: pending.recipe,
                expression: pending.expression,
                compare: pending.compare,
                map: { point in
                    CGPoint(x: point.x * size.width, y: point.y * size.height)
                }
            )
        }
    }

    private func skinTone(from image: CIImage, landmarks: FaceLandmarks) -> SkinTone? {
        guard let geometry = RegionBuilder.geometry(from: landmarks) else { return nil }
        var samples: [SkinSample] = []
        for cheek in [geometry.leftCheek, geometry.rightCheek] {
            guard let sample = sample(cheek, in: image) else { continue }
            samples.append(sample)
        }
        guard let mean = SkinToneClassifier.averageSkin(samples) else { return nil }
        return SkinToneClassifier.classify(mean)
    }

    private func sample(_ points: [Point2D], in image: CIImage) -> SkinSample? {
        guard !points.isEmpty else { return nil }
        let sum = points.reduce(Point2D(x: 0, y: 0)) { Point2D(x: $0.x + $1.x, y: $0.y + $1.y) }
        let count = Double(points.count)
        let extent = image.extent
        let px = extent.minX + (sum.x / count) * extent.width
        let py = extent.minY + (1 - sum.y / count) * extent.height
        let rect = CGRect(x: px - 4, y: py - 4, width: 8, height: 8).intersection(extent.insetBy(dx: 2, dy: 2))
        guard rect.width > 1, rect.height > 1 else { return nil }
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: rect), forKey: kCIInputExtentKey)
        guard let output = filter.outputImage else { return nil }
        let origin = output.extent.origin
        guard output.extent.width >= 1, output.extent.height >= 1 else { return nil }
        var pixel = [UInt8](repeating: 0, count: 4)
        let rendered = pixel.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress else { return false }
            ciContext.render(
                output,
                toBitmap: base,
                rowBytes: 4,
                bounds: CGRect(x: origin.x, y: origin.y, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )
            return true
        }
        guard rendered else { return nil }
        return SkinSample(
            r: Double(pixel[0]) / 255,
            g: Double(pixel[1]) / 255,
            b: Double(pixel[2]) / 255
        )
    }

    private func peekCapture() -> Bool {
        stateLock.lock()
        let pending = pendingCapture != nil
        stateLock.unlock()
        return pending
    }

    private func finishStaleCapture() {
        stateLock.lock()
        let capture = pendingCapture
        pendingCapture = nil
        stateLock.unlock()
        if let capture {
            DispatchQueue.main.async { capture.completion(nil) }
        }
    }

    private static func landmarks(from observation: VNFaceObservation) -> FaceLandmarks? {
        guard let marks = observation.landmarks else { return nil }
        let box = observation.boundingBox
        func converted(_ region: VNFaceLandmarkRegion2D?) -> [Point2D] {
            guard let region else { return [] }
            return region.normalizedPoints.map { point in
                let nx = box.origin.x + point.x * box.size.width
                let ny = box.origin.y + point.y * box.size.height
                return Point2D(x: Double(nx), y: Double(1 - ny))
            }
        }
        let eyes = orderPair(converted(marks.leftEye), converted(marks.rightEye))
        let brows = orderPair(converted(marks.leftEyebrow), converted(marks.rightEyebrow))
        let bounds = Rect2D(
            x: Double(box.origin.x),
            y: Double(1 - (box.origin.y + box.size.height)),
            width: Double(box.size.width),
            height: Double(box.size.height)
        )
        return FaceLandmarks(
            bounds: bounds,
            contour: converted(marks.faceContour),
            leftEye: eyes.0,
            rightEye: eyes.1,
            leftBrow: brows.0,
            rightBrow: brows.1,
            outerLips: converted(marks.outerLips),
            innerLips: converted(marks.innerLips)
        )
    }

    private static func orderPair(_ first: [Point2D], _ second: [Point2D]) -> ([Point2D], [Point2D]) {
        func meanX(_ points: [Point2D]) -> Double {
            guard !points.isEmpty else { return .greatestFiniteMagnitude }
            return points.reduce(0) { $0 + $1.x } / Double(points.count)
        }
        return meanX(first) <= meanX(second) ? (first, second) : (second, first)
    }
}

private struct PendingCapture {
    var recipe: MakeupRecipe
    var expression: FaceExpression
    var compare: CompareSplit?
    var completion: (UIImage?) -> Void
}

extension FaceSession: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let anchor = frame.anchors.compactMap { $0 as? ARFaceAnchor }.first
        let shapes = anchor?.blendShapes ?? [:]
        let expression = FaceExpression(
            jawOpen: shapes[.jawOpen]?.doubleValue ?? 0,
            blinkLeft: shapes[.eyeBlinkLeft]?.doubleValue ?? 0,
            blinkRight: shapes[.eyeBlinkRight]?.doubleValue ?? 0
        )
        handle(buffer: frame.capturedImage, orientation: .leftMirrored, expression: expression)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        arFailed = true
        running = false
        usesTrueDepth = false
        session.pause()
        DispatchQueue.main.async {
            self.statusMessage = "TrueDepth tracking stopped. Switching to the Vision camera."
        }
        startCapture()
    }
}

extension FaceSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        handle(buffer: buffer, orientation: .up, expression: .neutral)
    }
}
