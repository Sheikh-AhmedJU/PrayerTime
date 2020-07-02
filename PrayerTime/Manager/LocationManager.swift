//
//  LocationManager.swift
//  PrayerTime
//
//  Created by Sheikh Ahmed on 09/05/2020.
//  Copyright © 2020 Sheikh Ahmed. All rights reserved.
//
import SwiftUI
import CoreLocation

enum LocationPermissionStatus: String{
    case permissionGiven
    case permissionNotGiven
    case notDetermined
}
enum LocationRequestState: String {
    case shouldRequest
    case requested
    case doNotRequest
}

class LocationManager: NSObject, ObservableObject {
    @Published var isLocationFound: Bool = false
    @Published var isLocationPermissionGiven: Bool = true
    @Published var geoLocation: Location?// = Location()
    @Published var errorMessage: String?
    
    private var locationManager: CLLocationManager = CLLocationManager()
    private var shouldRequestLocation: LocationRequestState = .doNotRequest
    
    var locationPermissionStatus: LocationPermissionStatus = {
        var status = CLLocationManager.locationServicesEnabled()
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            return .permissionGiven
        case .notDetermined:
            return .notDetermined
        default:
            return .permissionNotGiven
        }
    }()
    
    
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    func requestAccess(){
        switch self.locationPermissionStatus {
        case .permissionGiven:
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            self.shouldRequestLocation = .requested
        case .permissionNotGiven:
            locationManager.stopUpdatingLocation()
            self.shouldRequestLocation = .doNotRequest
        case .notDetermined:
            self.shouldRequestLocation = .shouldRequest
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func fetchLocationInfo(currentLocation: CLLocation){
        var timeZone: TimeZone?
        let queue = OperationQueue()
        let fetchGeoName = BlockOperation{
            let geoNameService = GeoNameService()
            geoNameService.getGeoLocation(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude) { (result) in
                switch result {
                case .success(let model):
                    guard let model = model?.geonames?.filter({
                        !($0.countryName?.isEmpty ?? true) && !($0.name?.isEmpty ?? true)
                    }).first,
                        let city = model.name,
                        let country = model.countryName else { return }
                    let geoLocation = Location(cityName: city, countryName: country, latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, timeZone: timeZone)
                    DispatchQueue.main.async {
                        self.geoLocation = geoLocation
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
        let fetchTimeZone = BlockOperation {
            let geoCoder = CLGeocoder()
            let clLocation = currentLocation
            geoCoder.reverseGeocodeLocation(clLocation) { (placemarks, error) in
                if let placemark = placemarks?.first, let placeTimeZone = placemark.timeZone {
                    timeZone = placeTimeZone
                    queue.addOperation(fetchGeoName)
                }
                else if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Another error: \(error.localizedDescription)")
                }
            }
        }
        queue.addOperation(fetchTimeZone)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.shouldRequestLocation = .doNotRequest
        self.errorMessage = error.localizedDescription
        print("Location Service Error : \(error.localizedDescription)")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.shouldRequestLocation == .requested && self.locationPermissionStatus == .permissionGiven {
            if let location = locations.last {
                self.shouldRequestLocation = .shouldRequest
                self.locationManager.stopUpdatingLocation()
                self.fetchLocationInfo(currentLocation: location)
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationPermissionStatus = .permissionGiven
            switch shouldRequestLocation{
            case .doNotRequest:
                break
            case .shouldRequest:
                locationManager.startUpdatingLocation()
                self.shouldRequestLocation = .requested
            case .requested:
                break
            }
        case .notDetermined:
            self.locationPermissionStatus = .notDetermined
        default:
            self.locationPermissionStatus = .permissionNotGiven
            self.shouldRequestLocation = .doNotRequest
        }
    }
}


//
//import XCTest
//import CoreLocation
//@testable import CoreLocationDemo
//
//class CoreLocationDemoTests: XCTestCase {
//
//  func test_view_model_updates_latitude_and_longitude_properties() {
//    let locations: [CLLocation] = [CLLocation(latitude: 12, longitude: 10)]
//
//    let viewModel = LocationViewModel()
//
//    viewModel.locationManager(CLLocationManager(), didUpdateLocations: locations)
//
//    XCTAssertEqual(12, viewModel.userLatitude)
//    XCTAssertEqual(10, viewModel.userLongitude)
//  }
//}
