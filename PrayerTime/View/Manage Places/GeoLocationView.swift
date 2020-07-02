//
//  GeoLocationView.swift
//  PrayerTime
//
//  Created by Sheikh Ahmed on 27/05/2020.
//  Copyright © 2020 Sheikh Ahmed. All rights reserved.
//

import SwiftUI
import CoreLocation


struct GeoLocationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject var connectivityManager = ConnectivityManager()
    @ObservedObject var addLocationViewModel: AddLocationViewModel
    @State private var shouldGoBack: Bool = false
    @State private var locationPermissionStatus: Bool = false
    @State private var showLocationAlert: Bool = false
    @State private var showConnectivityAlert: Bool = false
    
    var body: some View {
        VStack {
            Image(systemName: "location")
                .foregroundColor(.blue)
        }
        .onTapGesture {
            if self.connectivityManager.monitor?.currentPath.status == .satisfied {
                switch self.locationManager.locationPermissionStatus{
                case .permissionGiven:
                    self.locationManager.requestAccess()
                case .permissionNotGiven:
                    self.showLocationAlert.toggle()
                case .notDetermined:
                    self.locationManager.requestAccess()
                }
            } else {
                self.showConnectivityAlert.toggle()
            }
        }.alert(isPresented: self.$showConnectivityAlert, content: {
            Alert(title: Text("APP needs Internet connection to calculate prayer times"),
                  message: Text("Your device is not connected to Internet. To add a location, Internet connection is necessary."),
                  dismissButton: .default(Text("OK")))
        })
            
            .onReceive(self.locationManager.$geoLocation, perform: { (geoLocation) in
                guard geoLocation != nil else {
                    //addLocationViewModel.errorMessage = locationManager
                    self.addLocationViewModel.errorMessage = self.locationManager.errorMessage ?? "Something went wrong, please check your network connection"
                    return
                }
                UserDefaults.standard.addLocation(location: geoLocation!)
                self.presentationMode.wrappedValue.dismiss()
            })
            
            
            .alert(isPresented: self.$showLocationAlert, content: {
                Alert(title: Text("APP needs permission to use your current location"),
                      message: Text("The permission is not allowed, please go to settings to change the settings"), primaryButton: .cancel(),
                      secondaryButton: .default(Text("Settings"), action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                      })
                )
            })
            
            .frame(width: 35, height: 35)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.blue, lineWidth: 1)
        )
    }
}
