//
//  String+extension.swift
//  PrayerTime
//
//  Created by Sheikh Ahmed on 08/05/2020.
//  Copyright © 2020 Sheikh Ahmed. All rights reserved.
//

import SwiftUI
import CommonCrypto

enum CalendarType{
    case hijri
    case gregorian
}


extension String {
   struct Formatter {
       static let utcFormatter: DateFormatter = {
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssz"
           
           return dateFormatter
       }()
   }
 
   var dateFromUTC: Date? {
       return Formatter.utcFormatter.date(from: self)
   }
}





extension String {
    func toNarrativeDate(calendarType: CalendarType)->String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        var result = ""
        if let date = dateFormatter.date(from: self){
            switch calendarType{
            case .gregorian:
                result = date.goergianDate()
            case .hijri:
                result = date.hijriDate()
            }
        }
        return result
    }
    func weekDay()->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        var result = ""
        if let date = dateFormatter.date(from: self){
            result = date.weekDay()
        }
        return result
    }
}
    
    
    // MARK:- get the first four digits from a string
    extension String{
        func showFirstFourDigits()->String{
            var result = self
            if let _ = result.firstIndex(of: ".") {
                let tempString = result.split(separator: ".")
                let first = tempString.first ?? ""
                let last = tempString.last?.prefix(4) ?? ""
                result = "\(String(first)).\(String(last))"
            }
            return result
        }
    }
    // MARK:- Sentance case string from enum value
    extension String{
        func titleCase() -> String {
            return self
                .replacingOccurrences(of: "([A-Z])",
                                      with: " $1",
                                      options: .regularExpression,
                                      range: range(of: self))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .capitalized // If input is in llamaCase
        }
    }
    
    // encript string to data
    extension String {
        func encriptString() -> Data {
            do {
                
                let key256 = "ierdfrghtydier561234067890123456" // 32 bytes for AES256
                
                let aes256 = try AES(keyString: key256)
                let encryptedData = try aes256.encrypt(self)
                return encryptedData
            } catch {
                return Data()
            }
        }
    }
    
    // decript data to string
    extension Data {
        func decriptData() -> String {
            do {
                let key256 = "ierdfrghtydier561234067890123456" // 32 bytes for AES256
                let aes256 = try AES(keyString: key256)
                let decriptedString = try aes256.decrypt(self)
                return decriptedString
            } catch {
                return String()
            }
        }
    }
    extension String {
        func hashStringUsingSHA256() -> String {
            
            if let strData = self.data(using: String.Encoding.utf8) {
                
                var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
                
                _ = strData.withUnsafeBytes {
                    
                    CC_SHA256($0.baseAddress, UInt32(strData.count), &digest)
                }
                
                var sha256String = ""
                
                for byte in digest {
                    sha256String += String(format:"%02x", UInt8(byte))
                }
                
                return sha256String
            }
            return ""
        }
    }
    
    
    protocol Cryptable {
        func encrypt(_ string: String) throws -> Data
        func decrypt(_ data: Data) throws -> String
    }
    
    struct AES {
        private let key: Data
        private let ivSize: Int         = kCCBlockSizeAES128
        private let options: CCOptions  = CCOptions(kCCOptionPKCS7Padding)
        
        init(keyString: String) throws {
            guard keyString.count == kCCKeySizeAES256 else {
                throw Error.invalidKeySize
            }
            self.key = Data(keyString.utf8)
        }
    }
    
    extension AES {
        enum Error: Swift.Error {
            case invalidKeySize
            case generateRandomIVFailed
            case encryptionFailed
            case decryptionFailed
            case dataToStringFailed
        }
    }
    
    private extension AES {
        
        func generateRandomIV(for data: inout Data) throws {
            
            try data.withUnsafeMutableBytes { dataBytes in
                
                guard let dataBytesBaseAddress = dataBytes.baseAddress else {
                    throw Error.generateRandomIVFailed
                }
                
                let status: Int32 = SecRandomCopyBytes(
                    kSecRandomDefault,
                    kCCBlockSizeAES128,
                    dataBytesBaseAddress
                )
                
                guard status == 0 else {
                    throw Error.generateRandomIVFailed
                }
            }
        }
    }
    
    extension AES: Cryptable {
        
        func encrypt(_ string: String) throws -> Data {
            let dataToEncrypt = Data(string.utf8)
            
            let bufferSize: Int = ivSize + dataToEncrypt.count + kCCBlockSizeAES128
            var buffer = Data(count: bufferSize)
            try generateRandomIV(for: &buffer)
            
            var numberBytesEncrypted: Int = 0
            
            do {
                try key.withUnsafeBytes { keyBytes in
                    try dataToEncrypt.withUnsafeBytes { dataToEncryptBytes in
                        try buffer.withUnsafeMutableBytes { bufferBytes in
                            
                            guard let keyBytesBaseAddress = keyBytes.baseAddress,
                                let dataToEncryptBytesBaseAddress = dataToEncryptBytes.baseAddress,
                                let bufferBytesBaseAddress = bufferBytes.baseAddress else {
                                    throw Error.encryptionFailed
                            }
                            
                            let cryptStatus: CCCryptorStatus = CCCrypt( // Stateless, one-shot encrypt operation
                                CCOperation(kCCEncrypt),                // op: CCOperation
                                CCAlgorithm(kCCAlgorithmAES),           // alg: CCAlgorithm
                                options,                                // options: CCOptions
                                keyBytesBaseAddress,                    // key: the "password"
                                key.count,                              // keyLength: the "password" size
                                bufferBytesBaseAddress,                 // iv: Initialization Vector
                                dataToEncryptBytesBaseAddress,          // dataIn: Data to encrypt bytes
                                dataToEncryptBytes.count,               // dataInLength: Data to encrypt size
                                bufferBytesBaseAddress + ivSize,        // dataOut: encrypted Data buffer
                                bufferSize,                             // dataOutAvailable: encrypted Data buffer size
                                &numberBytesEncrypted                   // dataOutMoved: the number of bytes written
                            )
                            
                            guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
                                throw Error.encryptionFailed
                            }
                        }
                    }
                }
                
            } catch {
                throw Error.encryptionFailed
            }
            
            let encryptedData: Data = buffer[..<(numberBytesEncrypted + ivSize)]
            return encryptedData
        }
        
        func decrypt(_ data: Data) throws -> String {
            
            let bufferSize: Int = (data.count) - ivSize
            guard bufferSize > 0 else {return String()}
            var buffer = Data(count: bufferSize)
            
            var numberBytesDecrypted: Int = 0
            
            do {
                try key.withUnsafeBytes { keyBytes in
                    try data.withUnsafeBytes { dataToDecryptBytes in
                        try buffer.withUnsafeMutableBytes { bufferBytes in
                            
                            guard let keyBytesBaseAddress = keyBytes.baseAddress,
                                let dataToDecryptBytesBaseAddress = dataToDecryptBytes.baseAddress,
                                let bufferBytesBaseAddress = bufferBytes.baseAddress else {
                                    throw Error.encryptionFailed
                            }
                            
                            let cryptStatus: CCCryptorStatus = CCCrypt( // Stateless, one-shot encrypt operation
                                CCOperation(kCCDecrypt),                // op: CCOperation
                                CCAlgorithm(kCCAlgorithmAES128),        // alg: CCAlgorithm
                                options,                                // options: CCOptions
                                keyBytesBaseAddress,                    // key: the "password"
                                key.count,                              // keyLength: the "password" size
                                dataToDecryptBytesBaseAddress,          // iv: Initialization Vector
                                dataToDecryptBytesBaseAddress + ivSize, // dataIn: Data to decrypt bytes
                                bufferSize,                             // dataInLength: Data to decrypt size
                                bufferBytesBaseAddress,                 // dataOut: decrypted Data buffer
                                bufferSize,                             // dataOutAvailable: decrypted Data buffer size
                                &numberBytesDecrypted                   // dataOutMoved: the number of bytes written
                            )
                            
                            guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
                                throw Error.decryptionFailed
                            }
                        }
                    }
                }
            } catch {
                throw Error.encryptionFailed
            }
            
            let decryptedData: Data = buffer[..<numberBytesDecrypted]
            
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw Error.dataToStringFailed
            }
            
            return decryptedString
        }
}
