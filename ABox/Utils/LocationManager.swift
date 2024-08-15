import UIKit
import CoreLocation

class LocationManager: NSObject {
    
    public static let shared = LocationManager()
    var locationManager: CLLocationManager?
    
    func startLocation() {
        print(message: "LocationManager startLocation ")

        if self.locationManager == nil {
            self.locationManager = CLLocationManager()
            
            self.locationManager?.delegate = self
            self.locationManager?.allowsBackgroundLocationUpdates = true
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager?.distanceFilter = 10
            self.locationManager?.requestAlwaysAuthorization()
        }
        guard let locationManager = self.locationManager else { return }
        locationManager.startUpdatingLocation()
    }
    
    func stopLocation() {
        print(message: "LocationManager stopLocation ")
        guard let locationManager = self.locationManager else { return }
        locationManager.stopUpdatingHeading()
        self.locationManager = nil

    }
    
    func requestAuthority() {
        guard let locationManager = self.locationManager else { return }
        locationManager.requestAlwaysAuthorization()
    }

}


extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currLocation = locations.last {
            print(message: "定位成功，\(currLocation.coordinate.latitude) \(currLocation.coordinate.longitude) \(currLocation.altitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(message: "定位失败：\(error.localizedDescription)")
    }
}
