//
//  ViewController.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/22/22.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
    
//    private let tableView : UITableView = {
//        let table = UITableView()
//        table.regis
//        return table
//    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .systemMint
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
}

