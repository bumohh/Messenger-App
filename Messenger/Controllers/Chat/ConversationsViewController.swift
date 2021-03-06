//
//  ViewController.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/22/22.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import NotificationCenter

struct Conversation {
    let id : String
    let name : String
    let otherUserEmail : String
    let latestMessage : LatestMessage
}

struct LatestMessage {
    let date : String
    let text : String
    let isRead : Bool
}
class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    private let tableView : UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel : UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight : .medium)
        label.isHidden = true
        return label
    }()
    
    private var loginObserver : NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.backgroundColor = .systemMint
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setupTableView()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            print("logged in now fetching conversations because observer noticed login")
            guard let strongSelf = self else { return }
            strongSelf.startListeningForConversations()
        })
        
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        print("starting conversation fetch")
        let safeEmail = DatabaseManager.safeEmail(email: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) {[weak self] result in
            switch result {
            case .success(let conversations):
                print("sucessfully got conversation models")
                self?.conversations = conversations
                print(conversations)
                guard !conversations.isEmpty else {
                    print("conversations are empty!");return
                }
                DispatchQueue.main.async {
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("Failed to get convos: \(error)")
            }
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = {[weak self] result in
            guard let strongSelf = self else { return }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversations = currentConversations.first(where: {$0.otherUserEmail == DatabaseManager.safeEmail(email: result.email)}) {
                let vc = ChatViewController(with: targetConversations.otherUserEmail, id: targetConversations.id)
                vc.isNewConversation = false
                vc.title = targetConversations.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            } else {
                strongSelf.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result : SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(email: result.email)
        
        //check in database if conversation with these two users exists
        //if it does, reuse conversation id
        //otherwise use existing code
        DatabaseManager.shared.conversationExists(with: email) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
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
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}

// MARK: Table View Config
extension ConversationsViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell
                                                    .identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model : Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //begin delete
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in	
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    
                    self?.tableView.deleteRows(at: [indexPath], with: .left)
                }
            }
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
