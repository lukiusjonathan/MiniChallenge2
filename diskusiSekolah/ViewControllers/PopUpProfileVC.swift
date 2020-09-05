//
//  PopUpProfileVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 26/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class PopUpProfileVC: UIViewController {

    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblBio: UILabel!
    @IBOutlet weak var lblPost: UILabel!
    @IBOutlet weak var lblVote: UILabel!
    @IBOutlet weak var lblRep: UILabel!
    @IBOutlet var outerView: UIView!
    
    var loadSenderUID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOuterTap()
        setupImageView()
        loadProfile()
    }
    
    func loadProfile() {
        Database.database().reference().child("users").child(loadSenderUID!).observeSingleEvent(of: .value) { (snapshot) in
        
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.lblUsername.text = dictionary["fullname"] as? String
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
    
    func setupImageView() {
        imgProfile.layer.cornerRadius = imgProfile.frame.size.width/2
        imgProfile.clipsToBounds=true
        imgProfile.layer.shadowRadius=10
        imgProfile.layer.shadowColor=UIColor.black.cgColor
        imgProfile.layer.shadowOffset=CGSize.zero
        imgProfile.layer.shadowOpacity=1
        imgProfile.layer.shadowPath = UIBezierPath(rect: imgProfile.bounds).cgPath
        
        imgProfile.layer.borderColor = #colorLiteral(red: 0.2039215686, green: 0.4941176471, blue: 1, alpha: 1)
        imgProfile.layer.borderWidth = 3
    }
    
    @IBAction func btnTutupTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupOuterTap(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleOuterTap(_:)))
        outerView.addGestureRecognizer(tap)
        outerView.isUserInteractionEnabled = true
    }
    
    @objc func handleOuterTap(_ sender: UITapGestureRecognizer? = nil) {
        //Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }

}
