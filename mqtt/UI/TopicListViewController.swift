//
//  TopicListViewController.swift
//  mqtt
//
//  Created by jailbreak2020 on 2021/8/24.
//

import UIKit
import CoreData
import SafariServices

class TopicCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    
    @IBOutlet weak var likeButton: UIButton!
    
    var topic: Topic!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.numberOfLines = 2
    }
    
    @IBAction func onTapLike(sender: UIButton) {
        topic.like += 1
        try? topic.managedObjectContext?.save()
        Mqtt.shared.like(topic: topic)
    }
       
}

class TopicListViewController: UIViewController {
    
    var fetchedResultsController: NSFetchedResultsController<Topic>!
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var mainVC: MainViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 65
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        
        let item = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem = item
        // Do any additional setup after loading the view.
        initializeFetchedResultsController()
    }
    
    @objc
    func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func initializeFetchedResultsController() {
        let request: NSFetchRequest<Topic> = Topic.fetchRequest()
        let like = NSSortDescriptor(key: "like", ascending: false)
        request.sortDescriptors = [like]
        
        let moc = Mqtt.shared.managedObjectContext
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
}

extension TopicListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? TopicCell else {
            fatalError("cell not found")
        }
        // Set up the cell
        guard let topic = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        cell.topic = topic
        cell.titleLabel.text = topic.subject
        cell.likeButton.setTitle("Like(\(topic.like))", for: .normal)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
     
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
}

extension TopicListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let t = fetchedResultsController?.object(at: indexPath)
        
        let vc = SFSafariViewController(url: URL(string: t!.link!)!)
        
        present(vc, animated: true, completion: nil)
    }
}

extension TopicListViewController: NSFetchedResultsControllerDelegate {
        
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .none)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .none)
        case .move:
            break
        case .update:
            break
        @unknown default:
            break
        }
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .none)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .none)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .none)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            break
        }
    }
     
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
