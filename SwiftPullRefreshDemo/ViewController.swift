//
//  ViewController.swift
//  SwiftPullRefreshDemo
//
//  Created by donghai cheng on 14-10-22.
//  Copyright (c) 2014年 chd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var tableView:UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*tableView.addPullDownRefreshView {
            () -> Void in
            println("start loading")
            
        }*/
        tableView.addPullDownRefreshView({ () -> Void in
            println("start loading")
        }, baseContentOffset: 0.0)
        // Do any additional setup after loading the view, typically from a nib.
    }

    //stop loading
    func stopLoading() {
        self.tableView.stopAnimation()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        //must remove observer
        self.tableView.removePullObserver()
    }
}

