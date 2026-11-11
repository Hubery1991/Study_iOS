import XCTest
@testable import SheenlisseCore

final class SheenlisseCoreTests: XCTestCase {
    func testZeroOpacityLeavesTheBaseUntouched() {
        let base = RGBA(r: 0.2, g: 0.4, b: 0.6, a: 1)
        let shade = RGBA(hex: 0xFF0000)
        let result = ColorBlend.apply(base: base, shade: shade, opacity: 0, mode: .multiply)
        XCTAssertEqual(result, base)
    }

    func testSourceOverReplacesWhenOpaque() {
        let base = RGBA(r: 0.1, g: 0.2, b: 0.3, a: 1)
        let shade = RGBA(r: 0.8, g: 0.1, b: 0.1, a: 1)
        let result = ColorBlend.apply(base: base, shade: shade, opacity: 1, mode: .sourceOver)
        XCTAssertEqual(result.r, shade.r, accuracy: 1e-9)
        XCTAssertEqual(result.g, shade.g, accuracy: 1e-9)
        XCTAssertEqual(result.b, shade.b, accuracy: 1e-9)
    }

    func testSourceOverMixesAtHalfCoverage() {
        let base = RGBA(r: 0.2, g: 0, b: 0, a: 1)
        let shade = RGBA(r: 0.8, g: 0, b: 0, a: 1)
        let result = ColorBlend.apply(base: base, shade: shade, opacity: 0.5, mode: .sourceOver)
        XCTAssertEqual(result.r, 0.5, accuracy: 1e-9)
    }

    func testMultiplyDarkens() {
        let base = RGBA(r: 0.4, g: 0.4, b: 0.4, a: 1)
        let shade = RGBA(r: 0.5, g: 0.5, b: 0.5, a: 1)
        let result = ColorBlend.apply(base: base, shade: shade, opacity: 1, mode: .multiply)
        XCTAssertEqual(result.r, 0.2, accuracy: 1e-9)
    }

    func testSoftLightAtMidGrayIsIdentity() {
        let base = RGBA(r: 0.3, g: 0.6, b: 0.9, a: 1)
        let shade = RGBA(r: 0.5, g: 0.5, b: 0.5, a: 1)
        let result = ColorBlend.apply(base: base, shade: shade, opacity: 1, mode: .softLight)
        XCTAssertEqual(result.r, base.r, accuracy: 1e-9)
        XCTAssertEqual(result.g, base.g, accuracy: 1e-9)
        XCTAssertEqual(result.b, base.b, accuracy: 1e-9)
    }

    func testOverlayKnownValue() {
        let dark = ColorBlend.blendChannel(0.25, 0.8, .overlay)
        XCTAssertEqual(dark, 2 * 0.25 * 0.8, accuracy: 1e-9)
        let light = ColorBlend.blendChannel(0.75, 0.2, .overlay)
        XCTAssertEqual(light, 1 - 2 * (1 - 0.75) * (1 - 0.2), accuracy: 1e-9)
    }

    func testBlendChannelsStayInRange() {
        let modes: [BlendMode] = [.sourceOver, .multiply, .softLight, .overlay]
        for mode in modes {
            for base in stride(from: 0.0, through: 1.0, by: 0.1) {
                for layer in stride(from: 0.0, through: 1.0, by: 0.1) {
                    let value = ColorBlend.blendChannel(base, layer, mode)
                    XCTAssertTrue(value.isFinite)
                    XCTAssertGreaterThanOrEqual(value, 0)
                    XCTAssertLessThanOrEqual(value, 1)
                }
            }
        }
    }

    func testHexInit() {
        let color = RGBA(hex: 0xE7A0A8)
        XCTAssertEqual(color.r, 231.0 / 255, accuracy: 1e-9)
        XCTAssertEqual(color.g, 160.0 / 255, accuracy: 1e-9)
        XCTAssertEqual(color.b, 168.0 / 255, accuracy: 1e-9)
        XCTAssertEqual(color.a, 1, accuracy: 1e-9)
    }

