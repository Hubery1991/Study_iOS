import CoreLocation
import WeatherKit

enum DeviceWeatherError: Error {
    case denied
    case unavailable
}

struct DeviceWeatherReading: Equatable {
    var celsius: Double
    var isRaining: Bool
    var summary: String
}

final class DeviceWeather: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    func reading() async throws -> DeviceWeatherReading {
        let location = try await locate()
        let weather = try await WeatherService.shared.weather(for: location)
        let celsius = weather.currentWeather.temperature.converted(to: .celsius).value
        let raining = Self.isWet(weather.currentWeather.condition)
        let rounded = Int(celsius.rounded())
        let sky = raining ? "rain" : "dry"
        return DeviceWeatherReading(
            celsius: celsius,
            isRaining: raining,
            summary: "\(rounded)° and \(sky)"
        )
    }

    private func locate() async throws -> CLLocation {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            throw DeviceWeatherError.denied
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            if status == .notDetermined {
                self.manager.requestWhenInUseAuthorization()
            } else {
                self.manager.requestLocation()
            }
        }
    }

    private func finish(_ result: Result<CLLocation, Error>) {
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(DeviceWeatherError.denied))
        case .notDetermined:
            break
        @unknown default:
            finish(.failure(DeviceWeatherError.unavailable))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let code = error as? CLError, code.code == .denied {
            finish(.failure(DeviceWeatherError.denied))
        } else {
            finish(.failure(DeviceWeatherError.unavailable))
        }
    }

    private static func isWet(_ condition: WeatherCondition) -> Bool {
        switch condition {
        case .rain, .heavyRain, .drizzle, .freezingDrizzle, .freezingRain, .sunShowers,
             .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms,
             .wintryMix, .hail, .sleet, .snow, .heavySnow, .flurries, .blizzard, .blowingSnow,
             .sunFlurries, .tropicalStorm, .hurricane:
            return true
        default:
            return false
        }
    }
}
