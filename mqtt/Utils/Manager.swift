//
//  Manager.swift
//  mqtt
//
//  Created by jailbreak2020 on 2021/8/24.
//

import Foundation
import CocoaMQTT
import Alamofire
import SwiftyJSON
import HyphenateChat
import Fakery
import CoreData

private let defaultPassword = "888888"

class Mqtt: NSObject {
    
    static let shared = Mqtt()
    
    private var mqtt: CocoaMQTT?
    
    let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
    private let faker = Faker(locale: "en")
    
    private(set) var clientID: String!
    
    // 先简单写写
    var mainVC: MainViewController?
    
    override private init() {
        super.init()
        managedObjectContext.persistentStoreCoordinator = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.persistentStoreCoordinator
        
        let mockDataAlreadyImported = UserDefaults.standard.bool(forKey: "mockDataAlreadyImported")
        
        if mockDataAlreadyImported {
            return
        }
        
        UserDefaults.standard.setValue(true, forKey: "mockDataAlreadyImported")
        UserDefaults.standard.synchronize()
        
        func newTopic(_ groudId: String, link: String, subject: String, desc: String) {
            let t = NSEntityDescription.insertNewObject(forEntityName: "Topic", into: managedObjectContext) as! Topic
            t.groupId = groudId
            t.subject = subject
            t.desc = desc
            t.link = link
            t.like = 0
        }
        
        newTopic("159060742701057", link: "https://www.imgeek.org/article/825358260", subject: "奇思妙想 CSS 3D 动画 | 仅使用 CSS 能制作出多惊艳的动画？", desc: """
            本文将从比较多的方面详细阐述如何利用 CSS 3D 的特性，实现各类有趣、酷炫的动画效果。认真读完，你将会收获到：



            了解 CSS 3D 的各种用途
            激发你新的灵感，感受动画之美
            对于提升 CSS 动画制作水平会有所帮助
            """)
        newTopic("159060742701060", link: "https://www.imgeek.org/article/825358262", subject: "前端动画lottie-web", desc: "lottie是一个跨平台的动画库，通过AE（After Effects）制作动画，再通过AE插件Bodymovin导出Json文件，最终各个终端解析这个Json文件，还原动画。本文中我只介绍前端用到的库lottie-web。")
        newTopic("159060742701058", link: "https://www.imgeek.org/article/825358263", subject: "JS数字之旅——Number", desc: """
            首先来一段神奇的数字比较的代码


            23333333333333333 === 23333333333333332

            // output: true

            233333333333333330000000000 === 233333333333333339999999999

            // output: true

            咦？明明不一样的两个数字，为啥是相等的呢？
""")
        newTopic("159060742701059", link: "https://www.imgeek.org/article/825358259", subject: "想了解到底啥是个Web Socket？猛戳这里！！！", desc: """
            WebSocket 协议在2008年诞生，2011年成为国际标准，所有浏览器都已经支持了。其是基于TCP的一种新的网络协议，是 HTML5 开始提供的一种在单个TCP连接上进行全双工通讯的协议，它实现了浏览器与服务器全双工(full-duplex)通信——允许服务器主动发送信息给客户端。


            都有http协议了，为什么要用Web Socket

            WebSocket使得客户端和服务器之间的数据交换变得更加简单，允许服务端主动向客户端推送数据。在 WebSocket API 中，浏览器和服务器只需要完成一次握手，两者之间就直接可以创建持久性的连接，并进行双向数据传输。在 WebSocket API 中，浏览器和服务器只需要做一个握手的动作，然后浏览器和服务器之间就形成了一条快速通道，两者之间就直接可以数据互相传送。


            HTTP协议是一种无状态、单向的应用层协议，其采用的是请求/响应模型，通信请求只能由客户端发起，服务端对请求做出应答响应，无法实现服务器主动向客户端发起消息，这就注定如果服务端有连续的状态变化，客户端想要获知就非常的麻烦。而大多数Web应用程序通过频繁的异步JavaScript 和 aJax 请求实现长轮询，其效率很低，而且非常的浪费很多的带宽等资源。


            HTML5定义的WebSocket协议，能更好的节省服务器资源和带宽，并且能够更实时地进行通讯。WebSocket 连接允许客户端和服务器之间进行全双工通信，以便任一方都可以通过建立的连接将数据推送到另一端。WebSocket 只需要建立一次连接，就可以一直保持连接状态，这相比于轮询方式的不停建立连接显然效率要大大提高。
            """)
        newTopic("159060742701061", link: "https://www.imgeek.org/article/825358258", subject: "我写的页面打开才用了10秒，产品居然说我是腊鸡！！", desc: """
            产品：你看看这页面加载的如此之慢，怎么会有用户用呢？（并甩给了我一个录屏）
            我: （抛出前端应对之策）前端需要加载vue，js，html，css这些都需要时间呀，是不是，别说还需要接口请求，数据库查询，js执行，这些都需要时间是不是，所以加载慢很正常，让用户用wifi嘛。（嗯。。。心安理得，就是这样。。）
            产品: 你上一家公司就是因为有你这样的优秀员工才倒闭的吧？！
            """)
        
        try! managedObjectContext.save()
    }
    
