//
//  subjectVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 12/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class Topic: NSObject {
    var topic: String?
    var senderUID: String?
    var reply: Int?
    var sender: String?
    var profileURL: String?
}

class subjectVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, TopicCollVCellDelegate {
    
    @IBOutlet weak var imgEmpty: UIImageView!
    
    let subject:[String] = ["Agama", "Bahasa Indonesia", "Bahasa Inggris", "Bahasa Mandarin", "Ilmu Pengetahuan Alam", "Ilmu Pengetahuan Sosial", "Komputer", "Matematika", "Olahraga", "Pendidikan Kewarganegaraan", "Seni Budaya"]
    var loadSubject = 0
    var topics = [Topic]()
    
    var selectedTopic: String?
    var selectedSender: String?
    var selectedSenderImg: UIImage?
    var selectedProfileUID: String?
    var selectedSenderUID: String?
    
    var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.size.width
        layout.estimatedItemSize = CGSize(width: width, height: 10)
        return layout
    }()

    @IBOutlet weak var topicCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPlusBtn()
        loadSubjectView()
        fetchData()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        topicCollectionView.register(topicCollVCell.self, forCellWithReuseIdentifier: "topicCollVCell")
        topicCollectionView.collectionViewLayout = layout
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.topics.count > 0 {
                self.imgEmpty.isHidden = true
            }
            else {
                self.imgEmpty.isHidden = false
            }
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topicCell", for: indexPath) as! topicCollVCell
        
        let post = topics[indexPath.item]
        
        cell.delegate = self
        cell.indexPath = indexPath.row
        
        cell.lblTopic.text = post.topic
        cell.lblSender.text = post.sender
        if let profileImageURL = post.profileURL {
            let url = URL(string: profileImageURL)
            URLSession.shared.dataTask(with: url!) { (data, response, error) in
                
                if error != nil {
                    print("error")
                    return
                }
                DispatchQueue.main.async {
                    cell.imgSender.image = UIImage(data: data!)
                }
            }.resume()
        }
        
//        cell.frame.size.height = cell.lblTopic.frame.size.height + 40
//        cell.lblTopic.sizeToFit()
//        cell.lblTopic.numberOfLines = 0
        
        //topicLabelHeight = heightForLabel(text: post.topic!, width: 150.0)
        return cell
    }
    
    
    
    func btnProfileTapped(index: Int) {
        selectedProfileUID = topics[index].senderUID
        performSegue(withIdentifier: "popUpSegue", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentCell = collectionView.cellForItem(at: indexPath) as! topicCollVCell
        
        let post = topics[indexPath.item]
//        let sender = currentCell.lblSender.text!.components(separatedBy: " ")
        
        selectedTopic = post.topic
        selectedSender = currentCell.lblSender.text!
        selectedSenderImg = currentCell.imgSender.image
        selectedSenderUID = post.senderUID
        
        performSegue(withIdentifier: "topicSegue", sender: self)
    }
    
    func loadSubjectView() {
        if subject[loadSubject] == "Ilmu Pengetahuan Alam" {
            self.title = "IPA"
        }
        else if subject[loadSubject] == "Ilmu Pengetahuan Sosial" {
            self.title = "IPS"
        }
        else if subject[loadSubject] == "Pendidikan Kewarganegaraan" {
            self.title = "PKn"
        }
        else {
            self.title = subject[loadSubject]
        }
    }
    
    //FECTH DATA FROM DATABASE TO SELECTED SUBJECT
    func fetchData() {
        Database.database().reference().child("topic").child(subject[loadSubject]).observe(.childAdded) { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let post = Topic()
                
                post.topic = dictionary["topic"] as? String
                post.reply = dictionary["reply"] as? Int
                post.senderUID = dictionary["senderUID"] as? String
                let senderUID = dictionary["senderUID"] as? String
                
                //LOAD SENDER DATA FROM UID
                Database.database().reference().child("users").child(senderUID!).observeSingleEvent(of: .value) { (snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject]{
                        post.sender = dictionary["fullname"] as? String
                        post.profileURL = dictionary["profileImgURL"] as? String
                        
                        self.topics.insert(post, at: 0)
                        
                        
                            if self.topics.count > 0 {
                                self.imgEmpty.isHidden = true
                            }
                            else {
                                self.imgEmpty.isHidden = false
                            }
                        
                        
                        DispatchQueue.main.async {
                            self.topicCollectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func addPlusBtn() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBtnTap))
        self.navigationItem.rightBarButtonItem = addButton
    }
    @objc func addBtnTap(){
        if Auth.auth().currentUser == nil{
            self.presentSignInScreen()
        }
        else {
            performSegue(withIdentifier: "newTopicSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "newTopicSegue") {
            let dest = segue.destination as! newTopicVC
            dest.loadSubject = loadSubject
        }
        else if (segue.identifier == "topicSegue") {
            let dest = segue.destination as! TopicVC
            dest.pertanyaan = selectedTopic
            dest.pengirim = selectedSender
            dest.subject = subject[loadSubject]
            dest.topicSenderImg = selectedSenderImg
            dest.senderUID = selectedSenderUID
        }
        else if (segue.identifier == "popUpSegue") {
            let dest = segue.destination as! PopUpProfileVC
            dest.loadSenderUID = selectedProfileUID
        }
    }
    
    func presentSignInScreen(){
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signInVC = storyboard.instantiateViewController(withIdentifier: "loginScreen")
        signInVC.modalPresentationStyle = .fullScreen
        self.present(signInVC, animated: true, completion: nil)
    }


}

extension subjectVC : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
         let post = topics[indexPath.item]
        
        let size = CGSize(width: view.frame.width - 12 - 50, height: 1000)
        let attribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
        
        let estimatedFrame = NSString(string: post.topic!).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attribute, context: nil)
        
//        print("Height: \(estimatedFrame.height + 200)")
        return CGSize(width: view.frame.width - 50, height: (estimatedFrame.height + 150))
    }
    
}

extension subjectVC {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        layout.estimatedItemSize = CGSize(width: view.bounds.size.width, height: 10)
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        layout.estimatedItemSize = CGSize(width: view.bounds.size.width, height: 10)
        layout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    
}
