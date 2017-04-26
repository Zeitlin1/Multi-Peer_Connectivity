//
//  MPCManager.swift
//  Multipeer_Connect
//
//  Created by Anthony on 4/23/17.
//  Copyright © 2017 Anthony. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MPCManagerDelegate {
    func foundPeer()
    
    func lostPeer()
    
    func invitationWasReceived(fromPeer: String)
    
    func connectedWithPeer(peerID: MCPeerID)
}


/**
 
BT <-> BT has effective range of ~41 feet (and through 1 flimsy wall)
 
1st test - Wireless <-> Wireless has effective range of ~50 feet through 2 walls and a wooden door
 
2nd test - Wireless <-> Wireless has effective range of ~50 feet direct no walls
 
**/


class MPCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {

    var session: MCSession!
    
    var peer: MCPeerID!
    
    var browser: MCNearbyServiceBrowser!
    
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    
    var invitationHandler: ((Bool, MCSession?) -> Void)!
    
    var delegate: MPCManagerDelegate?
    
    /// serviceType cannot be longer than 15 characters, and can contain only lowercase ASCII characters, numbers and hyphens
    let serviceType: String = "ant-multipeer"
    
    override init() {
        super.init()
        
        /// this gives you the name of yours and everyone else's device.  We should turn this into a hash for security purposes.
        peer = MCPeerID(displayName: UIDevice.current.name)
        
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: self.peer, serviceType: self.serviceType)
        browser.delegate = self
        
        /// look into how we can use discoveryInfo to pass data
        advertiser = MCNearbyServiceAdvertiser(peer: self.peer, discoveryInfo: nil, serviceType: self.serviceType)
        advertiser.delegate = self
        
    }
    
    @available(iOS 7.0, *)
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        
        /// check the peerid doesnt already exist in list and if it does replace it with new one?
        for (i, v) in foundPeers.enumerated() {
            if v == peerID {
                foundPeers.remove(at: i)
            }
        }
        
        
        foundPeers.append(peerID)
        
        /// this tells the tableview that a new peer has been found and to add it to the peers tableview
        delegate?.foundPeer()
    }
    
    /// this fires when one peer drops from network and removes peer from tableview
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        for (i, v) in foundPeers.enumerated() {
            if v == peerID {
                foundPeers.remove(at: i)
            }
        }
        delegate?.lostPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("ERROR OCCURED| \(error.localizedDescription)")
    }
    
    
    /// the RECEIVEE fires this after getting an invite
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        self.invitationHandler = invitationHandler
        
        delegate?.invitationWasReceived(fromPeer: peerID.displayName)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("ERROR DID NOT START ADVERTISING| \(error.localizedDescription)")
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
     
        switch state {
            
            /// this occurs shortly after above invite is accepted
        case MCSessionState.connecting:
           
            DispatchQueue.main.async {
                self.delegate?.connectedWithPeer(peerID: peerID)
            }
            print("Connecting to \(peerID.displayName) in session \(session)")
            
        /// this occurs as soon as our invite is accepted
        case MCSessionState.connected:
            
            print("Connected to \(peerID.displayName) in session: \(session)")
        
        default:
            break
        
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { print("Received Resources Func firing") }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) { print("Finished Receiving Resources Func firing") }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { print("Streaming Resources Func firing") }
    
    @available(iOS 7.0, *)
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("received data")
        let dictionary: [String: AnyObject] = ["data": data as AnyObject, "fromPeer": peerID]
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedMPCDataNotification"), object: dictionary)
    }
    
    func sendData(dictionaryWithData dictionary: [String: AnyObject], toPeer: MCPeerID, completion: (Bool)-> Void) {
        
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        
        print("MSSG HEaded to \(toPeer)")
        
        let peersArray = [toPeer]

        /// this may be how we can implement our private network streaming
//        session.startStream(withName: "Data Stream Name", toPeer: targetPeer)
        
        do {
            try session.send(dataToSend, toPeers: peersArray, with: MCSessionSendDataMode.reliable)
            
            completion(true)
        
        } catch {
            
            print(error.localizedDescription)
            completion(false)
        }
    }

}
