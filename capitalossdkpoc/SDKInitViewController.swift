//
//  ViewController.swift
//  SamplePlaidClient
//
//  Created by Todd Kerpelman on 8/17/23.
//

import UIKit

public class SDKInitViewController: UIViewController {
    
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var simpleCallResults: UILabel!
    
    
    @IBOutlet var connectToPlaid: UIButton!
    @IBOutlet var simpleCallButton: UIButton!
    let communicator = SDKServerCommunicator()

    @IBAction func makeSimpleCallWasPressed(_ sender: Any) {
        // Ask our server to make a call to the Plaid API on behalf of our user
        self.communicator.callMyServer(path: "/server/simple_auth", httpMethod: .get) { (result: Result<SimpleAuthResponse, SDKServerCommunicator.Error>) in
            switch result {
            case .success(let response):
                print("success")
            case .failure(let error):
                print("error")
            }
            
        }
    }
    
    private func determineUserStatus() {
        self.communicator.callMyServer(path: "/server/get_user_info", httpMethod: .get) {
            (result: Result<UserStatusResponse, SDKServerCommunicator.Error>) in
            
            switch result {
            case .success(let serverResponse):
                self.userLabel.text = "Hello user \(serverResponse.userId)!"
                switch serverResponse.userStatus {
                case .connected:
                    self.statusLabel.text = "You are connected to your bank via Plaid. Make a call!"
                    self.connectToPlaid.setTitle("Make a new connection", for: .normal)
                    self.simpleCallButton.isEnabled = true;
                case .disconnected:
                    self.statusLabel.text = "You should connect to a bank"
                    self.connectToPlaid.setTitle("Connect", for: .normal)
                    self.simpleCallButton.isEnabled = false;
                }
                self.connectToPlaid.isEnabled = true;
            case .failure(let error):
                print(error)
            }
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // We'll refresh this every time our view appears
        determineUserStatus()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }
}
