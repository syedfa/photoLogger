//
//  ViewController.swift
//  photoLogger
//
//  Created by Richard Martin on 2016-07-19.
//  Copyright © 2016 richard martin. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet

extension DetailView: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
//    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
//        
//        var emptyView = true
//        
//        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
//            DataService.ds.REF_POSTS.child((FIRAuth.auth()?.currentUser?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
//                print("DetailView: RGM: snapshot.childrenCount is: \(snapshot.childrenCount)")
//                if snapshot.childrenCount == 0 {
//                    emptyView = true
//                    print("DetailView: RGM: emptyView (when true) is: \(emptyView)")
//                    // return emptyView
//                } else {
//                    emptyView = false
//                    print("DetailView: RGM: emptyView (when false) is: \(emptyView)")
//                    // return emptyView
//                }
//                
//                }, withCancel: nil)
//            
//            DispatchQueue.main.async {
//                print("DetailView: RGM: emptyView is: \(emptyView)")
//            }
//        }
//        
//        print("DetailView: RGM: emptyView is: \(emptyView)")
//        return emptyView
//        
//    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "No Posts Available.")
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Time to add some PhotoLogger posts.")
    }
    
    /*
     unable to get working ... 
     
     
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "photo-logger-girl")
    }
 */
    
    
}

