//
//  newTopicVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 12/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class newTopicVC: UIViewController, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var txtSubject: UITextField!
    @IBOutlet weak var txtTopic: UITextView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var skeletonView: UIView!
    @IBOutlet weak var skeletonView2: UIView!
    @IBOutlet weak var skeletonView3: UIView!
    
    var loadSubject: Int?
    var subject:[String] = ["Agama", "Bahasa Indonesia", "Bahasa Inggris", "Bahasa Mandarin", "Ilmu Pengetahuan Alam", "Ilmu Pengetahuan Sosial", "Komputer", "Matematika", "Olahraga", "Pendidikan Kewarganegaraan", "Seni Budaya"]
    var selectedSubject: String?
    var username: String?
    var userpost: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtSubject.text = subject[loadSubject!]
        
        createPickerView()
        dismissPickerView()
        loadVC()
    }

    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        if txtTopic.text == "topik baru kamu" || txtTopic.text == nil {
            createAlert(message: "Kamu belum mengisi topik yang akan dikirimkan.")
        }
        else {
            let uid = Auth.auth().currentUser?.uid
            let ref = Database.database().reference().child("topic").child(txtSubject.text!).childByAutoId()
            let value = ["topic": txtTopic.text!, "senderUID": uid!, "timestamp": [".sv":"timestamp"], "reply": 0] as [String : Any]
            
            ref.updateChildValues(value)
            
            updateUserPost()
            updateNewestPost()
            
            createAlertDone(title: "Topik berhasil dikirim", message: "Topik baru kamu sudah masuk ke topik diskusi!") { (action) in
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    func loadVC() {
        txtTopic.text = "topik baru kamu"
        txtTopic.textColor = #colorLiteral(red: 0.4941176471, green: 0.4941176471, blue: 0.4980392157, alpha: 1)
        
        //RECREATE SUBJECT LIST BASED ON SELECTED
        let selectedSubject = subject[loadSubject!]
        subject.remove(at: loadSubject!)
        subject.insert(selectedSubject, at: 0)
        
        //LOAD USERNAME
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.username = dictionary["fullname"] as? String
                self.lblName.text = self.username
                self.skeletonView.isHidden = true
                self.skeletonView2.isHidden = true
                self.skeletonView3.isHidden = true
            }
        }
    }
    
    func updateUserPost() {
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
        
            if let dictionary = snapshot.value as? [String: AnyObject]{
                self.userpost = dictionary["post"] as? Int
                
                //SAVE USER POST DATA TO DATABASE
                let uid = (Auth.auth().currentUser?.uid)!
                let refPost = Database.database().reference().child("users").child(uid)
                
                let values = ["post": self.userpost!+1]
                refPost.updateChildValues(values)
            }
        }
    }
    func updateNewestPost() {
        let uid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("newest").child(txtSubject.text!)
                
        let values = ["topic": self.txtTopic.text!, "senderUID": uid!, "subject": self.txtSubject.text!, "timestamp": [".sv":"timestamp"]] as [String : Any]
        ref.updateChildValues(values)
    }
    
//CREATING PICKERVIEW SUBJECT
    func createPickerView(){
        let pickerView = UIPickerView();
        pickerView.delegate = self;
        
        txtSubject.inputView = pickerView;
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return subject.count;
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return subject[row];
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedSubject = subject[row];
        txtSubject.text = selectedSubject;
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
//ADD DONE BUTTON TO PICKERVIEW
    func dismissPickerView(){
        let toolbar = UIToolbar();
        toolbar.sizeToFit();
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let doneBtn = UIBarButtonItem(title: "Selesai", style: .plain, target: self, action: #selector(self.dissmissKeyboard))
        toolbar.setItems([flexibleSpace, doneBtn], animated: false);
        toolbar.isUserInteractionEnabled = true;
        
        txtSubject.inputAccessoryView = toolbar;
    }
    @objc func dissmissKeyboard(){
        view.endEditing(true);
    }
    
    //SETUP TEXT FIELD
    func textViewDidBeginEditing(_ textView: UITextView) {
        if txtTopic.text == "topik baru kamu" {
            txtTopic.text = nil
            txtTopic.textColor = UIColor.black
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if txtTopic.text.isEmpty {
            txtTopic.text = "topik baru kamu"
            txtTopic.textColor = UIColor.lightGray
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