    func testCatalogCoversEveryRegionWithUniqueIDs() {
        let ids = ShadeCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for region in MakeupRegion.allCases {
            let shades = ShadeCatalog.shades(for: region)
            XCTAssertGreaterThanOrEqual(shades.count, 4)
            XCTAssertTrue(shades.allSatisfy { $0.region == region })
            XCTAssertTrue(shades.allSatisfy { $0.color.r >= 0 && $0.color.r <= 1 })
        }
        XCTAssertEqual(ShadeCatalog.shade(id: "lip-deep-red")?.name, "Deep Red")
    }

    func testCuratedLooksReferenceRealShades() {
        XCTAssertEqual(CuratedLooks.all.map(\.id), ["natural", "evening", "vibrant", "fresh"])
        for look in CuratedLooks.all {
            for region in MakeupRegion.allCases {
                let setting = look.recipe.setting(for: region)
                let shade = ShadeCatalog.shade(id: setting.shadeID)
                XCTAssertEqual(shade?.region, region)
                XCTAssertGreaterThan(setting.intensity, 0)
                XCTAssertLessThanOrEqual(setting.intensity, 1)
                XCTAssertTrue(setting.enabled)
            }
            XCTAssertFalse(look.recipe.isBare)
            XCTAssertFalse(look.tagline.isEmpty)
        }
        XCTAssertTrue(CuratedLooks.bare.isBare)
    }

    func testPainterStyles() {
        let matte = MakeupPainter.style(region: .lipstick, finish: .matte, intensity: 1, enabled: true)
        XCTAssertEqual(matte.mode, .multiply)
        XCTAssertEqual(matte.opacity, 0.78, accuracy: 1e-9)
        let gloss = MakeupPainter.style(region: .lipstick, finish: .gloss, intensity: 1, enabled: true)
        XCTAssertEqual(gloss.mode, .overlay)
        let blush = MakeupPainter.style(region: .blush, finish: .satin, intensity: 1, enabled: true)
        XCTAssertEqual(blush.mode, .softLight)
        XCTAssertEqual(blush.opacity, 0.48, accuracy: 1e-9)
        let liner = MakeupPainter.style(region: .eyeliner, finish: .matte, intensity: 1, enabled: true)
        XCTAssertEqual(liner.mode, .sourceOver)
        XCTAssertEqual(liner.opacity, 0.92, accuracy: 1e-9)
        let off = MakeupPainter.style(region: .brows, finish: .matte, intensity: 1, enabled: false)
        XCTAssertEqual(off.opacity, 0, accuracy: 1e-9)
    }

    func testRecipeUpdateLeavesOtherRegionsAlone() {
        let original = CuratedLooks.natural.recipe
        var lip = original.lipstick
        lip.shadeID = "lip-plum"
        lip.intensity = 0.4
        let updated = original.updating(.lipstick, lip)
        XCTAssertEqual(updated.lipstick.shadeID, "lip-plum")
        XCTAssertEqual(updated.blush, original.blush)
        XCTAssertEqual(updated.eyeshadow, original.eyeshadow)
        XCTAssertEqual(updated.eyeliner, original.eyeliner)
        XCTAssertEqual(updated.brows, original.brows)
    }

    func testRegionSettingDecodeClampsIntensity() throws {
        let high = try JSONDecoder().decode(RegionSetting.self, from: Data("{\"shadeID\":\"lip-petal\",\"intensity\":2.5}".utf8))
        XCTAssertEqual(high.intensity, 1, accuracy: 1e-9)
        XCTAssertTrue(high.enabled)
        let low = try JSONDecoder().decode(RegionSetting.self, from: Data("{\"shadeID\":\"lip-petal\",\"intensity\":-0.4,\"enabled\":false}".utf8))
        XCTAssertEqual(low.intensity, 0, accuracy: 1e-9)
        XCTAssertFalse(low.enabled)
    }

