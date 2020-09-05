//
//  ViewController.swift
//  Carousel_Practice
//
//  Created by Alnodi Adnan on 11/05/20.
//  Copyright © 2020 Alnodi Adnan. All rights reserved.
//

import UIKit
import Firebase

class Reply: NSObject {
    var jawaban: String?
    var senderUID: String?
    var sender: String?
    var vote: Int?
    var voteTrue: Bool = false
    var profileURL: String?
}

class TopicVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CardCollectionViewCellDelegate {
    
    var pertanyaan: String?
    var pengirim: String?
    var subject: String?
    var topicUID: String?
    var senderUID: String?
    var topicSenderImg: UIImage?
    var replies = [Reply]()
    var rawReplies = [Reply]()
    var selectedSort: String?
    var selectedProfileUID: String?

    @IBOutlet weak var lblQuestion: UILabel!
    @IBOutlet weak var cardView: UICollectionView!
    @IBOutlet weak var lblSender: UILabel!
    @IBOutlet weak var imgSender: UIImageView!
    @IBOutlet weak var imgEmpty: UIImageView!
    @IBOutlet weak var sortBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSubject()
        cardView.delegate = self
        cardView.dataSource = self
        
        checkSortButtonEligibility()
        configureCell()
        fetchData()
        
        title = "Topik Diskusi"
        imgSender.image = topicSenderImg
        lblQuestion.text = pertanyaan
        lblSender.text = pengirim
        
    }
    
    func fetchData(){
        let refs = Database.database().reference().child("topic")
        refs.child(subject!).queryOrdered(byChild: "topic").queryEqual(toValue: pertanyaan!).observeSingleEvent(of: .value, with: {(snapshot) in
        
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                self.topicUID = rest.key
                Database.database().reference().child("topic").child(self.subject!).child(rest.key).child("replies").observe(.childAdded) { (snapshot) in
                    
                    if let dictionary = snapshot.value as? [String: AnyObject]{
                        let post = Reply()
                        
                        post.jawaban = dictionary["jawaban"] as? String
                        post.senderUID = dictionary["senderUID"] as? String
                        post.vote = dictionary["vote"] as? Int
                        
                        self.loadVoters(jawaban: post.jawaban!, post: post)

                        let senderUID = dictionary["senderUID"] as? String
                        
                        //LOAD SENDER DATA FROM UID
                        Database.database().reference().child("users").child(senderUID!).observeSingleEvent(of: .value) { (snapshot) in
                            if let dictionary = snapshot.value as? [String: AnyObject]{
                                post.sender = dictionary["fullname"] as? String
                                post.profileURL = dictionary["profileImgURL"] as? String
                                
                                self.replies.insert(post, at: 0)
                                self.rawReplies.insert(post, at: 0)
                                print(post)
                                self.checkSortButtonEligibility()
                                
                                DispatchQueue.main.async {
                                    self.cardView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func configureCell() {
        //Configure konten dalam cell collection view
        cardView.register(UINib.init(nibName: "CardCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cardIdentifier")
        
        let flowLayout = UPCarouselFlowLayout()
        flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width - 60.0, height: cardView.frame.size.height)
        flowLayout.scrollDirection = .horizontal
        flowLayout.sideItemScale = 0.8
        flowLayout.sideItemAlpha = 0.7
        flowLayout.spacingMode = .fixed(spacing: -10.0)
        cardView.collectionViewLayout = flowLayout
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "answerSegue") {
            let dest = segue.destination as! AnswerVC
            dest.pertanyaan = pertanyaan
            dest.pengirim = pengirim
            dest.subject = subject
        }
        else if (segue.identifier == "popUpTopicSegue") {
            let dest = segue.destination as! PopUpProfileVC
            dest.loadSenderUID = selectedProfileUID
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return (jumlah jawaban dalam 1 pertanyaan)
        return replies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cardIdentifier", for: indexPath) as! CardCollectionViewCell
        let reply = replies[indexPath.row]
        
//        loadVoters(jawaban: reply.jawaban!, idx: indexPath.row)
        cell.delegate = self
        cell.indexPath = indexPath.row
        cell.upVote = 1
        
        cell.cardAnswer.text = reply.jawaban
        cell.senderNameLabel.text = reply.sender
        cell.lblVote.text = "\(reply.vote!)"
        if reply.voteTrue == true {
            cell.btnUpOutlet.tintColor = #colorLiteral(red: 0.1254901961, green: 0.4862745098, blue: 0.8431372549, alpha: 1)
        }
        else if reply.voteTrue == false {
            cell.btnUpOutlet.tintColor = #colorLiteral(red: 0.6823529412, green: 0.6823529412, blue: 0.6980392157, alpha: 1)
        }
        
        if let profileImageURL = reply.profileURL {
            let url = URL(string: profileImageURL)
            URLSession.shared.dataTask(with: url!) { (data, response, error) in
                
                if error != nil {
                    print("error")
                    return
                }
                DispatchQueue.main.async {
                    cell.senderImage.image = UIImage(data: data!)
                }
            }.resume()
        }

        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("card selected : \(indexPath.row)")
    }
    
    func btnUpTapped(vote: Int, index: Int) {
        let indexPath = NSIndexPath(row: index, section: 0)
        let cell = self.cardView.cellForItem(at: indexPath as IndexPath) as! CardCollectionViewCell
        
        if Auth.auth().currentUser != nil {
            if cell.btnUpOutlet.tintColor != #colorLiteral(red: 0.1254901961, green: 0.4862745098, blue: 0.8431372549, alpha: 1) {
                likeTapped(repIndex: index)
            }
            else {
                unLikeTapped(repIndex: index)
            }
        }
    }
    func btnProfileTapped(index: Int) {
        selectedProfileUID = replies[index].senderUID
        performSegue(withIdentifier: "popUpTopicSegue", sender: self)
    }
    @IBAction func btnProfileTopicTapped(_ sender: Any) {
        selectedProfileUID = senderUID
        performSegue(withIdentifier: "popUpTopicSegue", sender: self)
    }
    
    func likeTapped(repIndex: Int){
        var voteCount = 0
        let refs = Database.database().reference().child("topic").child(self.subject!).child(topicUID!).child("replies")
        refs.queryOrdered(byChild: "jawaban").queryEqual(toValue: replies[repIndex].jawaban).observeSingleEvent(of: .value, with: {(snapshot) in
        
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).observeSingleEvent(of: .value) { (snapshot) in
                    
                    if let dictionary = snapshot.value as? [String: AnyObject]{
                        voteCount = (dictionary["vote"] as? Int)!
                        
                        //SAVE LIKE TO DATABASE
                        let ref = Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key)
                        let values = ["vote": voteCount+1]
                        ref.updateChildValues(values)
                        
                        //SAVE WHOSE VOTING
                        let voterUID = Auth.auth().currentUser?.uid
                        let ref2 = Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).child("votedBy").childByAutoId()
                        let value = ["voterUID": voterUID!] as [String : Any]
                        ref2.updateChildValues(value)
                        
                        //SAVE LIKE KE YG NGIRIM JAWABAN
                        self.updateUserLike(repIndex: repIndex)
                        
                        let indexPath = NSIndexPath(row: repIndex, section: 0)
                        let cell = self.cardView.cellForItem(at: indexPath as IndexPath) as! CardCollectionViewCell
                        cell.lblVote.text = "\(voteCount+1)"
                        cell.btnUpOutlet.tintColor = #colorLiteral(red: 0.1254901961, green: 0.4862745098, blue: 0.8431372549, alpha: 1)
                        
                        self.replies[repIndex].voteTrue = true
                        self.replies[repIndex].vote = voteCount+1
                    }
                }
            }
        })
    }
    func updateUserLike(repIndex: Int) {
        Database.database().reference().child("users").child(replies[repIndex].senderUID!).observeSingleEvent(of: .value) { (snapshot) in
        
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let userVote = dictionary["vote"] as? Int
                
                //SAVE USER VOTE DATA TO DATABASE
                let refPost = Database.database().reference().child("users").child(self.replies[repIndex].senderUID!)
                
                let values = ["vote": userVote!+1]
                refPost.updateChildValues(values)
            }
        }
    }
    func unLikeTapped(repIndex: Int) {
        var voteCount: Int?
        let refs = Database.database().reference().child("topic").child(self.subject!).child(topicUID!).child("replies")
        refs.queryOrdered(byChild: "jawaban").queryEqual(toValue: replies[repIndex].jawaban).observeSingleEvent(of: .value, with: {(snapshot) in
        
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).observeSingleEvent(of: .value) { (snapshot) in
                    
                    if let dictionary = snapshot.value as? [String: AnyObject]{
                        voteCount = (dictionary["vote"] as? Int)!
                        
                        //SAVE UNLIKE TO DATABASE
                        let ref = Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key)
                        let values = ["vote": voteCount!-1]
                        ref.updateChildValues(values)
                        
                        //REMOVE LIKE KE YG NGIRIM JAWABAN
                        self.updateUserUnlike(repIndex: repIndex)
                        
                        //REMOVE VOTER
                        let refs = Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies")
                        refs.queryOrdered(byChild: "jawaban").queryEqual(toValue: self.replies[repIndex].jawaban).observeSingleEvent(of: .value, with: {(snapshot) in
                        
                            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                                Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).observeSingleEvent(of: .value) { (snapshot) in
                                    
                                    let refs2 = Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).child("votedBy")
                                    refs2.queryOrdered(byChild: "voterUID").queryEqual(toValue: Auth.auth().currentUser?.uid).observeSingleEvent(of: .value, with: {(snapshot) in
                                    
                                        for rest2 in snapshot.children.allObjects as! [DataSnapshot] {
                                            Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).child("votedBy").child(rest2.key).observeSingleEvent(of: .value) { (snapshot) in
                                                
                                                let refDelete = Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).child("votedBy").child(rest2.key).child("voterUID")
                                                
                                                refDelete.removeValue()
                                            }
                                        }
                                    })
                                }
                            }
                        })
                        
                        let indexPath = NSIndexPath(row: repIndex, section: 0)
                        let cell = self.cardView.cellForItem(at: indexPath as IndexPath) as! CardCollectionViewCell
                        cell.lblVote.text = "\(voteCount!-1)"
                        cell.btnUpOutlet.tintColor = #colorLiteral(red: 0.6823529412, green: 0.6823529412, blue: 0.6980392157, alpha: 1)
                        
                        self.replies[repIndex].voteTrue = false
                        self.replies[repIndex].vote = voteCount!-1
                    }
                }
            }
        })
    }
    func updateUserUnlike(repIndex: Int) {
        Database.database().reference().child("users").child(replies[repIndex].senderUID!).observeSingleEvent(of: .value) { (snapshot) in
        
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let userVote = dictionary["vote"] as? Int
                
                //SAVE USER VOTE DATA TO DATABASE
                let refPost = Database.database().reference().child("users").child(self.replies[repIndex].senderUID!)
                
                let values = ["vote": userVote!-1]
                refPost.updateChildValues(values)
            }
        }
    }
    
    func loadVoters(jawaban: String, post: Reply){
        let refs = Database.database().reference().child("topic").child(self.subject!).child(topicUID!).child("replies")
        refs.queryOrdered(byChild: "jawaban").queryEqual(toValue: jawaban).observeSingleEvent(of: .value, with: {(snapshot) in
        
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).observeSingleEvent(of: .value) { (snapshot) in
                    
                    let refs2 = Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).child("votedBy")
                    refs2.queryOrdered(byChild: "voterUID").queryEqual(toValue: Auth.auth().currentUser?.uid).observeSingleEvent(of: .value, with: {(snapshot) in
                    
                        for rest2 in snapshot.children.allObjects as! [DataSnapshot] {
                            Database.database().reference().child("topic").child(self.subject!).child(self.topicUID!).child("replies").child(rest.key).child("votedBy").child(rest2.key).observeSingleEvent(of: .value) { (snapshot) in
                                
                                if let dictionary = snapshot.value as? [String: AnyObject]{
                                    print(dictionary)
                                    
                                    post.voteTrue = true
                                }
                                else {
                                    post.voteTrue = false
                                }
                            }
                        }
                    })
                }
            }
        })
    }
    
    
    @IBAction func btnJawabTapped(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            self.presentSignInScreen()
        }
        else {
            performSegue(withIdentifier: "answerSegue", sender: self)
        }
    }
    
    func presentSignInScreen(){
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signInVC = storyboard.instantiateViewController(withIdentifier: "loginScreen")
        signInVC.modalPresentationStyle = .fullScreen
        self.present(signInVC, animated: true, completion: nil)
    }
    
    func loadSubject() {
        if subject == "IPA" {
            subject = "Ilmu Pengetahuan Alam"
        }
        else if subject == "IPS" {
            subject = "Ilmu Pengetahuan Sosial"
        }
        else if subject == "PKN" {
            subject = "Pendidikan Kewarganegaraan"
        }
        else {
            subject = subject?.capitalized
        }
    }
    
    //MARK: Sorting Answer
    
    @IBAction func sortBtn_Action(_ sender: UIButton) {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let dateAdded = UIAlertAction(title: "Default (Terbaru)", style: .default) { (action) in
            // implement code
            self.selectedSort = "dateAdded"
            
            self.replies = self.rawReplies
            
            self.cardView.reloadData()
        }
        
        let voteCount = UIAlertAction(title: "Jumlah Vote", style: .default) { (action) in
            // implement code
            self.selectedSort = "voteCount"
            
            self.replies.sort(by: { $0.vote! > $1.vote! })
//            self.trendings.sort(by: { $0.reply > $1.reply })
            
            self.cardView.reloadData()
        }
        
        
        switch selectedSort {
        case "dateAdded":
            dateAdded.setValue(true, forKey: "checked")
        case "voteCount":
            voteCount.setValue(true, forKey: "checked")
        default:
            dateAdded.setValue(true, forKey: "checked")
        }
        
        actionSheet.addAction(dateAdded)
        actionSheet.addAction(voteCount)
        actionSheet.addAction(cancel)
        
        present(actionSheet, animated: true, completion: nil)
        
        // silence the constraint alert warnings. possible bug in iOS(?)
        actionSheet.view.subviews.flatMap({$0.constraints}).filter{ (one: NSLayoutConstraint) -> (Bool)  in
           return (one.constant < 0) && (one.secondItem == nil) && (one.firstAttribute == .width)
        }.first?.isActive = false
        checkSortButtonEligibility()
    }
    
    func checkSortButtonEligibility(){
        if replies.isEmpty {
            sortBtn.isEnabled = false
        }
        else {
            sortBtn.isEnabled = true
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.replies.count > 0 {
                self.imgEmpty.isHidden = true
            }
            else {
                self.imgEmpty.isHidden = false
            }
        }
    }
    
}

