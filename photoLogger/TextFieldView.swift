//
//  TextFieldView.swift
//  photoLogger
//
//  Created by Richard Martin on 2016-08-09.
//  Copyright © 2016 richard martin. All rights reserved.
//

import UIKit

class TextFieldView: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.borderColor = UIColor(red: SHADOW_GRAY, green: SHADOW_GRAY, blue: SHADOW_GRAY, alpha: 0.3).cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 2.0
        
    }
    

    // adjust inset for background text
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5)
    }
    
    // adjust inset for test while editing in box
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5)

    }

}