class DetailView: UIViewController, UITableViewDelegate, UITableViewDataSource, LoadDetailViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!

    var posts = [Post]()
    var postToEdit = FIRDataSnapshot()
    var fbPost = FIRDataSnapshot()
    var loadDetailView: LoginView?
    
    // MARK: - declare global cache var
    static var imageCache: NSCache<NSString, UIImage> = NSCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
        self.tableView.delegate = self
        
        self.title = "PhotoLogger"
        
        if FIRAuth.auth()?.currentUser == nil {
            print("DetailView -> RGM -> no currentUser")
            performSegue(withIdentifier: "goToSignIn", sender: nil)
        } else {
            print("DetailView -> RGM -> currentUser logged in \(FIRAuth.auth()?.currentUser?.uid)")
            // MARK: - firebase observer to track new post adds
            DataService.ds.REF_POSTS.child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childAdded, with: { (snapshot) in
                if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                    let postKey = snapshot.key
                    // call custom (convenience) init in Post.swift class to create a post
                    let post = Post(postKey: postKey, postData: postDict as! Dictionary<String, String>)
                    // append post to posts array (of Post type)
                    self.posts.append(post)
                }
                
                self.tableView.reloadData()
                self.tableView.reloadEmptyDataSet()
                print("DetailView -> RGM -> snap posts are: \(self.posts)")
            })
            
            // MARK: - firebase observer to track post edits/changes
            DataService.ds.REF_POSTS.child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childChanged, with: { (snapshot) in
                let postData = snapshot.value as! Dictionary<String, AnyObject>
                print("DetailView -> RGM -> postData for .childChanged \(postData)")
                let postKey = snapshot.key
                print("DetailView -> RGM -> postKey for .childChanged \(postKey)")
                print("DetailView -> RGM -> posts[0] \(self.posts[0])")
                
                let updatedPost = Post(postKey: postKey, postData: postData as! Dictionary<String, String>)
                
                let index = self.posts.index {
                    $0.postKey == postKey
                }
                
                self.posts[index!] = updatedPost
                self.tableView.reloadData()
            })
        }
    }
    
    func buildTable(controller: LoginView) {
        
        print("DetailView -> RGM -> buildTable function -> currentUser logged in \(FIRAuth.auth()?.currentUser?.uid)")
        
        // MARK: - firebase observer to track new post adds
        DataService.ds.REF_POSTS.child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childAdded, with: { (snapshot) in
            if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                let postKey = snapshot.key
                // call custom (convenience) init in Post.swift class to create a post
                let post = Post(postKey: postKey, postData: postDict as! Dictionary<String, String>)
                // append post to posts array (of Post type)
                self.posts.append(post)
            }
            
            self.tableView.reloadData()
            self.tableView.reloadEmptyDataSet()
            print("DetailView -> RGM -> snap posts are: \(self.posts)")
        })
        
        // MARK: - firebase observer to track post edits/changes
        DataService.ds.REF_POSTS.child((FIRAuth.auth()?.currentUser?.uid)!).observe(.childChanged, with: { (snapshot) in
            let postData = snapshot.value as! Dictionary<String, AnyObject>
            print("DetailView -> RGM -> postData for .childChanged \(postData)")
            let postKey = snapshot.key
            print("DetailView -> RGM -> postKey for .childChanged \(postKey)")
            print("DetailView -> RGM -> posts[0] \(self.posts[0])")
            
            let updatedPost = Post(postKey: postKey, postData: postData as! Dictionary<String, String>)
            
            let index = self.posts.index {
                $0.postKey == postKey
            }
            
            self.posts[index!] = updatedPost
            self.tableView.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
        self.title = "PhotoLogger"
    }
    
    // MARK: - clear out delegate and data source assignments for DZNEmptyDataSet when class is destroyed
    deinit {
        self.tableView.emptyDataSetSource = nil
        self.tableView.emptyDataSetDelegate = nil
    }
    
    // MARK: - delete individual posts from table view and firebase database and images from firebase storage
    internal func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let postImageURL = posts[indexPath.row].taskImage
            
            let postKey = posts[indexPath.row].postKey
            
            posts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            DataService.ds.REF_POSTS.child((FIRAuth.auth()?.currentUser?.uid)!).child(postKey).removeValue()
            
            let storage = FIRStorage.storage()
            let storageRef = storage.reference(forURL: postImageURL)
            
            storageRef.delete(completion: { (error ) in
                if (error != nil) {
                    print("DetailView -> RGM: error deleting image \(error)")
                } else {
                    print("DetailView -> RGM: image deleted")
                }
            })
        }
    }

    // MARK: - tableView Methods :: set up populating table view with cells
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row]
        var cell:PostCell
        
        cell = tableView.dequeueReusableCell(withIdentifier: "PostCellID") as! PostCell
            
        // check if we can source image from image cache
        if let img = DetailView.imageCache.object(forKey: post.taskImage as NSString) {
            cell.configureCell(post: post, img: img)
        } else {
            // image is not there :: return post data without image
            cell.configureCell(post: post, img: nil)
        }
        // assign tag attribute in shareButton the cell index row number
        cell.shareButton.tag = indexPath.row
        cell.shareButton.addTarget(self, action: #selector(sharePost), for: .touchUpInside)
        
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    internal func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: - logout user
    @IBAction func logoutButtonTapped(_ sender: AnyObject) {
        
        let currentUser = FIRAuth.auth()?.currentUser
        do {
            try! FIRAuth.auth()!.signOut()
            print("DetailView: RGM: user named, \(currentUser?.email), successfully logged out")
        }
        posts = [Post]()
        performSegue(withIdentifier: "goToSignIn", sender: nil)
    }
    
    // MARK: - add post with segue
    @IBAction func addPostButtonTapped(_ sender: AnyObject) {
        
        navigationItem.title = nil

        performSegue(withIdentifier: "addPostSegue", sender: nil)
    }
    
    // MARK: - edit post with segue :: didSelectRowAt
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "editPostSegue", sender: nil)
    }
    
    // MARK: - prepareForSegue for editPost and logOut
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editPostSegue", let dvc = segue.destination as? EditView, let postIndex = tableView.indexPathForSelectedRow?.row  {
            
            // back bar text
            let backBar = UIBarButtonItem()
            backBar.title = "Back"
            navigationItem.backBarButtonItem = backBar
            
            // assign dvc attributes to carry across to EditView controller on segue
            dvc.post = posts[postIndex]
            
            // when done, deselect the row
            let pathIndex = self.tableView.indexPathForSelectedRow
            self.tableView.deselectRow(at: pathIndex!, animated: true)
        } else if segue.identifier == "goToSignIn" {
            loadDetailView = segue.destination as? LoginView
            loadDetailView?.delegate = self
        }
    }
    
    // MARK: - (selector) logic to share post
    @IBAction  func sharePost(sender: UIButton) {
        
        var objectsToShare: [AnyObject]?
        let titlePost = self.posts[sender.tag].taskTitle as String
        // let descriptionPost = self.posts[sender.tag].taskDescription as String
        let url = NSURL(string: "http://www.google.com")
        
        objectsToShare = [titlePost as AnyObject, url as AnyObject]
        
        // let objectsToShare: [AnyObject] = [titlePost as AnyObject]
        // let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        let activityViewController = UIActivityViewController(activityItems: objectsToShare!, applicationActivities: nil)
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
   }
