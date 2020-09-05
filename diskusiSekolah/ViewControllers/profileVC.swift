//
//  homeVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 05/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class profileVC: UIViewController {


    @IBOutlet weak var lblDisplayName: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var lblPost: UILabel!
    @IBOutlet weak var lblVote: UILabel!
    @IBOutlet weak var lblRep: UILabel!
    @IBOutlet weak var lblBio: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setImgandBtn()
        loadProfile()
    }
    
    func loadProfile() {
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
        
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.lblDisplayName.text = dictionary["fullname"] as? String
                self.lblBio.text = dictionary["bio"] as? String
                self.lblPost.text =  "\(dictionary["post"] as! Int)"
                self.lblVote.text = "\(dictionary["vote"] as! Int)"
                self.lblRep.text = "\(dictionary["rep"] as! Int)"
                
                if let profileImageURL = dictionary["profileImgURL"] as? String {
                    let url = URL(string: profileImageURL)
                    URLSession.shared.dataTask(with: url!) { (data, response, error) in
                        
                        if error != nil {
                            print("error")
                            return
                        }
                        DispatchQueue.main.async {
                            self.imgProfile.image = UIImage(data: data!)
                        }
                    }.resume()
                }
            }
        }
    }
    
    func setImgandBtn() {
        imgProfile.layer.cornerRadius = imgProfile.frame.size.width/2
        imgProfile.clipsToBounds=true
//        imgProfile.layer.shadowRadius=10
//        imgProfile.layer.shadowColor=UIColor.black.cgColor
//        imgProfile.layer.shadowOffset=CGSize.zero
//        imgProfile.layer.shadowOpacity=1
        imgProfile.layer.shadowPath = UIBezierPath(rect: imgProfile.bounds).cgPath
        
        btnEdit.layer.cornerRadius = 10
        btnEdit.layer.masksToBounds=true
        btnEdit.layer.borderColor = #colorLiteral(red: 0.2039215686, green: 0.4941176471, blue: 1, alpha: 1)
        btnEdit.layer.borderWidth = 1.5
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editSegue") {
            let dest = segue.destination as! EditProfileVC
            dest.username = lblDisplayName.text
            dest.bio = lblBio.text
            dest.passImg = imgProfile.image
        }
    }
    
    @IBAction func unwindFromEdit (_ sender: UIStoryboardSegue) {
        guard let editProfileVC = sender.source as? EditProfileVC else { return }
        lblDisplayName.text = editProfileVC.txtUsername.text
        lblBio.text = editProfileVC.txtBio.text
        imgProfile.image = editProfileVC.imgProfile.image
    }

    @IBAction func btnEditTapped(_ sender: Any) {
        performSegue(withIdentifier: "editSegue", sender: self)
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        showAlert(title: "Log Out", message: "Are you sure want to log out?", handlerLogout: { (action) in
            do{
                try Auth.auth().signOut()
            } catch{
                print("Error Logout")
            }
            
            self.performSegue(withIdentifier: "unwindLogout", sender: self)
        }, handlerCancel: { (action) in
            return
        })
    }
    
    func showAlert(title: String, message: String, handlerLogout: ((UIAlertAction) -> Void)?, handlerCancel: ((UIAlertAction) -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Cancel", style: .default, handler: handlerCancel)
        let actionLogout = UIAlertAction(title: "LogOut", style: .destructive, handler: handlerLogout)
        alert.addAction(action)
        alert.addAction(actionLogout)
        self.present(alert, animated: true, completion: nil)
    }
}
