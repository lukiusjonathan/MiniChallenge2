//
//  diskusiVC.swift
//  diskusiSekolah
//
//  Created by Daniel Anadi Bagaskara on 08/05/20.
//  Copyright © 2020 Daniel Anadi Bagaskara. All rights reserved.
//

import UIKit
import Firebase

class Newest: NSObject {
    var topic: String?
    var senderUID: String?
    var subject: String?
    var sender: String?
    var senderImg: UIImage?
}
class TrendingTopic: NSObject {
    var topicName: String
    var senderUID: String
    var sender: String
    var senderImg: UIImage?
    var subject: String
    var reply: Int
    
    init(topicName : String = "", senderUID: String = "", sender: String = "", subject : String = "", reply : Int = 0){
        self.topicName = topicName
        self.senderUID = senderUID
        self.sender = sender
        self.subject = subject
        self.reply = reply
    }
}

private struct Const {
    /// Image height/width for Large NavBar state
    static let ImageSizeForLargeState: CGFloat = 40
    /// Margin from right anchor of safe area to right anchor of Image
    static let ImageRightMargin: CGFloat = 16
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Large NavBar state
    static let ImageBottomMarginForLargeState: CGFloat = 12
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Small NavBar state
    static let ImageBottomMarginForSmallState: CGFloat = 6
    /// Image height/width for Small NavBar state
    static let ImageSizeForSmallState: CGFloat = 32
    /// Height of NavBar for Small state. Usually it's just 44
    static let NavBarHeightSmallState: CGFloat = 44
    /// Height of NavBar for Large state. Usually it's just 96.5 but if you have a custom font for the title, please make sure to edit this value since it changes the height for Large state of NavBar
    static let NavBarHeightLargeState: CGFloat = 96.5
}

class diskusiVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let subject:[String] = ["Agama", "Bahasa Indonesia", "Bahasa Inggris", "Bahasa Mandarin", "Ilmu Pengetahuan Alam", "Ilmu Pengetahuan Sosial", "Komputer", "Matematika", "Olahraga", "Pendidikan Kewarganegaraan", "Seni Budaya"]
    var selectedSubject: Int?
    var selectedSubjectString: String?
    var refreshControl: UIRefreshControl?
    //FOR NEWEST AND TRENDING
    var selectedTopic: String?
    var selectedSender:String?
    var selectedSenderImg: UIImage?
    var selectedSenderUID: String?
    
    var topicCounter: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var trendings = [TrendingTopic]()
    var newest = [Newest]() {
        didSet {
            self.newestCollView.reloadData()
        }
    }

    @IBOutlet weak var lblSubjectTrending: UILabel!
    @IBOutlet weak var lblUserTrending: UILabel!
    @IBOutlet weak var lblTopicTrending: UILabel!
    
    @IBOutlet weak var newestCollView: UICollectionView!
    @IBOutlet weak var subjectCollView: UICollectionView!
    @IBOutlet weak var diskusiScrollView: UIScrollView!
    
    @IBOutlet weak var lblTrendingTopic: UILabel!
    @IBOutlet weak var lblTrendingSubject: UILabel!
    @IBOutlet weak var lblTrendingSender: UILabel!
    @IBOutlet weak var lblTrendingReply: UILabel!
    @IBOutlet weak var imgTrendingProfile: UIImageView!
    @IBOutlet weak var trendingView: UIView!
    
    let profileButtonView = UIImageView(image: UIImage(named: "UserDefaults40x40"))

    
    override func viewDidLoad() {
        super.viewDidLoad()
        diskusiScrollView.delegate = self
        
        transparentNavbar()
        addProfileBtn()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        setupTrendingTap()
        setupPullToRefresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        newest.removeAll()
        fetchNewest()
        fetchProfileImg()
        trendings.removeAll()
        fetchTrending()
    }
    
    func addProfileBtn() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(profileButtonView)
        profileButtonView.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        profileButtonView.clipsToBounds = true
        profileButtonView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileButtonView.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -Const.ImageRightMargin),
            profileButtonView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -Const.ImageBottomMarginForLargeState),
            profileButtonView.heightAnchor.constraint(equalToConstant: Const.ImageSizeForLargeState),
            profileButtonView.widthAnchor.constraint(equalTo: profileButtonView.heightAnchor)
        ])
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        profileButtonView.isUserInteractionEnabled = true
        profileButtonView.addGestureRecognizer(tapGestureRecognizer)
        
        profileButtonView.layer.cornerRadius = profileButtonView.frame.size.width/2
        profileButtonView.layer.borderColor = #colorLiteral(red: 0.1254901961, green: 0.4862745098, blue: 0.8431372549, alpha: 1)
        profileButtonView.layer.borderWidth = 1.5
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        if tappedImage == profileButtonView {
            profileBtnTap()
        }
    }
    
    @objc func profileBtnTap(){
        if Auth.auth().currentUser == nil{
            self.presentSignInScreen()
        }
        else {
            performSegue(withIdentifier: "profileSegue", sender: self)
        }
    }
    
    func fetchProfileImg() {
        if Auth.auth().currentUser == nil {
            self.profileButtonView.image = UIImage(named: "UserDefaults40x40")
            return
        }
        else {
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value) { (snapshot) in
            
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    if let profileImageURL = dictionary["profileImgURL"] as? String {
                        let url = URL(string: profileImageURL)
                        URLSession.shared.dataTask(with: url!) { (data, response, error) in
                            
                            if error != nil {
                                print("error")
                                return
                            }
                            DispatchQueue.main.async {
                                self.profileButtonView.image = UIImage(data: data!)
                            }
                        }.resume()
                    }
                }
            }
        }
    }
    
    func fetchTrending() {
        for sub in subject {
            
            Database.database().reference().child("topic").child("\(sub)").observe(.childAdded) { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    let post = TrendingTopic()
                    //print("sub saat ini: \(sub)")
                    post.topicName = (dictionary["topic"] as? String)!
                    post.subject =  sub
                    post.senderUID = (dictionary["senderUID"] as? String)!
                    post.reply = (dictionary["reply"] as? Int)!
                    
                    Database.database().reference().child("users").child(post.senderUID).observeSingleEvent(of: .value) { (snapshot) in
                        if let dictionary = snapshot.value as? [String: AnyObject]{
                            post.sender = (dictionary["fullname"] as? String)!
                            if let profileImageURL = dictionary["profileImgURL"] as? String {
                                let url = URL(string: profileImageURL)
                                URLSession.shared.dataTask(with: url!) { (data, response, error) in
                                    
                                    if error != nil {
                                        print("error")
                                        return
                                    }
                                    DispatchQueue.main.async {
                                        post.senderImg = UIImage(data: data!)!
                                    }
                                    self.trendings.insert(post, at: 0)
                                    DispatchQueue.main.async {
                                        self.trendings.sort(by: { $0.reply > $1.reply })
                                        self.lblTrendingSubject.text = self.trendings[0].subject.uppercased()
                                        self.lblTrendingTopic.text = self.trendings[0].topicName
                                        self.lblTrendingSender.text = self.trendings[0].sender
                                        self.lblTrendingReply.text = "\(self.trendings[0].reply) Balasan"
                                        self.imgTrendingProfile.image = self.trendings[0].senderImg
                                    }
                                }.resume()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchNewest() {
        Database.database().reference().child("newest").queryOrdered(byChild: "timestamp").observe(.childAdded) { (snapshot) in
                
            if let dictionary = snapshot.value as? [String: AnyObject]{
                let post = Newest()
                    
                post.topic = dictionary["topic"] as? String
                post.subject = dictionary["subject"] as? String
                post.senderUID = dictionary["senderUID"] as? String
                
                Database.database().reference().child("users").child(post.senderUID!).observeSingleEvent(of: .value) { (snapshot) in
                    if let dictionary = snapshot.value as? [String: AnyObject]{
                        post.sender = dictionary["fullname"] as? String
                        if let profileImageURL = dictionary["profileImgURL"] as? String {
                            let url = URL(string: profileImageURL)
                            URLSession.shared.dataTask(with: url!) { (data, response, error) in
                                
                                if error != nil {
                                    print("error")
                                    return
                                }
                                DispatchQueue.main.async {
                                    post.senderImg = UIImage(data: data!)
                                }
                            }.resume()
                        }
                    }
                }
                self.newest.insert(post, at: 0)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.newestCollView {
            if newest.count < 1 {
                return 1
            } else {
                return newest.count
            }
        }
        return subject.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.newestCollView {
            let newestCell = newestCollView.dequeueReusableCell(withReuseIdentifier: "newestCell", for: indexPath) as! newestCollVCell
            
            if newest.count > 0 {
                let post = newest[indexPath.row]
                
                newestCell.lblTopic.text = post.topic
                if post.subject == "Ilmu Pengetahuan Alam" {
                    newestCell.lblSubject.text = "IPA"
                }
                else if post.subject == "Ilmu Pengetahuan Sosial" {
                    newestCell.lblSubject.text = "IPS"
                }
                else if post.subject == "Pendidikan Kewarganegaraan" {
                    newestCell.lblSubject.text = "PKn"
                }
                else {
                    newestCell.lblSubject.text = post.subject?.uppercased()
                }
            } else {
                newestCell.lblTopic.text = "No Data"
                
            }
            
            return newestCell
        }
        else {
            let subjectCell = subjectCollView.dequeueReusableCell(withReuseIdentifier: "subjectCell", for: indexPath) as! subjectCollVCell
            subjectCell.btnChevron.isEnabled = false
            
            subjectCell.lblSubject.text = subject[indexPath.row]
            subjectCell.imgSubject.image = UIImage.init(named: subject[indexPath.row])
            
            //COUNT TOPIC IN SUBJECT COLLECTION VIEW
            for index in 0...10 {
                Database.database().reference().child("topic").child(subject[index]).observe(.value) { (snapshot) in
                    self.topicCounter[index] = Int(snapshot.childrenCount)
                    subjectCell.lblCounter.text = "\(self.topicCounter[indexPath.row]) topik"
                }
            }
            return subjectCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.newestCollView {
            let post = newest[indexPath.row]
            let currentCell = collectionView.cellForItem(at: indexPath) as! newestCollVCell
            
            selectedSubjectString = currentCell.lblSubject.text
            selectedTopic = currentCell.lblTopic.text
            selectedSender = post.sender
            selectedSenderImg = post.senderImg
            selectedSenderUID = post.senderUID
            
            performSegue(withIdentifier: "topicFromNewestSegue", sender: self)
        }
        else {
            selectedSubject = indexPath.row
            performSegue(withIdentifier: "subjectSegue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "subjectSegue") {
            let dest = segue.destination as! subjectVC
            dest.loadSubject = selectedSubject!
        }
        else if (segue.identifier == "topicFromNewestSegue") {
            let dest = segue.destination as! TopicVC
            dest.pertanyaan = selectedTopic
            dest.pengirim = selectedSender
            dest.subject = selectedSubjectString
            dest.topicSenderImg = selectedSenderImg
            dest.senderUID = selectedSenderUID
        }
        else if (segue.identifier == "topicFromTrendingSegue") {
            let dest = segue.destination as! TopicVC
            dest.pertanyaan = trendings[0].topicName
            dest.pengirim = trendings[0].sender
            dest.subject = trendings[0].subject
            dest.topicSenderImg = trendings[0].senderImg
            dest.senderUID = trendings[0].senderUID
        }
    }
    
    func transparentNavbar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
    }
    
    func presentSignInScreen(){
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signInVC = storyboard.instantiateViewController(withIdentifier: "loginScreen")
        signInVC.modalPresentationStyle = .fullScreen
        self.present(signInVC, animated: true, completion: nil)
    }
    
    func setupPullToRefresh(){
        refreshControl = UIRefreshControl()
        
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        diskusiScrollView.addSubview(refreshControl!)
    }
    
    @objc func refresh(_ sender: AnyObject) {
       // Code to refresh table view
        print("Refresh Berhasil")
        newest.removeAll()
        fetchNewest()
        fetchProfileImg()
        trendings.removeAll()
        fetchTrending()
        refreshControl!.endRefreshing()
    }

    @IBAction func unwindLogout(_ sender: UIStoryboardSegue) {}
}

extension diskusiVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        moveAndResizeImage(for: height)
    }
    
    func moveAndResizeImage(for height: CGFloat) {
        let coeff: CGFloat = {
            let delta = height - Const.NavBarHeightSmallState
            let heightDifferenceBetweenStates = (Const.NavBarHeightLargeState - Const.NavBarHeightSmallState)
            return delta / heightDifferenceBetweenStates
        }()

        let factor = Const.ImageSizeForSmallState / Const.ImageSizeForLargeState

        let scale: CGFloat = {
            let sizeAddendumFactor = coeff * (1.0 - factor)
            return min(1.0, sizeAddendumFactor + factor)
        }()

        // Value of difference between icons for large and small states
        let sizeDiff = Const.ImageSizeForLargeState * (1.0 - factor) // 8.0
        let yTranslation: CGFloat = {
            /// This value = 14. It equals to difference of 12 and 6 (bottom margin for large and small states). Also it adds 8.0 (size difference when the image gets smaller size)
            let maxYTranslation = Const.ImageBottomMarginForLargeState - Const.ImageBottomMarginForSmallState + sizeDiff
            return max(0, min(maxYTranslation, (maxYTranslation - coeff * (Const.ImageBottomMarginForSmallState + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)

        profileButtonView.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation, y: yTranslation)
    }
    
    private func showImage(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.profileButtonView.alpha = show ? 1.0 : 0.0
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showImage(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showImage(true)
    }
    
    //MARK: Setup Tap untuk trending view
    
    func setupTrendingTap(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTrendingTap(_:)))
        trendingView.addGestureRecognizer(tap)
        trendingView.isUserInteractionEnabled = true
    }
    
    @objc func handleTrendingTap(_ sender: UITapGestureRecognizer? = nil) {
        //Pindah ke halaman topic sesuai dengan trending
        performSegue(withIdentifier: "topicFromTrendingSegue", sender: self)
    }
}
