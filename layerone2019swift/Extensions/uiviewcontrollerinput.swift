//
//  uiviewcontrollerinput.swift
//  layerone2019swift

import Foundation
import UIKit


extension UIViewController {
    func showInputDialog(title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:String? = "Add",
                         cancelTitle:String? = "Cancel",
                         inputPlaceholder:String? = nil,
                         inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                         cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                         actionHandler: ((_ text: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = inputPlaceholder
            textField.keyboardType = inputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
            guard let textField =  alert.textFields?.first else {
                actionHandler?(nil)
                return
            }
            actionHandler?(textField.text)
        }))
        if let unwrappedcancel = cancelTitle {
            alert.addAction(UIAlertAction(title: unwrappedcancel, style: .cancel, handler: cancelHandler))
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    func showMenuDialog( title:String? = nil,
                         subtitle:String? = nil,
                         actionTitle:[Int:String] = [2:"Highlight"],
                         cancelTitle:String? = "Cancel",
                         actionHandler: ((_ num: Int?) -> Void)? = nil){
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        for (key, val) in actionTitle.sorted(by: {$0.key < $1.key}) {
            alert.addAction(UIAlertAction(title: val, style: .destructive, handler: { (action:UIAlertAction) in
                actionHandler?(key)
            }))
        }
        self.present(alert, animated: true, completion: nil)
    }
        
    func flashAlert(title:String = "Title", message:String = "Someone forgot to fill this", delay:Double = 2.0) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        
        // change to desired number of seconds (in this case 5 seconds)
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when){
            // your code with delay
            alert.dismiss(animated: true, completion: nil)
    }
    }
}
