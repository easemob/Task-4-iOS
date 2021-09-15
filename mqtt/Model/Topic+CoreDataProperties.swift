//
//  Topic+CoreDataProperties.swift
//  
//
//  Created by jailbreak2020 on 2021/8/25.
//
//

import Foundation
import CoreData
import SwiftyJSON
import Toast_Swift


extension Topic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Topic> {
        return NSFetchRequest<Topic>(entityName: "Topic")
    }

    @NSManaged public var desc: String?
    @NSManaged public var groupId: String?
    @NSManaged public var like: Int16
    @NSManaged public var link: String?
    @NSManaged public var subject: String?
    @NSManaged public var fav: Bool

}

extension Topic {
    
    public class func get(_ groupId: String, moc: NSManagedObjectContext) -> Topic? {
        let fq: NSFetchRequest<Topic> = Topic.fetchRequest()
        fq.predicate = NSPredicate(format: "groupId=%@", groupId)
        fq.fetchLimit = 1
        return try? moc.fetch(fq).first
    }
    
    @discardableResult
    public class func upsert(_ data: Data, moc: NSManagedObjectContext) -> Topic? {
        
        guard let d = try? JSON(data: data) , !data.isEmpty else {
            return nil
        }
        
        let id = d["groupId"].stringValue
        
        let fq: NSFetchRequest<Topic> = Topic.fetchRequest()
        fq.predicate = NSPredicate(format: "groupId=%@", id)
        
        if let topics = try? moc.fetch(fq) {
            var topic = topics.first
            if topic == nil {
                topic = NSEntityDescription.insertNewObject(forEntityName: "Topic", into: moc) as? Topic
                topic?.groupId = id
                
                let nvc = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
                
                nvc?.view.makeToast("有新话题,点击右上角选择", duration: 3.0, point: CGPoint(x: 100, y: 100), title: nil, image: nil, style: .init(), completion: nil)
            }
            
            if let l = d["like"].int16 {
                topic?.like = l
            }
            
            if let t = d["subject"].string {
                topic?.subject = t
            }
            
            if let l = d["link"].string {
                topic?.link = l
            }
            
            if let d = d["desc"].string {
                topic?.desc = d
            }
            
            try? moc.save()
            
            return topic
        }
        
        return nil
    }
}
