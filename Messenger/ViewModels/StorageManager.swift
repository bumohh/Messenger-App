//
//  StorageManager.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/24/22.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    private init() {}
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/emailname-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns competion with url string to download
    public func uploadProfilePicture(with data : Data, fileName : String, completion : @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] metadata, error in
            guard let strongSelf = self else { return }
            guard error == nil else {
                //failed
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned : \(urlString)")
                completion(.success(urlString))
            }
        })
    }
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                // failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    /// Upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl : URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        var data : Data?
        do {
            data = try Data(contentsOf: fileUrl)
        } catch let err {
            print("error putting data", err)
        }
        guard let data = data else { completion(.failure(StorageErrors.failedToConvert));return }
        storage.child("message_videos/\(fileName)").putData(data, metadata: nil) { [weak self] url, error in
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for video")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        }
    }
    
    //        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) {[weak self] url,error in
    //            guard error == nil else {
    //                // failed
    //                print("failed to upload data to firebase for video")
    //                completion(.failure(StorageErrors.failedToUpload))
    //                return
    //            }
    //
    //            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
    //                guard let url = url else {
    //                    print("Failed to get download url")
    //                    completion(.failure(StorageErrors.failedToGetDownloadURL))
    //                    return
    //                }
    //
    //                let urlString = url.absoluteString
    //                print("download url returned: \(urlString)")
    //                completion(.success(urlString))
    //            })
    //        }
//}

public enum StorageErrors : Error {
    case failedToConvert
    case failedToUpload
    case failedToGetDownloadURL
}

public func downloadURL(for path: String, completion: @escaping (Result<String, Error>) -> Void) {
    let reference = storage.child(path)
    reference.downloadURL { url, error in
        guard let url = url, error == nil else {
            completion(.failure(StorageErrors.failedToGetDownloadURL))
            return }
        completion(.success(url.absoluteString))
    }
}
}
