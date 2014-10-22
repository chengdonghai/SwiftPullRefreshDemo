SwiftPullRefreshDemo
====================

Pull Refresh with swift


Add a pull refresh for a scrollView like this.

tableView.addPullDownRefreshView({ () -> Void in
            println("start loading")
        }, baseContentOffset: 0.0)
        
And stop loading like this.

self.tableView.stopAnimation()

