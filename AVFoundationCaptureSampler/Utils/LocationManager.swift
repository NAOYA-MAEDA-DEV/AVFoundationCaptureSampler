import CoreLocation

final class LocationManager: NSObject {
    private var locationManager: CLLocationManager = CLLocationManager()
    private(set) var location: CLLocation?
    var updateisOn: Bool = true
    
    override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
        startListeningForLocationUpdates()
    }
    
    private func startListeningForLocationUpdates() {
        Task {
            do {
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    guard let currentLocation = update.location else { continue }
                    self.location = currentLocation
                    if !updateisOn {
                        break
                    }
//                    print("Updated Location: \(currentLocation.coordinate)")
                }
            } catch {
                print(error)
            }
        }
    }
    
    func stopLocationUpdate() {
        updateisOn = false
    }
    
    func getLocation() -> CLLocation? {
        return location
    }
}
