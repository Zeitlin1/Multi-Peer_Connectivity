//
//  ChatViewViewController.swift
//  Multipeer_Connect
//
//  Created by Anthony on 4/23/17.
//  Copyright © 2017 Anthony. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet weak var chatTextField: UITextField!
    
    @IBOutlet weak var chatTableViewOutlet: UITableView!
    
    @IBOutlet weak var endChatButton: UIButton!
    
    var messagesArray: [[String: String]] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var peerName: String = "User"
    
//    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("View Loading")
        
//        dateFormatter.dateStyle = .full
        
        chatTextField.delegate = self
        
        chatTableViewOutlet.dataSource = self
        
        chatTableViewOutlet.delegate = self
        
        chatTableViewOutlet.estimatedRowHeight = 60.0
        
        chatTableViewOutlet.rowHeight = UITableViewAutomaticDimension
        
        chatTableViewOutlet.setNeedsLayout()
        
        chatTableViewOutlet.layoutIfNeeded()

        let titleText = "Chat With \(peerName)"
        let titleTextLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        titleTextLabel.textAlignment = .center
        titleTextLabel.textColor = UIColor.white
        titleTextLabel.text = titleText
        navigationItem.titleView = titleTextLabel
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMPCReceivedDataWithNotification), name: NSNotification.Name.init(rawValue: "receivedMPCDataNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.lostConnectionUnwindBackToPeers), name: NSNotification.Name.init(rawValue: "unwindToPeers"), object: nil)
        
        endChatButton.snp.makeConstraints { (make) in
            make.left.equalTo(chatTextField.snp.left)
            make.width.equalTo(self.view).multipliedBy(0.2)
            make.top.equalTo(self.view).offset(25)
        }
        
        chatTextField.snp.makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.8)
            make.centerX.equalTo(self.view)
            make.top.equalTo(endChatButton.snp.bottom).offset(25)
        }
        chatTableViewOutlet.snp.makeConstraints { (make) in
            make.width.equalTo(self.view).multipliedBy(0.85)
            make.bottom.equalTo(self.view)
            make.top.equalTo(chatTextField.snp.bottom).offset(10)
            make.centerX.equalTo(self.view)
            chatTableViewOutlet.separatorColor = UIColor.clear
        }
        
        self.view.backgroundColor = UIColor.white
        
        self.automaticallyAdjustsScrollViewInsets = false
        
    }
    
    func unwindBackToPeers() {
        self.performSegue(withIdentifier: "unwindToPeersSegue", sender: self)
    }
    
    func lostConnectionUnwindBackToPeers() {
            
            let alert = UIAlertController(title: "", message: "Connection Terminated", preferredStyle: UIAlertControllerStyle.alert)
            
            let doneAction: UIAlertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.default) { (alertAction) -> Void in
        
                self.performSegue(withIdentifier: "unwindToPeersSegue", sender: self)
        
        }
            
            alert.addAction(doneAction)
            
            self.present(alert, animated: true, completion: nil)
        
    }
    
        @IBAction func endChat(_ sender: AnyObject) {
            
            if !appDelegate.mpcManager.session.connectedPeers.isEmpty {
            
            let messageDictionary: [String: String] = ["message": "_end_chat_"]
            
            appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary as [String : AnyObject], toPeer: appDelegate.mpcManager.session.connectedPeers[0] as MCPeerID, completion: { (success) in
                
                    unwindBackToPeers()
                    self.appDelegate.mpcManager.session.disconnect()
                
            })
                
            } else {
               
                unwindBackToPeers()
                self.appDelegate.mpcManager.session.disconnect()
            }
        }
    
    //Mark: tableViewOutlet delegate functions:
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell") as! ChatTableViewCell

        let currentMessage = messagesArray[indexPath.row] as [String: String]
        
        if let sender = currentMessage["sender"] {
            var senderLabelText: String
            
            var senderColor: UIColor
            
            if sender == "self" {
                
                senderLabelText = "I said:"
                
                senderColor = UIColor.purple
                
                cell.userNameText.textAlignment = .right
                
                cell.chatMssgText.textAlignment = .right
                
                cell.chatDateLabel.textAlignment = .left
                
            }
            else{
                senderLabelText = sender + " said:"
                
                senderColor = UIColor.orange
                
                cell.userNameText.textAlignment = .left
                
                cell.chatMssgText.textAlignment = .left
                
                cell.chatDateLabel.textAlignment = .right
            }
            
            cell.userNameText.text = senderLabelText
            cell.userNameText.textColor = senderColor
        }
        
        if let message = currentMessage["message"] {
            cell.chatMssgText.text = message
        }
        
        return cell
    }
    
    func updateTableview(){
        chatTableViewOutlet.reloadData()
        
        chatTableViewOutlet.setNeedsLayout()
        
        chatTableViewOutlet.layoutIfNeeded()
        
        if self.chatTableViewOutlet.contentSize.height > self.chatTableViewOutlet.frame.size.height {
            
            chatTableViewOutlet.scrollToRow(at: IndexPath(row: messagesArray.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
       
        }
    }

    
    //Mark: Observer Chat Message Function

    func handleMPCReceivedDataWithNotification(_ notification: Notification) {
        
        let receivedDataDictionary = notification.object as! [String: AnyObject]
        
        let data = receivedDataDictionary["data"] as? NSData
        
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID
        
        let dataDictionary = NSKeyedUnarchiver.unarchiveObject(with: data! as Data) as! [String: String]
       
        if let message = dataDictionary["message"] {
            
            if message == "_end_chat_"{
                
                let alert = UIAlertController(title: "", message: "\(fromPeer.displayName) ended this chat.", preferredStyle: UIAlertControllerStyle.alert)
                
                let doneAction: UIAlertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.default) { (alertAction) -> Void in
                    self.appDelegate.mpcManager.session.disconnect()
                    
                    self.navigationController?.popViewController(animated: true)
                }
                
                alert.addAction(doneAction)
                
                OperationQueue.main.addOperation({ () -> Void in
                    self.present(alert, animated: true, completion: nil)
                })
                
            } else {
                
            let messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
            
            messagesArray.append(messageDictionary)
                
            OperationQueue.main.addOperation({ () -> Void in
                
                self.updateTableview()
                
            })
                
            }
        }
    }
    
    
    
    // MARK: UITextFieldDelegate method implementation
    
    /// this gets fired whenever the user pushes return on the keyboard
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            
            textField.resignFirstResponder()
    
            let messageDictionary: [String: String] = ["message": textField.text!]
            
            if !appDelegate.mpcManager.session.connectedPeers.isEmpty {
            
                let peer = appDelegate.mpcManager.session.connectedPeers[0] as MCPeerID
                    
                appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary as [String : AnyObject], toPeer: peer) { (success) in
            
                    let dictionary: [String: String] = ["sender": "self", "message": textField.text!]
                    
                    messagesArray.append(dictionary)
                    
                    self.updateTableview()
                    
                    textField.text = ""
                }
            }
    
            return true
        }

}

