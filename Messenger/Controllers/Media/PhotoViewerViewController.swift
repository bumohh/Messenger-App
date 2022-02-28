//
//  PhotoViewerViewController.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/22/22.
//

import UIKit
import SDWebImage

class PhotoViewerViewController: UIViewController {
    private let url : URL
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Photo"
        view.backgroundColor = .systemMint
        navigationItem.largeTitleDisplayMode = .never
        view.addSubview(imageView)
        self.imageView.sd_setImage(with: self.url, completed: nil)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    init(with url : URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
