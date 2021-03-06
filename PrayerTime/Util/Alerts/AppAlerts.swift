//
//  AppAlerts.swift
//  PrayerTime
//
//  Created by Sheikh Ahmed on 24/05/2020.
//  Copyright © 2020 Sheikh Ahmed. All rights reserved.
//
import SwiftUI
// MARK:- Custom alert base class
struct APPAlertItem: Identifiable {
    var id = UUID()
    var type: APPAlerts
    init(type: APPAlerts){
        self.type = type
    }
    var alert: Alert?
}

// MARK:- APP alerts
enum APPAlerts: String {
    case invalidEmailAddress
    case incompleteRequiredData
    case unknownError
    case emailNotSet
    
    var title: String{
        return self.rawValue.titleCase()
    }
    var message: String {
        switch self {
        case .incompleteRequiredData:
            return "Please check the information you provided."
        default: return self.rawValue.titleCase()
        }
    }
    var dissmissButton: Alert.Button{
        switch self{
        case .invalidEmailAddress: return .default(Text("OK"))
        case .incompleteRequiredData: return .default(Text("OK"))
        default: return .cancel()
        }
        
    }
    var alert: Alert{
        switch self{
        default:
            return Alert(title: Text(self.title), message: Text(self.message), dismissButton: self.dissmissButton )
        }
    }
}
// MARK:- Umbrella Alerts
struct PrayerAlerts: Identifiable {
    var id = UUID()
    var alert: Alert
    init(customAlert: APPAlerts, error: Error?){
        if let error = error{
            switch error._code{
            default:
                let title = Text("Error code: \(error._code)")
                let message = Text(APPAlerts.unknownError.message)
                self.alert = Alert(title: title, message: message, dismissButton: .default(Text("OK")))
            }
        } else {
            self.alert = customAlert.alert
        }
    }
}
