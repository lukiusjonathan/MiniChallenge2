//
//  registerVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 05/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class registerVC: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var fullnameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var conPasswordField: UITextField!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var roleField: UITextField!
    
    var role = ["Siswa", "Guru"]
    var selectedRole: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hideKeyboardWhenTappedAround()
        createPickerView()
        dismissPickerView()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    @IBAction func registerTapped(_ sender: Any) {
        if (emailField.text == "" || passwordField.text == "" || fullnameField.text == "" || conPasswordField.text == "" || roleField.text == ""){
            //error input register data
            print("please input data")
            createAlert(message: "Tolong isi semua data yang diperlukan")
        }
        else if passwordField.text != conPasswordField.text {
            createAlert(message: "Konfirmasi kata sandi tidak sama dengan kata sandi")
        }
        else {
            let email = emailField.text
            let password = passwordField.text
            let fullname = fullnameField.text
            let roles = roleField.text
            
            Auth.auth().createUser(withEmail: email!, password: password!) { (user, error) in
                //CHECK ERROR FIREBASE
                if let firebaseError = error {
                    print(firebaseError.localizedDescription)
                    self.createAlert(message: firebaseError.localizedDescription)
                    
                    return
                }
                self.showSpinner()
                
                //SAVE PROFILE IMAGE TO DATABASE
                let imageName = NSUUID().uuidString
                let storageRef = Storage.storage().reference().child(imageName + ".png")
                if let uploadData = self.imgProfile.image!.pngData() {
                    storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        
                        storageRef.downloadURL(completion: { (url, error) in
                            if error != nil {
                                print("error")
                                return
                            }
                            else {
                                //SAVE USER DATA TO DATABASE
                                let ref = Database.database().reference(fromURL: "https://mc2-diskusisekolah.firebaseio.com/")
                                let uid = user!.user.uid
                                let usersRef = ref.child("users").child(uid)
                                
                                let values = ["fullname": fullname!, "bio": "isi bio semaumu di ubah profil", "email": email!, "password": password!, "post": 0, "vote": 0, "rep": 0, "profileImgURL": url!.absoluteString, "profileImgName": imageName + ".png", "role": roles!] as [String : Any]
                                usersRef.updateChildValues(values as [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                                    
                                    if err != nil {
                                        print(err!)
                                        return
                                    }
                                    
                                    print("Saved to database")
                                })
                                
                                self.removeSpinner()
                                print("User Created Success")
                                self.presentLoggedInScreen()
                            }
                        })
                    }
                }
            }
        }
    }

    //GENERATING IMAGE PICKER FOR PROFILE
    @IBAction func btnSelectImgTapped(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        let actionSheet = UIAlertController(title: "Piih Foto Profil", message: "Ambil dari photo library atau ambil menggunakan camera.", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImage: UIImage?
        
        if let editedImg = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImage = editedImg
        }
        else if let originalImg = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImage = originalImg
        }
        
        if let selectedImg = selectedImage {
            let selectedImgProfile = resizeImage(image: selectedImg, targetSize: CGSize(width: 250, height: 250))
            imgProfile.image = selectedImgProfile
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //CREATING PICKERVIEW ROLE
        func createPickerView(){
            let pickerView = UIPickerView();
            pickerView.delegate = self;
            
            roleField.inputView = pickerView;
        }
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return role.count
        }
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return role[row];
        }
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            selectedRole = role[row];
            roleField.text = selectedRole;
        }
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1;
        }
    //ADD DONE BUTTON TO PICKERVIEW
        func dismissPickerView(){
            let toolbar = UIToolbar();
            toolbar.sizeToFit();
            
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
            
            let doneBtn = UIBarButtonItem(title: "Selesai", style: .plain, target: self, action: #selector(self.dissmissKeyboard))
            toolbar.setItems([flexibleSpace, doneBtn], animated: false);
            toolbar.isUserInteractionEnabled = true;
            
            roleField.inputAccessoryView = toolbar;
        }
        @objc func dissmissKeyboard(){
            selectedRole = role[0]
            roleField.text = selectedRole
            view.endEditing(true);
        }
    
    //SEGUE LOGIN
    func presentLoggedInScreen(){
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let loggedInVC = storyboard.instantiateViewController(withIdentifier: "homeScreen")
        loggedInVC.modalPresentationStyle = .fullScreen
        self.present(loggedInVC, animated: true, completion: nil)
    }
    
    func createAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
}
