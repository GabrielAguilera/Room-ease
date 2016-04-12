//
//  SharedUserManager.swift
//  RoomEase
//
//  Created by Jessica Aboukasm on 3/8/16.
//  Copyright © 2016 RoomEase - EECS 441. All rights reserved.
//

import Firebase
import Foundation
import FBSDKCoreKit
import FBSDKLoginKit

class ShareData {
    
    class var sharedInstance: ShareData {
        struct Static {
            static var instance: ShareData?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ShareData()
        }
        
        return Static.instance!
    }

    let ROOT_URL:String = "https://fiery-heat-3695.firebaseio.com/"
    var userSelectedTasks:[String:Int] = [:]
    var roommateRankings: [String:Int] = [:]
    
    var roommateRankingsChanged = false
    var bestRoommate = false
    var currentUser:String = ""
    var currentUserId:String = ""
    var currentUserPhotoUrl:String = ""
    var currentHomeId:String = ""
    
    var taskList:[String:Int] = ["Clean kitchen after party":50, "Clean upstairs bathroom":35]
    
    func getPointsUrl() -> String {
        return ROOT_URL + "users/" + currentUserId + "/points"
    }
    
//    Usage example
//    -------------
//    ShareData().get_open_tasks("home1", callback: { (openTasks:[String:NSDictionary]) in
//        print(openTasks)
//    })
    func get_open_tasks(homeID:String, callback:([String:NSDictionary]) -> Void) {
        let ref = Firebase(url: self.ROOT_URL + "tasks")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var tasks = [String:NSDictionary]()
            let enumerator = snapshot.children
            while let child = enumerator.nextObject() as? FDataSnapshot {
                let task = child.value as! NSDictionary
                if (String(task["homeId"]!) == homeID && task["assignedTo"] == nil){
                    tasks[child.key!] = task
                }
            }
            callback(tasks)
        })
    }
    
//    Gives tasks as (unique_key, dictionary)
//    Usage example
//    -------------
//    ShareData().get_user_tasks("mgild", callback: { (tasks:[String: NSDictionary]) in
//        print(tasks)
//    })
    func get_user_tasks(username:String, callback:([String: NSDictionary]) -> Void) {
        let ref = Firebase(url: self.ROOT_URL + "tasks")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
            var tasks = [String: NSDictionary]()
            let enumerator = snapshot.children
            while let child = enumerator.nextObject() as? FDataSnapshot {
                let task = child.value as! NSDictionary
                if (task["assignedTo"] != nil && String(task["assignedTo"]!) == username){
                    tasks[child.key!] = task
                }
            }
            callback(tasks)
        })
    }
    
    //for some reason could not get the firebase sort to work
    //sorting by value myself
    //currently uses callback that returns an array of tuples (User, score) pairs
    //example call
    //-----------
//  ShareData().get_roomate_rankings("home1", callback: { (roomates:[(String,Int)]) in
//      print(roomates)
//  })
    func get_roomate_rankings(callback:([(String, Int)]) -> Void) {
        self.roommateRankings.removeAll()
        let ref = Firebase(url: self.ROOT_URL + "users")
        ref.observeSingleEventOfType(.Value, withBlock: { snapshot in
           // var roomate_scores = [String:Int]()
            //This loop builds the array from the Firebase snap
            for item in snapshot.children {
                let user = item as! FDataSnapshot
                
                let user_home = String(user.childSnapshotForPath("homeId").value)
                if (self.currentHomeId == user_home) {
                    //get the username from the tuple
                    let user_points = Int(String(user.childSnapshotForPath("points").value))
                    let userName = String(user.childSnapshotForPath("name").value)                    
                    self.roommateRankings[userName] = user_points
                }
            }
            //function for sorting by value
            let byValue = {
                (elem1:(key: String, val: Int), elem2:(key: String, val: Int))->Bool in
                if elem1.val > elem2.val {
                    return true
                } else {
                    return false
                }
            }
            //sorts roomates by value
            let sorted_roomate_scores = self.roommateRankings.sort(byValue)
            callback(sorted_roomate_scores)
        })
    }
    
    //example usage:
    //--------------
    //ShareData().push_task(["homeId":"home1", "points": "5", "title": "test"])
    func push_task(var values:[String:String]) {
        let ref = Firebase(url: self.ROOT_URL + "tasks")
        //TODO: throw error here
        if (values["homeId"] == nil || values["points"] == nil || values["title"] == nil) {
            assert(false)
        }
        //automatically creates a unique ID for the task
        ref.childByAutoId().setValue(values)
    }
    

    //example usage:
    //--------------
    //ShareData().assign_task("-KESJq2Rxv8AhbIjjDNE", user: "mgild")
    func assign_task(task_key:String, user:String) {
        let ref = Firebase(url: self.ROOT_URL + "tasks/" + task_key)
        ref.updateChildValues(["assignedTo": user])
    }
}