    func testEllipseSitsOnTheCurve() {
        let center = Point2D(x: 0.4, y: 0.5)
        let points = RegionBuilder.ellipse(center: center, rx: 0.2, ry: 0.1, samples: 16)
        XCTAssertEqual(points.count, 16)
        for point in points {
            let nx = (point.x - center.x) / 0.2
            let ny = (point.y - center.y) / 0.1
            XCTAssertEqual(nx * nx + ny * ny, 1, accuracy: 1e-8)
        }
    }

    func testGeometryPlacesCheeksLidsAndLiner() {
        let face = sampleFace()
        let geometry = RegionBuilder.geometry(from: face)
        XCTAssertNotNil(geometry)
        guard let geometry else { return }
        XCTAssertEqual(geometry.lipsOuter.count, face.outerLips.count)
        XCTAssertEqual(geometry.lipsInner.count, face.innerLips.count)
        let left = geometry.leftCheek.map(\.x).reduce(0, +) / Double(geometry.leftCheek.count)
        let right = geometry.rightCheek.map(\.x).reduce(0, +) / Double(geometry.rightCheek.count)
        XCTAssertLessThan(left, right)
        XCTAssertLessThan(geometry.leftLid.map(\.y).min() ?? 1, face.leftEye.map(\.y).min() ?? 0)
        XCTAssertGreaterThanOrEqual(geometry.leftLiner.count, 2)
        let eyeMid = face.leftEye.map(\.y).reduce(0, +) / Double(face.leftEye.count)
        XCTAssertTrue(geometry.leftLiner.allSatisfy { $0.y <= eyeMid + 0.003 })
    }

    func testTinyFaceProducesNoGeometry() {
        var face = sampleFace()
        face.bounds = Rect2D(x: 0.4, y: 0.4, width: 0.05, height: 0.08)
        XCTAssertNil(RegionBuilder.geometry(from: face))
    }

    func testFaceShapeFixtures() {
        XCTAssertEqual(FaceShapeClassifier.classify(FaceMetrics(length: 1.6, cheekWidth: 1, foreheadWidth: 0.85, jawWidth: 0.8)), .oblong)
        XCTAssertEqual(FaceShapeClassifier.classify(FaceMetrics(length: 1.3, cheekWidth: 1, foreheadWidth: 1.0, jawWidth: 0.7)), .heart)
        XCTAssertEqual(FaceShapeClassifier.classify(FaceMetrics(length: 1.1, cheekWidth: 1, foreheadWidth: 0.95, jawWidth: 0.95)), .round)
        XCTAssertEqual(FaceShapeClassifier.classify(FaceMetrics(length: 1.28, cheekWidth: 1, foreheadWidth: 0.95, jawWidth: 0.94)), .square)
        XCTAssertEqual(FaceShapeClassifier.classify(FaceMetrics(length: 1.38, cheekWidth: 1, foreheadWidth: 0.86, jawWidth: 0.82)), .oval)
        XCTAssertEqual(FaceShapeClassifier.classify(FaceMetrics(length: 1, cheekWidth: 0, foreheadWidth: 1, jawWidth: 1)), .oval)
    }

    func testMetricsExtractorReadsAnOvalFixture() {
        let face = measuredFace()
        let metrics = FaceShapeClassifier.metrics(from: face)
        XCTAssertNotNil(metrics)
        guard let metrics else { return }
        XCTAssertEqual(metrics.length, 0.80, accuracy: 1e-9)
        XCTAssertEqual(metrics.cheekWidth, 0.64, accuracy: 1e-9)
        XCTAssertEqual(metrics.foreheadWidth, 0.56, accuracy: 1e-9)
        XCTAssertEqual(metrics.jawWidth, 0.40, accuracy: 1e-9)
        XCTAssertEqual(FaceShapeClassifier.shape(of: face), .oval)
        var empty = face
        empty.contour = []
        XCTAssertNil(FaceShapeClassifier.metrics(from: empty))
    }

