//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/23/22.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    static let shared = DatabaseManager()
    private init() {}
    private let database = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
    public func getDataFor(path: String, completion : @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else { completion(.failure(DatabaseError.failedToFetch));return }
            completion(.success(value))
        }
    }
}
// MARK: - Account Management
extension DatabaseManager {
    public func userExists(with email : String, completion : @escaping ((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with:  { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return }
            completion(true)
        })
    }
    /// Inserts new user to database
    public func insertUser(with user : ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue(["first_name":user.firstName, "last_name":user.lastName]) { error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            /*
             users => [
             [
             "name":
             "safe_email":
             ],
             [
             "name":
             "safe_email":
             ]
             ]
             */
            self.database.child("users").observeSingleEvent(of: .value) {[weak self] snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement = [
                        "name" : user.firstName + " " + user.lastName,
                        "email" : user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self?.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else { completion(false); return }
                        completion(true)
                    }
                } else {
                    //create that array
                    let newCollection : [[String:String]] = [
                        [
                            "name" : user.firstName + " " + user.lastName,
                            "email" : user.safeEmail
                        ]
                    ]
                    self?.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else { completion(false); return }
                        completion(true)
                    }
                }
            }
            completion(true)
        }
    }
    public func getAllUsers(completion : @escaping ((Result<[[String : String]], Error>)-> Void)) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String : String]] else { completion(.failure(DatabaseError.failedToFetch)); return }
            completion(.success(value))
        }
        
    }
    public enum DatabaseError : Error {
        case failedToFetch
    }
}

//MARK: Sending Messages / Conversations
extension DatabaseManager {
    
    /*
     
     "conversation_id" {
     "messages":[
     {
     "id":String,
     "type": text, photo, video,
     "content": String,
     "date": Date(),
     "sender_email": String,
     "isRead": Bool,
     }
     ]
     }
     
     conversation => [
     [
     "conversation_id": "conversation_id",
     "other_user_email":,
     "latest_message": => {
     "date": Date(),
     "latest_message": "message",
     "is_read": Bool,
     }
     ]
     ]
     */
    
    ///Creates a new conversation with target email and first message sent
    public func createNewConversation(with otherUserEmail: String , firstMessage: Message, name: String, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else { return }
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        let ref = database.child(safeEmail)
        let recipientRef = database.child("\(otherUserEmail)/conversations")
        ref.observeSingleEvent(of: .value) {[weak self] snapshot in
            guard var userNode = snapshot.value as? [String : Any] else {
                completion(false)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversationData : [String: Any] = [
                "id": conversationID,
                "name":name,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                ],
            ]
            
            let recipient_newConversationData : [String: Any] = [
                "id": conversationID,
                "name": currentName,
                "other_user_email": safeEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                ],
            ]
            
            //update recipient conversation entry
            recipientRef.observeSingleEvent(of: .value) { snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    //append
                    conversations.append(recipient_newConversationData)
                    recipientRef.setValue(conversationID)
                } else {
                    //create
                    recipientRef.setValue([recipient_newConversationData])
                }
            }
            //update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String:Any]]  {
                //conversation array exists for current user
                //you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    
                }
            } else {
                // conversation array does NOT exist
                //create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                    
                }
                
            }
        }
    }
    
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool)->Void) {
        //        {
        //            "id": String,
        //            "type": text, photo, video,
        //            "content": String,
        //            "date": Date(),
        //            "sender_email": String,
        //            "isRead": true/false,
        //        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
            print("messageText: ", messageText)
        case .attributedText(_), .photo(_), .video(_), .location(_), .emoji(_), .audio(_), .contact(_),.custom(_), .linkPreview(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else { completion(false); return }
        
        let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
        
        let collectionMessage : [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "name": name,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        let value : [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding convo: \(conversationID)")
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///Fetches and returns all conversation for the user with past in email
    public func getAllConversations(for email : String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations : [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool,
                      let otherUserEmail = dictionary["other_user_email"] as? String else {
                          return nil
                      }
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            print("conversations fetched : ",conversations)
            completion(.success(conversations))
        })
    }
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id : String, completion: @escaping (Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages : [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                          return nil
                      }
                var kind : MessageKind?
                if type == "photo" {
                    //photo
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else { return nil }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    //video
                    guard let videoUrl = URL(string: content),
                          let placeholder = UIImage(named: "video_placeholder") else { return nil }
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                } else {
                    //text
                    kind = .text(content)
                }
                guard let finalKind = kind else { return nil }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: finalKind)
            })
            
            print("messages fetched : ", messages)
            completion(.success(messages))
        })
    }
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation : String, otherUserEmail: String, name : String, newMessage: Message, completion : @escaping (Bool)->Void) {
        //add new message to messages
        //update sender latest message
        //update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else { completion(false);return }
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) {[weak self] snapshot in
            guard let strongSelf = self else { return }
            guard var currentMessages = snapshot.value as? [[String: Any]] else { completion(false);return}
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
                print("messageText: ", messageText)
            case .photo(let mediaItem) :
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem) :
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .attributedText(_), .location(_), .emoji(_), .audio(_), .contact(_),.custom(_), .linkPreview(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else { completion(false); return }
            
            let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
            
            let newMessageEntry : [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "name": name,
                "sender_email": currentUserEmail,
                "is_read": false
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else { completion(false);return }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else { completion(false); return }
                    
                    let updatedValue : [String:Any] = [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                    
                    var targetConversation : [String: Any]?
                    
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else { completion(false);return }
                    
                    currentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error == nil else { completion(false); return }
                    }
                    
                    // Update latest message for recipient user
                    strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                        guard var otherUserConversations = snapshot.value as? [[String: Any]] else { completion(false); return }
                        
                        let updatedValue : [String:Any] = [
                            "date": dateString,
                            "message": message,
                            "is_read": false
                        ]
                        
                        var targetConversation : [String: Any]? = [:]
                        
                        var position = 0
                        
                        for conversationDictionary in otherUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        targetConversation?["latest_message"] = updatedValue
                        guard let finalConversation = targetConversation else { completion(false);return }
                        
                        otherUserConversations[position-1] = finalConversation
                        strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
                            guard error == nil else { completion(false); return }
                        }
                        
                        
                        completion(true)
                    }
                }
            }
        }
    }
}
struct ChatAppUser {
    let firstName : String
    let lastName : String
    let emailAddress : String
    //let profilePictureUrl : String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName : String {
        //"emailname-gmail-com_profile_picture.png"
        return "\(safeEmail)_profile_picture.png"
    }
}

