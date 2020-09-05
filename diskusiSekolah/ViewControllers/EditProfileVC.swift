//
//  EditProfileVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 15/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class EditProfileVC: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtBio: UITextField!
    
    var username: String?
    var bio: String?
    var passImg: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setImg()
        txtUsername.text = username!
        txtBio.text = bio!
    }
    
    func setImg() {
        imgProfile.layer.cornerRadius = imgProfile.frame.size.width/2
        imgProfile.clipsToBounds=true
        imgProfile.layer.shadowRadius=10
        imgProfile.layer.shadowColor=UIColor.black.cgColor
        imgProfile.layer.shadowOffset=CGSize.zero
        imgProfile.layer.shadowOpacity=1
        imgProfile.layer.shadowPath = UIBezierPath(rect: imgProfile.bounds).cgPath
        
        imgProfile.image = passImg!
    }
    

    @IBAction func btnBataltapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSimpanTapped(_ sender: Any) {
        if (txtUsername.text == "") {
            createAlert(message: "Kolom nama tidak boleh kosong.")
        }
        else if imgProfile.image != passImg {
            showSpinner()
            
            //FETCH OLD IMAGE TO BE DELETED
            let uid = Auth.auth().currentUser?.uid
            var oldImgName: String?
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    oldImgName = dictionary["profileImgName"] as? String
                    
                    let delRef = Storage.storage().reference().child(oldImgName!)
                    delRef.delete { (error) in
                        if error != nil {
                            print("error")
                            return
                        }
                        else {
                            print("delete complete.")
                        }
                    }
                }
            }
            //UPLOADING NEW PROFILE IMAGE
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
                            let uid = (Auth.auth().currentUser?.uid)!
                            let refPost = Database.database().reference().child("users").child(uid)
                            
                            let values = ["fullname": self.txtUsername.text!, "bio": self.txtBio.text!, "profileImgURL": url!.absoluteString, "profileImgName": imageName + ".png"]
                            refPost.updateChildValues(values)
                            
                            self.removeSpinner()
                            self.performSegue(withIdentifier: "unwindProfile", sender: self)
                            print("Upload complete.")
                        }
                    })
                }
            }
        }
        else {
            let uid = (Auth.auth().currentUser?.uid)!
            let refPost = Database.database().reference().child("users").child(uid)
            
            let values = ["fullname": txtUsername.text!, "bio": txtBio.text!]
            refPost.updateChildValues(values)
            
            self.performSegue(withIdentifier: "unwindProfile", sender: self)
        }
    }
    
    @IBAction func btnEditTapped(_ sender: Any) {
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
    
    func createAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
}
