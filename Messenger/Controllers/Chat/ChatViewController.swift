//
//  ChatViewController.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/23/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

struct Message : MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
    
}

struct Media : MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location : LocationItem {
    var location : CLLocation
    var size : CGSize
}

extension MessageKind {
    var messageKindString : String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}
struct Sender : SenderType {
    public var photoURL : String
    public var senderId: String
    public var displayName: String
    
    
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail : String
    private let conversationId : String?
    
    private var messages = [Message]()
    
    private var selfSender : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return nil }
        let safeEmail = DatabaseManager.safeEmail(email: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }
    
    init(with email : String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) {[weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else { return }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed to get messages : \(error)")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .cyan
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside {[weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionsheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionsheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            
        }))
        present(actionSheet,animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = {[weak self] selectedCoordinates in
            guard let strongSelf = self else { return }
            let longitude = selectedCoordinates.longitude
            let latitude = selectedCoordinates.latitude
            print("long: \(longitude)\nlat: \(latitude)")
            guard let messageId = strongSelf.createMessageId(),
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else { return }
            let media = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .location(media))
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("Sent location message")
                } else {
                    print("Failed to send photo message")
                }
            }
            
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionsheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "What would you like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet,animated: true)
    }
    
    private func presentVideoInputActionsheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "What would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet,animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

// MARK: Image picker required functions
extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = self.selfSender else { return }
        if let image = info[.editedImage] as? UIImage,
           let imageData = image.pngData() {
            let filename = "photo_message_\(messageId)".replacingOccurrences(of: " " , with: "-") + ".png"
            
            //upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: filename) { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let urlString) :
                    // Ready to send message
                    print("Uploaded Message Photo : \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else { return }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("Sent photo message")
                        } else {
                            print("Failed to send photo message")
                        }
                    }
                case .failure(let error) :
                    print("Message photo upload error : \(error)")
                }
            }
        } else if let videoUrl = info[.mediaURL] as? URL {
            let filename = "video_message_\(messageId)".replacingOccurrences(of: " " , with: "-") + ".mov"
            
            //Upload Video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: filename) { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let urlString) :
                    // Ready to send message
                    print("Uploaded Message Video : \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else { return }
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .video(media))
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("Sent video message")
                        } else {
                            print("Failed to send video message")
                        }
                    }
                case .failure(let error) :
                    print("Message video upload error : \(error)")
                }
            }
        }
    }
}

extension ChatViewController : InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let messageId = createMessageId(),
              let selfSender = self.selfSender else { return }
        print("sending text")
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        //send message
        if isNewConversation {
            //create convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, name: self.title ?? "User") {[weak self] success in
                if success {
                    print("Message sent")
                    self?.isNewConversation = false
                } else {
                    print("Failed to send")
                }
            }
        }
        else {
            //append to existing conversation data
            guard let conversationId = conversationId, let name = self.title else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail : otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("Message sent")
                } else {
                    print("Failed to send")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        let dateString = Self.dateFormatter.string(from: Date())
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil }
        let safeCurrentEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        return newIdentifier
        
    }
}
extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default :
            break
        }
    }
}

extension ChatViewController : MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
        default :
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else { return }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
            
        default :
            break
        }
    }
}
