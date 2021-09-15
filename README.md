# Task-4-iOS

## 安装Pod

``` shell
pod install
```

## 添加你自己的Key

修改`Config`中的配置文件

```

struct MqttOptions {
    static let to = "" // xxx.cn1.mqtt.chat
    static let port = 1883
    static let appID = "" // xxx
    static let base = "https://api.cn1.mqtt.chat/app/xxx"
    
    static let orgName = ""
    static let appName = ""
    
    static var tokenBase: String {
        return "https://a1.easemob.com/\(orgName)/\(appName)/token"
    }
    
    static var appKey: String {
        return "\(orgName)#\(appName)"
    }
    static let clientID = ""
    static let clientSecret = ""
}

```

## Build & Run

## 点击左上角可以添加新话题

## 点击右上角可以选择任意话题
