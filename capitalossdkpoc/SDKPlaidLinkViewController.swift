//
//  PlaidLinkViewController.swift
//  SamplePlaidClients
//
//  Created by Todd Kerpelman on 8/18/23.
//

import UIKit
import LinkKit
import SwiftUI

public class SDKPlaidLinkViewController: UIViewController {
    //@IBOutlet var startLinkButton: UIButton!
    let communicator = SDKServerCommunicator()
    var linkToken: String?
    var handler: Handler?
    
    @objc func didButtonClick(_ sender: UIButton) {
        print("Link plaid button clicked")
        determineUserStatus()
    }
    
    override public func loadView() {
        view = UIView()
        view.backgroundColor = .lightGray
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        view.addSubview(stackView)
        let button = UIButton()
        button.setTitle("Link Plaid", for: .normal)
        button.addTarget(self, action: #selector(didButtonClick), for: .touchUpInside)

        stackView.addArrangedSubview(button)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func createLinkConfiguration(linkToken: String) -> LinkTokenConfiguration? {
        // Create our link configuration object
        // This return type will be a LinkTokenConfiguration object
        var linkTokenConfig = LinkTokenConfiguration(token: linkToken) { success in
        print("Link was finished successfully! \(success)")
            self.exchangePublicTokenForAccessToken(success.publicToken)
        }

        linkTokenConfig.onExit = { linkEvent in
        print("User exited link early \(linkEvent)")
        }
        
        linkTokenConfig.onEvent = { linkEvent in
            print("Hit an event \(linkEvent.eventName)")
        }
        
        return linkTokenConfig
    }
    
    private func determineUserStatus() {
        self.communicator.callMyServer(path: "/server/get_user_info", httpMethod: .get) {
            (result: Result<UserStatusResponse, SDKServerCommunicator.Error>) in
            
            switch result {
            case .success(let serverResponse):
           //     self.userLabel.text = "Hello user \(serverResponse.userId)!"
                self.fetchLinkToken()
                switch serverResponse.userStatus {
                    
                case .connected:
                    print("User connected")
                    //self.statusLabel.text = "You are connected to your bank via Plaid. Make a call!"
                   // self.connectToPlaid.setTitle("Make a new connection", for: .normal)
                   // self.simpleCallButton.isEnabled = true;
                case .disconnected:
                    print("User disconnected")
                   // self.statusLabel.text = "You should connect to a bank"
                   // self.connectToPlaid.setTitle("Connect", for: .normal)
                   // self.simpleCallButton.isEnabled = false;
                }
             //   self.connectToPlaid.isEnabled = true;
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func exchangePublicTokenForAccessToken(_ publicToken: String) {
        // Exchange our public token for an access token
        self.communicator.callMyServer(path: "/server/swap_public_token", httpMethod: .post, params: ["public_token": publicToken]) {
            (result: Result<SwapPublicTokenResponse, SDKServerCommunicator.Error>) in
            switch result {
            case .success(_):
                print("Public token exchanged for access token - success")
                print("Popping SDK view to return to the app")
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                print("Got an error \(error)")
            }
        }
    }
    
    private func fetchLinkToken() {
        self.communicator.callMyServer(path: "/server/generate_link_token", httpMethod: .post) { (result: Result<LinkTokenCreateResponse, SDKServerCommunicator.Error>) in switch result {
            case .success(let response):
            self.linkToken = response.linkToken
            guard let config = self.createLinkConfiguration(linkToken: response.linkToken) else {return}
            
            let creationResult = Plaid.create(config)
            switch creationResult {
            case .success(let handler):
                self.handler = handler
                print("Plaid created, opening Link")
                
                handler.open(presentUsing: .viewController(self))
            case .failure(let error):
                print("Handler creation error \(error)")
            }
             //   self.startLinkButton.isEnabled = true
            case .failure(let error):
                print(error)
            }
        }
    }

}
