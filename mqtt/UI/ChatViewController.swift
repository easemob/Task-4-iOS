//
//  ChatViewController.swift
//  mqtt
//
//  Created by jailbreak2020 on 2021/8/25.
//

import UIKit
import HyphenateChat
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController, MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    
    private var messages = [EMMessage]()
    private var conversation: EMConversation?
    
    var groupId: String! {
        didSet {
            messages.removeAll()
            conversation = EMClient.shared().chatManager.getConversation(groupId, type: EMConversationTypeGroupChat, createIfNotExist: true)
            conversation?.loadMessagesStart(fromId: nil, count: 50, searchDirection: EMMessageSearchDirectionUp) { [weak self] m, err in
                if let aMessages = m as? [EMMessage] {
                    self?.messages.append(contentsOf: aMessages)
                    self?.messagesCollectionView.reloadData()
                    self?.messagesCollectionView.scrollToLastItem()
                }
            }
        }
    }   
    
//    private func sendMessage(_ body: EMMessageBody?) {
//        let from = EMClient.shared().currentUsername
//        let cid = dataSource!.conversation!.conversationId
//        let message = EMMessage(conversationID: cid, from: from, to: groupId, body: body, ext: [:])
//        message?.chatType = EMChatTypeGroupChat
//        EMClient.shared().chatManager.send(message!) { p in
//            debugPrint("progress \(p)")
//        } completion: { msg, err in
//            debugPrint("msg: \(msg) err: \(err)")
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messagesCollectionView.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        EMClient.shared().chatManager.add(self, delegateQueue: DispatchQueue.main)
        
        configureMessageInputBar()
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = UIColor.blue
        messageInputBar.inputTextView.placeholder = "Join discussion 🚀"
        messageInputBar.sendButton.setTitleColor(.blue, for: .normal)
        messageInputBar.sendButton.setTitleColor(UIColor.blue.withAlphaComponent(0.3), for: .highlighted)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
        
    func currentSender() -> SenderType {
        return EMClient.shared().currentUsername
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return Message(messages[indexPath.section])
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
}

extension ChatViewController: EMChatManagerDelegate {
    
    func messagesDidReceive(_ aMessages: [Any]!) {
        guard let messages = aMessages as? [EMMessage] else {
            fatalError()
        }
        self.messages.append(contentsOf: messages)
        self.messagesCollectionView.reloadData()
        self.messagesCollectionView.scrollToLastItem()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {

    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }

    func processInputBar(_ inputBar: InputBarAccessoryView) {
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in

            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        let body = EMTextMessageBody(text: inputBar.inputTextView.text)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        // Resign first responder for iPad split view
        inputBar.inputTextView.resignFirstResponder()
        
        let message = EMMessage(conversationID: conversation?.conversationId, from: currentSender().senderId, to: groupId, body: body, ext: nil)
        message?.chatType = EMChatTypeGroupChat
        
        EMClient.shared().chatManager.send(message, progress: nil) { [weak self] m, err in
            if let message = m {
                DispatchQueue.main.async { [weak self] in
                    inputBar.sendButton.stopAnimating()
                    inputBar.inputTextView.placeholder = "Join discussion 🚀"
                    self?.messages.append(message)
                    self?.messagesCollectionView.reloadData()
                    self?.messagesCollectionView.scrollToLastItem()
                }
            }
        }
        
    }
}

extension String: SenderType {
    public var senderId: String {
        self
    }
    
    public var displayName: String {
        self
    }

}

struct Message: MessageType {
    
    var messageId: String {
        _m.messageId
    }
    
    
    private let _m: EMMessage
    
    init(_ m: EMMessage) {
        _m = m
    }
    
    public var sender: SenderType {
        _m.from
    }
        
    public var sentDate: Date {
        Date(timeIntervalSince1970: Double(_m.timestamp))
    }
    
    public var kind: MessageKind {
        if let tb = _m.body as? EMTextMessageBody {
            return .text(tb.text)
        }
               
        fatalError("unsupport message")
    }
}