    var needRegister: Bool {
        if let uid = UserDefaults.standard.string(forKey: "UserID"), !uid.isEmpty {
            return false
        }
        return true
    }
    
    func registerAndLogin(_ user: String, completion: @escaping (String?) -> ())  {
        EMClient.shared().register(withUsername: user, password: defaultPassword) { [unowned self] username, err in
            if err == nil {
                UserDefaults.standard.setValue(user, forKey: "UserID")
                UserDefaults.standard.synchronize()
                
                self.fetchTokenAndConnect(user)
                
                EMClient.shared().login(withUsername: username, password: "888888") { un, error in
                    EMClient.shared().options.isAutoLogin = true
                    completion(err?.errorDescription)
                    // 第一次登录插入模拟数据
                        
                        
            //            newTopic("https://www.imgeek.org/article/825357899", subject: "【环信IM集成指南】Android 端常见问题整理", desc: """
            //                1、如何修改系统通知中的头像和用户名
            //
            //                系统通知是在主module中自己写的，demo中是AgreeMsgDelegate，InviteMsgDelegate，OtherMsgDelegate中去修改头像和用户名。
            //                """)
            //
            //            newTopic("https://www.imgeek.org/question/262748", subject: "【验收中ing】环信MQTT创意编程挑战赛火热报名中！欢迎大家踊跃参赛～", desc: """
            //                本帖是本次环信MQTT创意编程挑战赛指定作品提交帖
            //                提交作品时，将作品github地址回复在本帖下方即可
            //                本次mqtt编程赛作品正在验收和评选中，由于还没有全部验收完，原定9月1日公布的比赛结果将延期(最多一周）请大家耐心等待！
            //                """)
            //
            //            newTopic("https://www.imgeek.org/article/825357508", subject: "【环信IM集成指南】iOS端常见问题整理", desc: """
            //                建议用浏览器搜索定位问题～
            //                本文持续更新，欢迎大家留言点菜～
            //
            //
            //                1、集成IM如何自定义添加表情组
            //
            //                https://www.imgeek.org/article/825357506
            //
            //
            //                2、旧版音视频与EaseCallKit兼容升级方案
            //
            //                https://www.imgeek.org/article/825357507
            //
            //
            //                3、如何集成环信EaseIMKit和EaseCallKit源码
            //                """)
            //
            //            newTopic("https://www.imgeek.org/article/825358357", subject: "Flutter 绘制番外篇 - 数学中的角度知识", desc: """
            //                对一些有趣的绘制技能和知识， 我会通过 [番外篇] 的形式加入《Flutter 绘制指南 - 妙笔生花》小册中，一方面保证小册的“与时俱进” 和 “活力”。另一方面，是为了让一些重要的知识有个 好的归宿。普通文章就像昙花一现，不管多美丽，终会被时间泯灭。
            //
            //
            //
            //
            //
            //                另外 [番外篇] 的文章是完全公开免费的，也会同时在普通文章中发表，且 [番外篇] 会在普通文章发布三日后入驻小册，这样便于错误的暴露和收集建议反馈。本文作为 [番外篇] 之一，主要来探讨一下角度和坐标 的知识。
            //
            //
            //                """)
            //
            //            newTopic("https://www.imgeek.org/article/825358354", subject: "译）Kotlin中的Lateinits vs Nullables", desc: """
            //                Lateinit修饰符
            //                通常来说，kotlin中所有不可空的属性都必须被正确地初始化。你可以用很多方式实现：
            //
            //                在主构造器中,
            //                在初始化代码块中,
            //                直接在类里的属性声明中,
            //                在getter方法中*,
            //                用delegate实现*.
            //                *的方法严格意义上来说并不是初始化，但是它使得编译器理解这些变量是非null。
            //
            //                但如果一个属性是生命周期驱动的（例如：一个button的引用，它会在Activity的生命周期中被inflated出来）或者它需要通过注入来初始化，那就没办法提供一个non-null的初始化，就只能把它声明成可空的。这就需要你每次使用它都进行null checks，很麻烦，尤其是在你百分百确定它在被使用之前，一定会被初始化的时候。
            //
            //                所以kotlin给这种情况提供了一种简单的解决方案，lateinit修饰符。这样就不需要每次都做null checks了，当然如果用到的时候该属性没有被初始化，系统就会抛出UninitializedPropertyAccessException。
            //                """)
            //
            //
            //            try? managedObjectContext.save()
                }
            } else {
                completion(err?.errorDescription)
            }
        }
    }
    
    func connectLast() {
        guard let uid = UserDefaults.standard.string(forKey: "UserID"), !uid.isEmpty else {
            return
        }
        EMClient.shared().login(withUsername: uid, password: "888888") { _, _ in }
        self.fetchTokenAndConnect(uid)
    }
    
