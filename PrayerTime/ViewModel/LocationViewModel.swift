//
//  LocationViewModel.swift
//  PrayerTime
//
//  Created by Sheikh Ahmed on 14/06/2020.
//  Copyright © 2020 Sheikh Ahmed. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import Adhan

class LocationViewModel: ObservableObject {
    
    @Published var locations: [Location] = []
    @Published var currentLocation: Location? {
        didSet {
            if let location = self.currentLocation {
                self.calculatePrayerTimes(location: location)
            }
        }
    }
    @Published var currentLocationIndex: Int = -1
    @Published var fajrTime: String = ""
    @Published var sunriseTime: String = ""
    @Published var duhrTime: String = ""
    @Published var asrTime: String = ""
    @Published var maghribTime: String = ""
    @Published var ishaTime: String = ""
    @Published var isCalculating: CalculationState  = .isCalculating
    @Published var gregorianTime: String = ""
    @Published var weekDay: String = ""
    @Published var hijriTime: String = ""
    @State var errorMessage: String?
    
    
    init() {
        self.reloadLocations()
    }
    func loadNextLocation(){
        if currentLocationIndex < locations.count - 1 {
            currentLocationIndex = currentLocationIndex + 1
            self.currentLocation = locations[currentLocationIndex]
        }
    }
    func loadPreviousLocation(){
        if currentLocationIndex > 0 {
            currentLocationIndex = currentLocationIndex - 1
            self.currentLocation = locations[currentLocationIndex]
        }
    }
    func reloadLocations(){
        self.locations = UserDefaults.standard.getLocations()
        if locations.count > 0 {
            self.currentLocationIndex = 0
            self.currentLocation = locations[0]
        }
    }
    public func calculatePrayerTimes(location: Location, method: CalculationMethod = .moonsightingCommittee){
        guard let timeZone = location.timeZone else {
            self.isCalculating = .finishedWithError
            return
        }
        let coordinates = Adhan.Coordinates(latitude: location.latitude, longitude: location.longitude)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        if let dateComponent = self.getDateInLocation(timeZone: timeZone) {
            if let prayerTimes = PrayerTimes(coordinates: coordinates, date: dateComponent, calculationParameters: method.params){
                self.fajrTime = self.calculateTime(time: prayerTimes.fajr, timeZone: timeZone)
                self.sunriseTime = self.calculateTime(time: prayerTimes.sunrise, timeZone: timeZone)
                self.duhrTime = self.calculateTime(time: prayerTimes.dhuhr, timeZone: timeZone)
                self.asrTime = self.calculateTime(time: prayerTimes.asr, timeZone: timeZone)
                self.maghribTime = self.calculateTime(time: prayerTimes.maghrib, timeZone: timeZone)
                self.ishaTime = self.calculateTime(time: prayerTimes.isha, timeZone: timeZone)
                self.gregorianTime = self.calculateLocalGregorianTime(time: Date(), timeZone: timeZone).toNarrativeDate(calendarType: .gregorian)
                self.weekDay = self.gregorianTime.weekDay()
                self.hijriTime = self.calculateLocalGregorianTime(time: Date(), timeZone: timeZone).toNarrativeDate(calendarType: .hijri)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.isCalculating = .finishedCalculating
                }
            }
            else {
                self.isCalculating = .finishedWithError
            }
        }
    }
    
    // show the calculated time in local time using timezone
    private func calculateTime(time: Date, timeZone: TimeZone)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        dateFormatter.timeZone = timeZone
        let convertedTime = dateFormatter.string(from: time).split(separator: " ")
        let timeComponents = convertedTime.filter {
            $0.contains(":")
        }.first?.split(separator: ":").dropLast().joined(separator: ":")
        if let result = timeComponents {
            return result
        }
        return ""
    }
    // calculate local time
    private func calculateLocalGregorianTime(time: Date, timeZone: TimeZone)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        dateFormatter.timeZone = timeZone
        let convertedTime = dateFormatter.string(from: time).split(separator: " ")
        if let result = convertedTime.first {
            return String(result)
        }
        return ""
    }
    
    // Prayer Times
    private func getDateInLocation(timeZone: TimeZone)->DateComponents?{
        let currentTime = Date()
        let remoteFormatter = DateFormatter()
        remoteFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        remoteFormatter.timeZone = timeZone
        if let remoteDateString = remoteFormatter.string(from: currentTime).split(separator: " ").first?.split(separator: "/"),
            remoteDateString.count == 3,
            let day = Int(remoteDateString[0]),
            let month = Int(remoteDateString[1]),
            let year = Int(remoteDateString[2])
        {
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = day
            return dateComponents
            
        }
        return nil
    }
}


