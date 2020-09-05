//
//  AnswerVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 18/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class AnswerVC: UIViewController, UITextViewDelegate {
    
    var pertanyaan: String?
    var pengirim: String?
    var subject: String?
    var topicUid: String?
    var userReply: Int?
    var topicReplyCount: Int?

    @IBOutlet weak var lblQuestion: UILabel!
    @IBOutlet weak var lblSender: UILabel!
    @IBOutlet weak var txtAnswer: UITextView!
    @IBOutlet weak var lblAnswerSender: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadAnswerVC()
        getTopicUID()
    }
    
    func loadAnswerVC() {
        lblQuestion.text = pertanyaan
        lblSender.text = pengirim
        
        txtAnswer.text = "ketik jawaban kamu disini"
        txtAnswer.textColor = #colorLiteral(red: 0.4941176471, green: 0.4941176471, blue: 0.4980392157, alpha: 1)
        
        //LOAD USERNAME
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.lblAnswerSender.text = dictionary["fullname"] as? String
            }
        }
    }
    
    func getTopicUID(){
        let refs = Database.database().reference().child("topic")
        refs.child(subject!).queryOrdered(byChild: "topic").queryEqual(toValue: pertanyaan!).observeSingleEvent(of: .value, with: {(snapshot) in
        
            for rest in snapshot.children.allObjects as! [DataSnapshot] {
                self.topicUid = rest.key
            }
        })
    }
    
    func updateUserReply() {
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
        
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.userReply = dictionary["rep"] as? Int
                
                //SAVE USER POST DATA TO DATABASE
                let uid = (Auth.auth().currentUser?.uid)!
                let refPost = Database.database().reference().child("users").child(uid)
                
                let values = ["rep": self.userReply!+1]
                refPost.updateChildValues(values)
            }
        }
    }
    func updateReplyCount() {
        Database.database().reference().child("topic").child(subject!).child(topicUid!).observeSingleEvent(of: .value) { (snapshot) in
        
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.topicReplyCount = dictionary["reply"] as? Int
                
                //SAVE TOTAL REPLY TO DATABASE
                let ref = Database.database().reference().child("topic").child(self.subject!).child(self.topicUid!)
                
                let values = ["reply": self.topicReplyCount!+1]
                ref.updateChildValues(values)
            }
        }
    }
    
    //SETUP TEXT FIELD
    func textViewDidBeginEditing(_ textView: UITextView) {
        if txtAnswer.text == "ketik jawaban kamu disini" {
            txtAnswer.text = nil
            txtAnswer.textColor = UIColor.black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if txtAnswer.text.isEmpty {
            txtAnswer.text = "ketik jawaban kamu disini"
            txtAnswer.textColor = UIColor.lightGray
        }
    }

    @IBAction func btnBatalTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnKirimTapped(_ sender: Any) {
        if txtAnswer.text == "ketik jawaban kamu disini" || txtAnswer.text == nil {
            createAlert(message: "Kamu belum mengisi jawaban yang akan dikirimkan.")
        }
        else {
            let senderUid = Auth.auth().currentUser?.uid
            
            let ref = Database.database().reference().child("topic").child(subject!).child(topicUid!).child("replies").childByAutoId()
            let value = ["jawaban": txtAnswer.text!, "senderUID": senderUid!, "timestamp": [".sv":"timestamp"], "vote": 0] as [String : Any]
            
            ref.updateChildValues(value)
            updateUserReply()
            updateReplyCount()
            
            createAlertDone(title: "Jawaban berhasil dikirim", message: "Jawaban kamu sudah masuk ke balasan topik ini!") { (action) in
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func createAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    func createAlertDone(title: String, message: String, handlerOK: ((UIAlertAction) -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: handlerOK)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}
