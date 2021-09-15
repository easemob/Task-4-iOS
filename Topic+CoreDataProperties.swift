//
//  Topic+CoreDataProperties.swift
//  
//
//  Created by jailbreak2020 on 2021/8/24.
//
//

import Foundation
import CoreData


extension Topic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Topic> {
        return NSFetchRequest<Topic>(entityName: "Topic")
    }

    @NSManaged public var id: Int16
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var link: String?
    @NSManaged public var like: Int16

}
