//
//  Config.swift
//  mqtt
//
//  Created by jailbreak2020 on 2021/8/24.
//

import Foundation

// 以下这些key 都需要替换成自己的

struct MqttOptions {
    
    // test
    static let to = <#T##String#>
    static let port = 1883
    static let appID = <#T##String#>
    static let base = <#T##String#>
    
    static let orgName = <#T##String#>
    static let appName = <#T##String#>
    
    static var tokenBase: String {
        return "http://a1.easecdn.com/\(orgName)/\(appName)/token"
    }
    
    static var appKey: String {
        return "\(orgName)#\(appName)"
    }
    static let clientID = <#T##String#>
    static let clientSecret = <#T##String#>
}

