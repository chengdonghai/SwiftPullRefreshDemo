//
//  File.swift
//  D2Video
//
//  Created by donghai cheng on 14-10-4.
//  Copyright (c) 2014年 Donghai Cheng. All rights reserved.
//
import CoreGraphics
import QuartzCore
import UIKit

//圆的半径
let radius:CGFloat = 8.0
//圆周长
let circumference = 2.0 * CGFloat(M_PI) * radius



enum PullDownRefreshType : Int {
    case PullNoDown //未下拉
    case PullDowning //正在下拉
    case Refreshing //正在刷新
    case PullDowned //下拉完毕
}

class PullDownRefreshView:UIView {
    
    
    //线条粗细
    let lineWidth:CGFloat = 2.0
    //线条颜色
    var lineStrokeColor:UIColor = UIColor.darkGrayColor()
    //开始角度
    var startAngle:CGFloat = -CGFloat(M_PI_2)
    //结束角度
    var endAngle:CGFloat = -CGFloat(M_PI_2)
    //竖线长度
    var verticalLineLength:CGFloat = 0.0
    //三角形长度
    let arrowEdgeLength:CGFloat = 8.0
    //
    var baseContentOffset:CGFloat = 0.0
    
    lazy var refreshBlock = {
        ()->Void in
    }
    
    var refreshType = PullDownRefreshType.PullNoDown
    
 
    deinit {
        println("PullDownRefreshView 被释放了")
        
    }
    
    //画直线和圆
    override func drawRect(rect: CGRect) {
        //圆周长
        var ctx = UIGraphicsGetCurrentContext()
        var centerX = rect.width / 2.0
        var centerY = rect.height / 2.0// - radius - 12
        CGContextSaveGState(ctx)
        CGContextSetShouldAntialias(ctx, true);
        CGContextSetAllowsAntialiasing(ctx, true);
        //CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, centerX, centerY - self.verticalLineLength - radius)
        CGContextAddLineToPoint(ctx, centerX, centerY - radius)
        CGContextAddArc(ctx, centerX, centerY, radius, startAngle, endAngle, 0)
        CGContextSetStrokeColorWithColor(ctx, self.lineStrokeColor.CGColor)
        CGContextSetLineWidth(ctx, self.lineWidth)
        var currentPoint = CGContextGetPathCurrentPoint(ctx)
        //CGContextDrawPath (ctx, kCGPathStroke)
         CGContextStrokePath(ctx)
       
        //画三角
        var k =  (currentPoint.y - centerY) / (currentPoint.x - centerX)
        var degree:CGFloat = 0.0
        if(currentPoint.x < centerX && currentPoint.y < centerY) {
            degree = -CGFloat(M_PI_2)
            k = -(currentPoint.x - centerX) / (currentPoint.y - centerY)
        } else if (currentPoint.x < centerX && currentPoint.y > centerY) {
            degree = CGFloat(M_PI_2)
            k = -(currentPoint.x - centerX) / (currentPoint.y - centerY)
        }
        CGContextTranslateCTM(ctx, currentPoint.x, currentPoint.y)
        CGContextRotateCTM(ctx,  degree + CGFloat(atanf(Float(k))))
        CGContextMoveToPoint(ctx, 0, arrowEdgeLength / CGFloat(sqrtf(3.0)) )
        CGContextAddLineToPoint(ctx, -arrowEdgeLength / 2.0, -arrowEdgeLength / (2.0 * CGFloat(sqrtf(3.0))))
        CGContextAddLineToPoint(ctx, arrowEdgeLength / 2.0, -arrowEdgeLength / (2.0 * CGFloat(sqrtf(3.0))))
        CGContextClosePath(ctx)
        CGContextSetFillColorWithColor(ctx, self.lineStrokeColor.CGColor)
        CGContextFillPath(ctx)
        
    
        CGContextRestoreGState(ctx)
    }
}

extension UIScrollView {
    
    /* 添加下拉视图
     * @param refreshBlock 刷新数据的回调
     * @param baseContentOffset 原始ContentOffset.y
     */
    func addPullDownRefreshView (refreshBlock:(()->Void)?,baseContentOffset:CGFloat) {
        var pullDownView = self.viewWithTag(10) as? PullDownRefreshView
        if(pullDownView == nil) {
            let height:CGFloat = 50.0
            pullDownView = PullDownRefreshView(frame: CGRectMake(0, -height, self.frame.size.width, height))
            pullDownView!.verticalLineLength = circumference
            pullDownView!.backgroundColor = UIColor.clearColor()
            pullDownView!.tag = 10
            pullDownView!.baseContentOffset = baseContentOffset
 
            pullDownView!.autoresizingMask = UIViewAutoresizing.FlexibleWidth
            self.addSubview(pullDownView!)
            self.addObserver(self, forKeyPath: "contentOffset", options: .New | .Old, context: nil)
      
        }
        
        if(refreshBlock != nil) {
            pullDownView?.refreshBlock = refreshBlock!
        }
        
        
    }
   
    //设置基本contentoffsety
    func setBaseContentOffsetY (offset:CGFloat) {
        if var pullDownView = self.viewWithTag(10) as? PullDownRefreshView {
            pullDownView.baseContentOffset = offset
        }
    }
    /* 添加下拉视图
     * @param refreshBlock 刷新数据的回调 baseContentOffset.y=0.0
     */
    func addPullDownRefreshView (refreshBlock:(()->Void)?) {
        self.addPullDownRefreshView(refreshBlock, baseContentOffset: 0.0)
    }