    private func fetchTokenAndConnect(_ username: String) {
        
        AF.request(MqttOptions.tokenBase, method: .post, parameters: ["username": username, "password": defaultPassword, "grant_type": "password"], encoder: JSONParameterEncoder.default)
            .responseData { [unowned self] response in
                let result = response.result.map { JSON($0) }
                switch result {
                    case .success(let r):
                        let token = r["access_token"].stringValue
                        let uuid = r["user", "uuid"].stringValue
                        clientID = "\(uuid)@\(MqttOptions.appID)"
                        
                        let offline = (clientID + "|0")
                        
                        let mqtt = CocoaMQTT(clientID: clientID, host: MqttOptions.to)
                        mqtt.username = username
                        mqtt.password = token
                        mqtt.willMessage = CocoaMQTTWill(topic: "client/status", message: offline)
                        mqtt.keepAlive = 60
                        if !mqtt.connect() {
                            debugPrint("connect failed")
                        }
                       
                        mqtt.didReceiveMessage = { [weak self] mqtt, message, id in
                            debugPrint("process id: \(id)")
                            self?.process(message: message)
                        }
                        
                        mqtt.delegate = self
                        self.mqtt = mqtt
                    case .failure(let e):
                        debugPrint(e.errorDescription ?? "unknown error")
                }
        }
    }
    
    func like(topic: Topic) {
        // 点击按钮的时候 已经自增过了
        if let data = JSON(["groupId": topic.groupId as Any, "like": topic.like]).rawString() {
            mqtt?.publish(CocoaMQTTMessage(topic: "topic", string: data, qos: .qos1, retained: true, dup: false))
        }
    }
    
    func sync(topic: Topic, times: Int) {
        if let data = JSON(["groupId": topic.groupId as Any, "times": times, "like": topic.like]).rawString() {
            mqtt?.publish(CocoaMQTTMessage(topic: "sync", string: data, qos: .qos1, retained: true, dup: false))
        }
    }
    
//    func randomNewTopic(subject: String?, completion: @escaping (String?) -> ()) {
//        let gm = EMClient.shared().groupManager
//
//        let subject = subject ?? faker.company.name()
//        let description = faker.lorem.words(amount: 55)
//        let options = EMGroupOptions()
//        options.isInviteNeedConfirm = false
//        options.style = EMGroupStylePublicOpenJoin
//
//        gm?.createGroup(withSubject: subject, description: description, invitees: [], message: "", setting: options, completion: { [weak self] group, error in
//            guard let `group` = group, let `self` = self else {
//                debugPrint("error: \(error?.errorDescription ?? "unkown error")")
//                return
//            }
//            let json = JSON(["groupId": group.groupId!,
//                             "subject": subject,
//                             "desc": description,
//                             "like": self.faker.number.randomInt(),
//                             "link": self.faker.internet.url()])
//            //
//            completion(error?.errorDescription)
//            self.mqtt?.publish(CocoaMQTTMessage(topic: "topic", string: json.rawString()!, qos: .qos2, retained: true, dup: false))
//        })
//    }
    
    private func process(message: CocoaMQTTMessage) {
                // topic 相关的更新啦
        if message.topic == "topic" {
            Topic.upsert(Data(message.payload), moc: managedObjectContext)
        } else if message.topic == "sync" {
            let data = JSON(Data(message.payload))
            self.mainVC?.refreshTopic(groupId: data["groupId"].stringValue, times: data["times"].intValue, like: data["like"].int16)
        } else if message.topic == "client/status" {
            // 在线人数
            if let payload = message.string {
                let info = payload.split(separator: "|")
                if info.count == 2 {
                    if info[1] == "1" {
                        onlineDevice.insert(info[0])
                    } else {
                        onlineDevice.remove(info[0])
                    }
                    DispatchQueue.main.async { [unowned self] in
                        self.mainVC?.onlineLabel?.text = "\(self.onlineDevice.count)人"
                    }
                }
            }
        }
    }
    
    var onlineTimer: Timer?
    var onlineDevice = Set<Substring>()
}

extension Mqtt: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
       
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        
    }
    
           
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        
    }
    // deprecated!!! instead of `func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String])`
    //func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String)
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        debugPrint("error: \(err)")
    }
    
    @objc func mqtt(_ mqtt: CocoaMQTT, didPublishComplete id: UInt16) {
        
    }
    
    @objc func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        if state == .connected {
            mqtt.subscribe("topic")
            mqtt.subscribe("client/status")
            mqtt.subscribe("sync")
            
            func online() {
                let online = "\(mqtt.clientID)|1"
                mqtt.publish(CocoaMQTTMessage(topic: "client/status", string: online))
            }
            
            online()
            onlineTimer = Timer(timeInterval: 10, repeats: true, block: { _ in
                // 发送上线消息
                online()
            })
            
            RunLoop.main.add(onlineTimer!, forMode: .default)
        } else {
            onlineTimer?.invalidate()
            onlineTimer = nil
        }
    }
}