    func testSkinToneBandsAndGate() {
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.80, g: 0.80, b: 0.80)), .fair)
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.72, g: 0.72, b: 0.72)), .fair)
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.65, g: 0.65, b: 0.65)), .light)
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.52, g: 0.52, b: 0.52)), .medium)
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.40, g: 0.40, b: 0.40)), .tan)
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.28, g: 0.28, b: 0.28)), .deep)
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.15, g: 0.15, b: 0.15)), .rich)
        XCTAssertEqual(SkinToneClassifier.classify(SkinSample(r: 0.219, g: 0.219, b: 0.219)), .rich)
        XCTAssertFalse(SkinToneClassifier.isLikelySkin(SkinSample(r: 0.3, g: 0.3, b: 0.6)))
        XCTAssertFalse(SkinToneClassifier.isLikelySkin(SkinSample(r: 0.3, g: 0.5, b: 0.3)))
        XCTAssertFalse(SkinToneClassifier.isLikelySkin(SkinSample(r: 0.02, g: 0.02, b: 0.02)))
        XCTAssertNil(SkinToneClassifier.average([]))
        let mixed = SkinToneClassifier.averageSkin([
            SkinSample(r: 0.3, g: 0.3, b: 0.9),
            SkinSample(r: 0.40, g: 0.40, b: 0.40),
            SkinSample(r: 0.60, g: 0.60, b: 0.60),
        ])
        XCTAssertEqual(mixed?.r ?? 0, 0.50, accuracy: 1e-9)
        XCTAssertNil(SkinToneClassifier.averageSkin([SkinSample(r: 0.1, g: 0.1, b: 0.9)]))
    }

    func testSuggestionTableAndTuning() {
        XCTAssertEqual(SuggestionEngine.lookID(shape: .oval, tone: .fair), "natural")
        XCTAssertEqual(SuggestionEngine.lookID(shape: .round, tone: .fair), "fresh")
        XCTAssertEqual(SuggestionEngine.lookID(shape: .square, tone: .medium), "vibrant")
        XCTAssertEqual(SuggestionEngine.lookID(shape: .heart, tone: .tan), "evening")
        XCTAssertEqual(SuggestionEngine.lookID(shape: .oblong, tone: .deep), "vibrant")
        XCTAssertEqual(SuggestionEngine.lookID(shape: .oval, tone: .rich), "evening")

        for shape in FaceShape.allCases {
            for tone in SkinTone.allCases {
                let suggestion = SuggestionEngine.suggest(shape: shape, tone: tone)
                XCTAssertFalse(suggestion.headline.isEmpty)
                XCTAssertEqual(suggestion.notes.count, 2)
                XCTAssertTrue(suggestion.notes.allSatisfy { !$0.isEmpty })
                XCTAssertTrue(CuratedLooks.all.contains { $0.id == suggestion.look.id })
                let tuned = SuggestionEngine.tunedRecipe(shape: shape, tone: tone)
                for region in MakeupRegion.allCases {
                    let intensity = tuned.setting(for: region).intensity
                    XCTAssertGreaterThanOrEqual(intensity, 0)
                    XCTAssertLessThanOrEqual(intensity, 1)
                }
            }
        }

        let fair = SuggestionEngine.tunedRecipe(shape: .oval, tone: .fair)
        let rich = SuggestionEngine.tunedRecipe(shape: .oval, tone: .rich)
        XCTAssertLessThan(fair.blush.intensity, CuratedLooks.natural.recipe.blush.intensity)
        XCTAssertGreaterThan(rich.lipstick.intensity, CuratedLooks.evening.recipe.lipstick.intensity * 0.99)
        XCTAssertTrue(SuggestionEngine.suggest(shape: .oval, tone: .fair).notes[0].contains("oval"))
        XCTAssertTrue(SuggestionEngine.suggest(shape: .round, tone: .fair).notes[0].contains("round"))
        XCTAssertTrue(SuggestionEngine.suggest(shape: .oval, tone: .fair).notes[1].contains("Fair"))
    }

    func testExpressionFadesEyesAndLeavesTheLip() {
        let recipe = CuratedLooks.evening.recipe
        let closed = ExpressionAdjuster.adjusted(recipe, expression: FaceExpression(jawOpen: 0, blinkLeft: 1, blinkRight: 0.2))
        XCTAssertEqual(closed.eyeshadow.intensity, 0, accuracy: 1e-9)
        XCTAssertEqual(closed.eyeliner.intensity, 0, accuracy: 1e-9)
        XCTAssertEqual(closed.lipstick, recipe.lipstick)
        let half = ExpressionAdjuster.adjusted(recipe, expression: FaceExpression(blinkLeft: 0.5, blinkRight: 0.1))
        XCTAssertEqual(half.eyeshadow.intensity, recipe.eyeshadow.intensity * 0.5, accuracy: 1e-9)
        let openJaw = ExpressionAdjuster.adjusted(recipe, expression: FaceExpression(jawOpen: 1))
        XCTAssertEqual(openJaw.lipstick, recipe.lipstick)
        XCTAssertEqual(openJaw.eyeshadow, recipe.eyeshadow)
    }

    func testFavoriteLibrary() throws {
        var document = MirrorDocument.initial
        XCTAssertEqual(document.lastLookID, "natural")
        XCTAssertFalse(document.preferences.hasSeenCoach)
        XCTAssertTrue(document.preferences.hapticsEnabled)

        let first = UUID()
        for index in 0..<25 {
            document.save(SavedLook(
                id: index == 0 ? first : UUID(),
                name: "Look \(index)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(1_700_000_000 + index)),
                recipe: CuratedLooks.fresh.recipe,
                note: ""
            ))
        }
        XCTAssertEqual(document.favorites.count, MirrorDocument.maxFavorites)
        XCTAssertEqual(document.favorites.first?.name, "Look 24")
        XCTAssertFalse(document.favorites.contains { $0.id == first })

        let kept = document.favorites[0].id
        XCTAssertTrue(document.rename(id: kept, to: "   evening   glam  "))
        XCTAssertEqual(document.favorites[0].name, "evening glam")
        XCTAssertFalse(document.rename(id: UUID(), to: "Nope"))
        XCTAssertTrue(document.remove(id: kept))
        XCTAssertFalse(document.favorites.contains { $0.id == kept })

        XCTAssertEqual(MirrorDocument.sanitizedName("   "), "Saved look")
        XCTAssertEqual(MirrorDocument.sanitizedName(String(repeating: "a", count: 50)).count, 40)

        let data = try document.encodeData()
        let decoded = try MirrorDocument.decodeData(data)
        XCTAssertEqual(decoded.favorites.count, document.favorites.count)
        XCTAssertEqual(decoded.lastRecipe, document.lastRecipe)
        XCTAssertEqual(decoded.version, 1)
        XCTAssertThrowsError(try MirrorDocument.decodeData(Data("{}".utf8)))
    }

    func testCompareAndPreviewMapping() {
        let split = CompareSplit(position: 0.5)
        XCTAssertFalse(split.showsMakeup(normalizedX: 0.49))
        XCTAssertTrue(split.showsMakeup(normalizedX: 0.5))
        XCTAssertTrue(CompareSplit(position: 0).showsMakeup(normalizedX: 0))
        XCTAssertEqual(CompareSplit(position: -1).position, 0)
        XCTAssertEqual(CompareSplit(position: 3).position, 1)

        let matched = PreviewMapper(imageWidth: 100, imageHeight: 200, viewWidth: 100, viewHeight: 200)
        let center = matched.viewPoint(Point2D(x: 0.25, y: 0.5))
        XCTAssertEqual(center.x, 25, accuracy: 1e-9)
        XCTAssertEqual(center.y, 100, accuracy: 1e-9)

        let filled = PreviewMapper(imageWidth: 100, imageHeight: 100, viewWidth: 200, viewHeight: 100)
        let mid = filled.viewPoint(Point2D(x: 0.5, y: 0.5))
        XCTAssertEqual(mid.x, 100, accuracy: 1e-9)
        XCTAssertEqual(mid.y, 50, accuracy: 1e-9)
        XCTAssertEqual(filled.displayedImageRect.y, -50, accuracy: 1e-9)

        let mirrored = PreviewMapper(imageWidth: 100, imageHeight: 100, viewWidth: 100, viewHeight: 100, mirrorX: true)
        let flipped = mirrored.viewPoint(Point2D(x: 0, y: 0.5))
        XCTAssertEqual(flipped.x, 100, accuracy: 1e-9)
        XCTAssertEqual(flipped.y, 50, accuracy: 1e-9)
    }

    private func sampleFace() -> FaceLandmarks {
        FaceLandmarks(
            bounds: Rect2D(x: 0.20, y: 0.12, width: 0.60, height: 0.74),
            contour: [
                Point2D(x: 0.22, y: 0.30), Point2D(x: 0.78, y: 0.30),
                Point2D(x: 0.20, y: 0.55), Point2D(x: 0.80, y: 0.55),
                Point2D(x: 0.48, y: 0.84),
            ],
            leftEye: [
                Point2D(x: 0.32, y: 0.34), Point2D(x: 0.40, y: 0.32),
                Point2D(x: 0.42, y: 0.36), Point2D(x: 0.34, y: 0.38),
            ],
            rightEye: [
                Point2D(x: 0.58, y: 0.34), Point2D(x: 0.66, y: 0.32),
                Point2D(x: 0.68, y: 0.36), Point2D(x: 0.60, y: 0.38),
            ],
            leftBrow: [Point2D(x: 0.30, y: 0.26), Point2D(x: 0.36, y: 0.24), Point2D(x: 0.42, y: 0.27)],
            rightBrow: [Point2D(x: 0.58, y: 0.27), Point2D(x: 0.64, y: 0.24), Point2D(x: 0.70, y: 0.26)],
            outerLips: [
                Point2D(x: 0.40, y: 0.64), Point2D(x: 0.46, y: 0.62),
                Point2D(x: 0.50, y: 0.63), Point2D(x: 0.54, y: 0.62),
                Point2D(x: 0.60, y: 0.64), Point2D(x: 0.50, y: 0.72),
            ],
            innerLips: [
                Point2D(x: 0.44, y: 0.65), Point2D(x: 0.50, y: 0.64),
                Point2D(x: 0.56, y: 0.65), Point2D(x: 0.50, y: 0.69),
            ]
        )
    }

    private func measuredFace() -> FaceLandmarks {
        var face = sampleFace()
        face.bounds = Rect2D(x: 0.18, y: 0.15, width: 0.64, height: 0.80)
        face.contour = [
            Point2D(x: 0.20, y: 0.30), Point2D(x: 0.80, y: 0.30),
            Point2D(x: 0.18, y: 0.55), Point2D(x: 0.82, y: 0.55),
            Point2D(x: 0.30, y: 0.85), Point2D(x: 0.70, y: 0.85),
            Point2D(x: 0.50, y: 0.95),
        ]
        face.leftBrow = [Point2D(x: 0.22, y: 0.28), Point2D(x: 0.40, y: 0.24)]
        face.rightBrow = [Point2D(x: 0.60, y: 0.24), Point2D(x: 0.78, y: 0.28)]
        return face
    }
}
