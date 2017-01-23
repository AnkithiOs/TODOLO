//
//  EditView.swift
//  RealmTODOLO
//
//  Created by Sunny on 23/1/2017.
//  Copyright © 2017 Ramayanam SaiAnkith. All rights reserved.
//

import UIKit

class EditView: UIView {
    @IBOutlet var lowPBtn: UIButton!
    @IBOutlet var regularPBtn: UIButton!
    @IBOutlet var highPBtn: UIButton!
    
    var priority = 1
    
    var btns = [UIButton]() //[lowPBtn, regularPBtn, highPBtn]
    
    @IBAction func selectPriority(_ sender: UIButton){
        for i in 0..<btns.count{
            if(btns[i] != sender){
                btns[i].setTitleColor(UIColor.blue, for: .normal)
            }else{
                btns[i].setTitleColor(UIColor.green, for: .normal)
                priority = i
            }
        }
    }
    
    @IBAction func submit(_ sender: Any) {
        self.removeFromSuperview()
    }
    open override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        btns = [lowPBtn, regularPBtn, highPBtn]
        if self.subviews.count > 0 { return self }
        guard let view = type(of: self).loadFromNib() else { return self }
        return view
    }
    
    open class func loadFromNib() -> EditView! {
        
        guard let view = Bundle(for: self).loadNibNamed(String(describing: self), owner: nil, options: nil)?.first as? EditView else { return nil }
        view.btns = [view.lowPBtn, view.regularPBtn, view.highPBtn]
        return view
    }
}
