//
//  ViewController.swift
//  RealmTODOLO
//
//  Created by Sunny on 23/1/2017.
//  Copyright © 2017 Ramayanam SaiAnkith. All rights reserved.
//

import UIKit
import RealmSwift

// MARK: Realm Models

final class TaskList: Object {
    dynamic var text = ""
    //dynamic var priority = ""
    dynamic var id = ""
    let items = List<Task>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Task: Object {
    dynamic var text = ""
    dynamic var priority = 1
    dynamic var completed = false
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TvTaskCellDelegate, UISearchBarDelegate {
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    var searchActive: Bool = false
    
    var filteredItems = List<Task>()
    var items = List<Task>()
    var notificationToken: NotificationToken!
    var realm: Realm!
    
    
    var priorities:[UIColor] = [.yellow, .orange, .red]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        setupRealm()
    }
    
    private func initView() {
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        title = "My Tasks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        navigationItem.leftBarButtonItem = editButtonItem
    }
    func setupRealm() {
        // Log in existing user with username and password
        let username = "ankithj"  // <--- Update this
        let password = "pswdj"  // <--- Update this
        
        SyncUser.logIn(with: .usernamePassword(username: username, password: password, register: false), server: URL(string: "http://127.0.0.1:9080")!) { user, error in
            guard let user = user else {
                fatalError(String(describing: error))
            }
            
            DispatchQueue.main.async {
                // Open Realm
                let configuration = Realm.Configuration(
                    syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://127.0.0.1:9080/~/realmtasks")!)
                )
                self.realm = try! Realm(configuration: configuration)
                
                // Show initial tasks
                func updateList() {
                    if self.items.realm == nil, let list = self.realm.objects(TaskList.self).first {
                        self.items = list.items
                        self.filteredItems = list.items
                    }
                    self.tableView.reloadData()
                }
                updateList()
                
                // Notify us when Realm changes
                self.notificationToken = self.realm.addNotificationBlock { _ in
                    updateList()
                }
            }
        }
    }
    
    deinit {
        notificationToken.stop()
    }
    
    // MARK: Functions
    func add() {
        let alertController = UIAlertController(title: "New Task", message: "Enter Task Name", preferredStyle: .alert)
        var alertTextField: UITextField!
        alertController.addTextField { textField in
            alertTextField = textField
            textField.placeholder = "Task Name"
        }
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let text = alertTextField.text , !text.isEmpty else { return }
            
            let items = self.items
            try! items.realm?.write {
                items.insert(Task(value: ["text": text, "priority": 1]), at: items.filter("completed = false").count)
            }
            self.filteredItems = items
        })
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UITableView
    
    func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count//items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell") as! TvTaskCell
        cell.delegate = self
        let item = filteredItems[indexPath.row]//items[indexPath.row]
        cell.textLabel?.text = item.text
        cell.textLabel?.alpha = item.completed ? 0.5 : 1
        return cell
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        try! items.realm?.write {
            items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
            filteredItems = items
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! realm.write {
                let item = items[indexPath.row]
                realm.delete(item)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = filteredItems[indexPath.row]//items[indexPath.row]
        try! item.realm?.write {
            item.completed = !item.completed
            let destinationIndexPath: IndexPath
            if item.completed {
                // move cell to bottom
                destinationIndexPath = IndexPath(row: items.count - 1, section: 0)
            } else {
                // move cell just above the first completed item
                let completedCount = items.filter("completed = true").count
                destinationIndexPath = IndexPath(row: items.count - completedCount - 1, section: 0)
            }
            items.move(from: indexPath.row, to: destinationIndexPath.row)
        }
    }
    // MARK: TableViewCell Delegate Function(s) implimentation
    
    func cellDidClickEdit(cell: TvTaskCell){
        if(priorities.contains(cell.priorityIndicator.backgroundColor!)){
            if(cell.priorityIndicator.backgroundColor == priorities.last){
                cell.priorityIndicator.backgroundColor = priorities.first
            }else{
                var i = priorities.index(of: cell.priorityIndicator.backgroundColor!)! + 1
                cell.priorityIndicator.backgroundColor = priorities[i]
            }
        }
        //let item = self.items[(tableView.indexPath(for: cell)?.row)!]
        //item.priority = priorities.index(of: cell.priorityIndicator.backgroundColor!)!
    }
    
    
    
    // MARK: SearchBar Delegate Functions: 
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text
        search(text: text)
        searchBar.endEditing(true)
    }
    
   func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
        search(text: searchText)
    
    
        
        if(filteredItems.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
    }
    
    func search(text: String!) {
        if text != ""{
            filteredItems = List<Task>()
            for i in items{
                if i.text.lowercased().contains(text.lowercased()){
                    filteredItems.append(i)
                }
            }
        }else{
            filteredItems = items
        }
    }
    
    
}

@objc protocol TvTaskCellDelegate {
    @objc optional func cellDidClickEdit(cell: TvTaskCell)
    
}

class TvTaskCell: UITableViewCell{
    weak var delegate: TvTaskCellDelegate?
    
    @IBOutlet var priorityIndicator: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        priorityIndicator.backgroundColor = UIColor.orange
        layoutIfNeeded()
        setNeedsLayout()
    }
    
    @IBAction func editAction(_ sender: Any) {
        delegate?.cellDidClickEdit!(cell: self)
    }
}


