//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/23/22.
//

import Foundation
import FirebaseDatabase

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
            completion(true)
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