    //移除观察者
    func removePullObserver() {
        self.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    //KVO
    override public func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "contentOffset" {
      
            if var pullDownView = self.viewWithTag(10) as? PullDownRefreshView {
                pullDownView.hidden = false
                var baseOffsetY:CGFloat = pullDownView.baseContentOffset + 12 + 2.0 * radius

                if(pullDownView.refreshType != PullDownRefreshType.Refreshing) {

                    if(self.contentOffset.y <= 0 - baseOffsetY && self.contentOffset.y > 0 - baseOffsetY - circumference / 2.0) {
                        if (pullDownView.refreshType == PullDownRefreshType.PullDowned) {
                            
                            if(self.dragging == false) {
                                self.startAnimating()
                            } else {
                                self.drawRectAtChange(baseOffsetY)
                            }
                        } else {
                            self.drawRectAtChange(baseOffsetY)
                        }
                        
                    } else if(self.contentOffset.y > 0 - baseOffsetY) {
                        if(pullDownView.refreshType != PullDownRefreshType.PullDowned) {
                            self.drawRectAtStart()
                        }
                    } else {
                        self.drawRectAtEnd()
                        if(self.dragging == false) {
                            self.startAnimating()
                        }
                        
                    }
                }
            }
        }  else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    //正在画图
    func drawRectAtChange(baseOffsetY:CGFloat) {
        if var pullDownView = self.viewWithTag(10) as? PullDownRefreshView {
        pullDownView.refreshType = PullDownRefreshType.PullDowning
        var verticalLength = circumference + (baseOffsetY + self.contentOffset.y) * 2.0
      
        var endEng = 2.0 * CGFloat(M_PI) * ((circumference - verticalLength) / circumference) - CGFloat(M_PI_2)
        pullDownView.endAngle = endEng
        pullDownView.lineStrokeColor = UIColor.darkGrayColor()
        pullDownView.verticalLineLength = verticalLength
      
        pullDownView.setNeedsDisplay()
       
        }
    }
    //画开始的视图
    func drawRectAtStart() {
        if var pullDownView = self.viewWithTag(10) as? PullDownRefreshView {
            pullDownView.transform = CGAffineTransformIdentity
          
            pullDownView.endAngle = -CGFloat(M_PI_2)
            pullDownView.lineStrokeColor = UIColor.darkGrayColor()
            pullDownView.verticalLineLength = circumference
            pullDownView.refreshType = PullDownRefreshType.PullNoDown
           
            pullDownView.setNeedsDisplay()
            
        }
    }
    //画结束的视图
    func drawRectAtEnd() {
        if  var pullDownView = self.viewWithTag(10) as? PullDownRefreshView {
            pullDownView.transform = CGAffineTransformIdentity
            pullDownView.endAngle = 3.0 * CGFloat(M_PI_2)
            pullDownView.lineStrokeColor = UIColor.grayColor()
            pullDownView.verticalLineLength = 0.0
            pullDownView.refreshType = PullDownRefreshType.PullDowned
           
            pullDownView.setNeedsDisplay()
            
        }
    }
    
    //开始动画
    func startAnimating() {
        if var pullDownView = self.viewWithTag(10) as? PullDownRefreshView {
            pullDownView.hidden = false
            if(pullDownView.refreshType != PullDownRefreshType.Refreshing) {
                pullDownView.refreshType = PullDownRefreshType.Refreshing
                
                pullDownView.refreshBlock()
                
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.contentInset = UIEdgeInsetsMake(pullDownView.baseContentOffset+pullDownView.frame.size.height, self.contentInset.left, self.contentInset.bottom, self.contentInset.right)
                    }, completion: {
                        (flag:Bool) -> Void in
                        
                })
                self.rotationCicle(pullDownView)
                
            }
        }
    }
    //停止动画
    func stopAnimation() {
        if var pullDownView = self.viewWithTag(10) as? PullDownRefreshView {

            pullDownView.refreshType = PullDownRefreshType.PullDowned
           var rotation = pullDownView.layer.presentationLayer().valueForKeyPath("transform.rotation") as NSNumber
            
            
            pullDownView.layer.setValue(NSNumber.numberWithDouble(rotation.doubleValue + (M_PI / 3.5)), forKeyPath: "transform.rotation")
            
            pullDownView.layer.removeAnimationForKey("rotttt")
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.contentInset = UIEdgeInsetsMake(pullDownView.baseContentOffset, self.contentInset.left, self.contentInset.bottom, self.contentInset.right)
            }, completion: { (flat:Bool) -> Void in
                self.drawRectAtStart()
            })
            
        }
    }
    //执行旋转动画
    func rotationCicle(pdview:PullDownRefreshView) {
        var animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 0.8
      
        animation.fromValue = pdview.layer.valueForKeyPath(animation.keyPath)//
        animation.toValue = NSNumber.numberWithDouble(2 * M_PI)
        
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.repeatCount = 99999
        animation.removedOnCompletion = false
        animation.delegate = self
        animation.autoreverses = false
        animation.fillMode = kCAFillModeForwards
        animation.cumulative = true;
        pdview.layer.addAnimation(animation, forKey: "rotttt")
    }
    
}