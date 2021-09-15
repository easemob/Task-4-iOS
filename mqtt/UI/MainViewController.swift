//
//  ViewController.swift
//  mqtt
//
//  Created by jailbreak2020 on 2021/8/24.
//

import UIKit
import CoreData
import HyphenateChat
import Toast_Swift

class MainViewController: UIViewController {

    @IBOutlet weak var nextLabel: UILabel?
    @IBOutlet weak var onlineLabel: UILabel?
    
    @IBOutlet weak var topicLabel: UILabel?
    @IBOutlet weak var descLabel: UILabel?
    @IBOutlet weak var linkLabel: UILabel?
    @IBOutlet weak var likeLabel: UILabel?
    
    @IBOutlet weak var favButton: UIButton?
    
    private var timer: Timer?
    private var retryTimer: Timer?
    private var times = -1 {
        didSet {
            self.parent?.view.hideToastActivity()
            retryTimer?.invalidate()
            retryTimer = Timer(timeInterval: 5, repeats: false, block: { [weak self] _ in
                self?.parent?.view.makeToastActivity(.center)
                self?.loadData()
            })
        }
    }
    
    var topic: Topic! {
        didSet {
            chatVC?.groupId = topic.groupId
            let ms = NSMutableAttributedString(string: "    话题名称：", attributes: [.font: UIFont.boldSystemFont(ofSize: 14.0)])
            ms.append(NSAttributedString(string: topic.subject ?? "unknown subject"))
            
            topicLabel?.attributedText = ms
            
            let ms1 = NSMutableAttributedString(string: "    话题内容：", attributes: [.font: UIFont.boldSystemFont(ofSize: 14.0)])
            ms1.append(NSAttributedString(string: topic.desc ?? "unknown description"))
            descLabel?.attributedText = ms1
            
            let ms2 = NSMutableAttributedString(string: "    话题连接：", attributes: [.font: UIFont.boldSystemFont(ofSize: 14.0)])
            ms2.append(NSAttributedString(string: topic.link ?? "httmps://imgeek.rog", attributes: [.foregroundColor: UIColor.link]))
            linkLabel?.attributedText = ms2
            
            updateLike()
            
            // 查看是否已经进群,如果没有的话自动进群
            if let gm = EMClient.shared().groupManager {
                gm.getJoinedGroupsFromServer(withPage: 1, pageSize: 100) { groups, error in
                    if let `groups` = groups as? [EMGroup], !groups.isEmpty {
                        if (groups.first { g in g.groupId == self.topic.groupId }) != nil {
                            debugPrint("已经加入群聊")
                            return
                        }
                    }

                    // 加入群聊
                    gm.joinPublicGroup(self.topic.groupId) { _, error in
                        if let `error` = error {
                            debugPrint("join public group failed. \(error)")
                        }
                    }
                }
            }
            
            favButton?.setTitle(topic.fav ? "已收藏" : "收藏", for: .normal)
        }
    }
    
    private func updateLike() {
        let ms2 = NSMutableAttributedString(string: "    点  赞  数：", attributes: [.font: UIFont.boldSystemFont(ofSize: 14.0)])
        ms2.append(NSAttributedString(string: "\(topic!.like)人", attributes: [.foregroundColor: UIColor.green]))
        likeLabel?.attributedText = ms2
    }
    
    
    private var chatVC: ChatViewController?
    
    private var moc: NSManagedObjectContext {
        return Mqtt.shared.managedObjectContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        title = "话题聊天室"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"), style: .plain, target: self, action: #selector(showTopicList))
//        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(randomCreateNewTopic))
        
        for vc in children {
            if vc is ChatViewController {
                chatVC = vc as? ChatViewController
                break
            }
        }
        Mqtt.shared.mainVC = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange(notification:)), name: .NSManagedObjectContextObjectsDidChange, object: moc)
        
        // 等待5s 如果收不到任何host的信息， 那么自己就作为host
        parent?.view.makeToastActivity(.center)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + TimeInterval(5)) { [unowned self] in
            // 需要自己成为host
            if times == -1 {
                self.times = 0
                self.loadData()
            }
        }
        
        // 每60s 从数据库拿一条数据
//        loadData()
    }

    private func loadData() {
              
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let `self` = self else { return }
            let o = 60 - self.times % 60
            if o == 60 {
                self.loadTopic(times: self.times)
            }
//            else {
//                self.nextLabel?.text = "时间倒计时: 00: \(o >= 10 ? "\(o)" : "0\(o)")"
//            }
            
            self.times += 1
            Mqtt.shared.sync(topic: self.topic!, times: self.times)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func loadTopic(times: Int) {
        let request: NSFetchRequest<Topic> = Topic.fetchRequest()
        let groupId = NSSortDescriptor(key: "groupId", ascending: true)
        request.sortDescriptors = [groupId]
        
        if let total = try? self.moc.count(for: request), total > 0 {
            request.fetchOffset = times < total ? times : ((times / 60) % total)
            request.fetchLimit = 1
            if let topics = try? self.moc.fetch(request), !topics.isEmpty {
                self.topic = topics[0]
            }
        }
    }
    
    func refreshTopic(groupId: String, times: Int, like: Int16?) {
        if groupId != topic?.groupId {
            topic = Topic.get(groupId, moc: self.moc)
            timer?.invalidate()
        }
        if let likeCount = like {
            topic.like = likeCount
            try? topic.managedObjectContext?.save()
        }
        try? topic.managedObjectContext?.save()
        self.times = times
        let o = 60 - self.times % 60
        self.nextLabel?.text = "时间倒计时: 00: \(o >= 10 ? "\(o)" : "0\(o)")"
    }
    
    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Topic>, !updates.isEmpty, let ct = topic {
            for t in updates {
                if t.groupId == ct.groupId {
                    updateLike()
                }
            }
        }
    }
    
    
    @objc
    func showTopicList() {
        performSegue(withIdentifier: "ShowTopicList", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        ((segue.destination as? UINavigationController)?.topViewController as? TopicListViewController)?.mainVC = self
    }
    
//    @objc
//    func randomCreateNewTopic() {
//        showTopicList()
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 50000)) {
//            Mqtt.shared.randomNewTopic(subject: nil) { _ in
//
//            }
//        }
//    }
    
//    @IBAction func next(sender: UIButton) {
//        loadTopic(times: times + 60)
//    }
    
    @IBAction func like(sender: UIButton) {
        topic?.like += 1
        try? topic?.managedObjectContext?.save()
        Mqtt.shared.like(topic: topic!)
    }
        
    @IBAction func collect(sender: UIButton) {
        topic?.fav = !(topic?.fav ?? false)
        try? topic?.managedObjectContext?.save()
        favButton?.setTitle(topic.fav ? "已收藏" : "收藏", for: .normal)
    }
      
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

