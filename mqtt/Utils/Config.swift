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
    static let to = "4x1hh0.cn1.mqtt.chat"
    static let port = 1883
    static let appID = "4x1hh0"
    static let base = "https://api.cn1.mqtt.chat/app/4x1hh0"
    
    static let orgName = "1102200911042804"
    static let appName = "mqttdemo"
    
    static var tokenBase: String {
        return "http://a1.easecdn.com/\(orgName)/\(appName)/token"
    }
    
    static var appKey: String {
        return "\(orgName)#\(appName)"
    }
    static let clientID = "YXA6poUUQxR-SnCBXwJsG_Y5CQ"
    static let clientSecret = "YXA6Am5QYDm7Tmy-gAfJ_aylRkbDm18"
}

