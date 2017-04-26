//
//  ViewController.swift
//  Multipeer_Connect
//
//  Created by Anthony on 4/23/17.
//  Copyright © 2017 Anthony. All rights reserved.
//

import UIKit
import SnapKit
import MultipeerConnectivity

class PeersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MPCManagerDelegate {

    @IBOutlet weak var tableViewOutlet: UITableView!
    
    @IBOutlet weak var engageButton: UIButton!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    /// status of whether we are actively looking for other connections
    var isAdvertising: Bool!
    
    var peerName: String = "User"
    
    @IBAction func unwindToPeers(segue: UIStoryboardSegue) { /** Nothing goes here **/ }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        engageButton.snp.makeConstraints { (make) in
            make.width.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.height.equalTo(60)
            make.centerX.equalTo(self.view)
            engageButton.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        }
        
        tableViewOutlet.snp.makeConstraints { (make) in
            make.width.equalTo(self.view)
            make.bottom.equalTo(engageButton.snp.top)
            make.top.equalTo(self.view).offset(65)
            make.centerX.equalTo(self.view)
            tableViewOutlet.backgroundColor = UIColor.white
        }
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.view.backgroundColor = UIColor.black
        
        createInsets(onTableView: tableViewOutlet)
        
        tableViewOutlet.delegate = self
        
        tableViewOutlet.dataSource = self
        
        appDelegate.mpcManager.delegate = self
        
        appDelegate.mpcManager.browser.startBrowsingForPeers()
        
        appDelegate.mpcManager.advertiser.startAdvertisingPeer()
        
        isAdvertising = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBAction method implementation
    
    @IBAction func startStopAdvertising(_ sender: AnyObject) {
        let actionSheet = UIAlertController(title: "", message: "Change Visibility", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        var actionTitle: String
        if isAdvertising == true {
            actionTitle = "Make me invisible to others"
        }
        else{
            actionTitle = "Make me visible to others"
        }
        
        let visibilityAction: UIAlertAction = UIAlertAction(title: actionTitle, style: UIAlertActionStyle.default) { (alertAction) -> Void in
            if self.isAdvertising == true {
                self.appDelegate.mpcManager.advertiser.stopAdvertisingPeer()
                self.appDelegate.mpcManager.browser.stopBrowsingForPeers()
            }
            else{
                self.appDelegate.mpcManager.advertiser.startAdvertisingPeer()
                self.appDelegate.mpcManager.browser.startBrowsingForPeers()
            }
            
            self.isAdvertising = !self.isAdvertising
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(visibilityAction)
        
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
         tableViewOutlet.reloadData()
    }
    
    // MARK: UITableView related method implementation
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.mpcManager.foundPeers.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellPeer")! as UITableViewCell
        
        cell.textLabel?.text = appDelegate.mpcManager.foundPeers[indexPath.row].displayName
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 75.0
    }
    
    
    /// the sendor fires this
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPeer = appDelegate.mpcManager.foundPeers[indexPath.row] // as MCPeerID
        
        appDelegate.mpcManager.browser.invitePeer(selectedPeer, to: appDelegate.mpcManager.session, withContext: nil, timeout: 30)
        
        peerName = selectedPeer.displayName
    }
    
    // MARK: MPCManagerDelegate method implementation
    
    func foundPeer() {
        tableViewOutlet.reloadData()
    }
    
    func lostPeer() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "unwindToPeers"), object: nil)
        tableViewOutlet.reloadData()
    }
    
    /// this fires an alert on the receivee device after didReceiveInvitationFromPeer: when the inviting device selects table view cell
    func invitationWasReceived(fromPeer: String) {
        
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to connect", preferredStyle: .alert)
        
        /// this initiates a connection AND fires a segue to the chat view
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.default) { (alertAction) -> Void in
     
            self.appDelegate.mpcManager.invitationHandler(true, self.appDelegate.mpcManager.session)

            self.peerName = fromPeer
           
        }
        
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
            self.appDelegate.mpcManager.invitationHandler(false, nil)
        }
        
        alert.addAction(acceptAction)
        
        alert.addAction(declineAction)
        
        self.present(alert, animated: true) { }
    }
    
    /// this is called above in invitationWasReceived:
    func connectedWithPeer(peerID: MCPeerID) {
        
        self.performSegue(withIdentifier: "chatViewSegue", sender: self)

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "chatViewSegue" {
            
            if let dest = segue.destination as? ChatViewController {
                
                dest.peerName = peerName
                
            }
        }
    }
}

extension UIViewController {
    
    func createInsets(onTableView: UITableView) {
        
        onTableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        
        onTableView.separatorColor = UIColor.blue.withAlphaComponent(0.3)
        
        onTableView.preservesSuperviewLayoutMargins = true
        
        onTableView.separatorInset = UIEdgeInsets.init(top: 0.00, left: 15.0, bottom: 0.00, right: 15.00)
        
        onTableView.layoutMargins = UIEdgeInsets.zero
        
        onTableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0)
    }
}

