//
//  ViewController.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 05/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class loginVC: UIViewController{

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
    }

    @IBAction func loginTapped(_ sender: Any) {
        if (emailField.text == "" || passwordField.text == ""){
            //check if text field is empty
            print("please input data")
            createAlert(message: "isi email dan kata sandi anda")
        }
        else{
            let email = emailField.text
            let password = passwordField.text
            
            Auth.auth().signIn(withEmail: email!, password: password!) { user, error in
                //CHECK ERROR FIREBASE
                if let firebaseError = error {
                    print(firebaseError.localizedDescription)
                    
                    if firebaseError.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted." {
                        self.createAlert(message: "Email ini tidak terdaftar.")
                    }
                    else if firebaseError.localizedDescription == "The password is invalid or the user does not have a password." {
                        self.createAlert(message: "Kata sandi yang anda masukan salah.")
                    }
                    else{
                        self.createAlert(message: firebaseError.localizedDescription)
                    }
                    return
                }
                print("Login Success!")
                self.presentLoggedInScreen()
            }
        }
    }
    
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
    
    @IBAction func btnCancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func unwindSegue(_ sender: UIStoryboardSegue) {}

}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

