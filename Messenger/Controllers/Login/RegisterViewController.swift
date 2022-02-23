//
//  LoginViewController.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/22/22.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let firstNameField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let lastNameField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.isSecureTextEntry = true
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let registerButton : UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = UIColor.darkerColorForColor(color: .green)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Register"
        view.backgroundColor = .green
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        firstNameField.delegate = self
        lastNameField.delegate = self
        
        
        //Add subviews
        view.addSubview(scrollView)
        //Add to scroll view
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        
    }
    
    @objc private func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    
    @objc private func registerButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        guard let email = emailField.text,
              let password = passwordField.text,
              let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              !email.isEmpty,
              !password.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              password.count >= 6 else {
                  alertUserLoginError()
                  return }
        
        //Firebase Login
        
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Incorrect Login", message: "Please enter correct register information.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = view.width/3
        imageView.frame = CGRect(x: (view.width - size) / 2, y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        
        firstNameField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        
        lastNameField.frame = CGRect(x: 30, y: firstNameField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        emailField.frame = CGRect(x: 30, y: lastNameField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        
        registerButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
    }
    
}

extension RegisterViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case firstNameField:
            lastNameField.becomeFirstResponder()
        case lastNameField:
            emailField.becomeFirstResponder()
        case emailField:
            passwordField.becomeFirstResponder()
        default:
            registerButtonTapped()
        }
        return true
    }
}

//picking an image
extension RegisterViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self] _ in
            self?.presentPhotoPicker()
        }))
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        self.imageView.image = image
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
