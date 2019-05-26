//
//  AlarmViewController.swift
//  layerone2019swift


import Foundation
import UIKit

class AlarmViewController: UIViewController
{
    @IBOutlet weak var faceLabel: UILabel!
    @IBOutlet weak var periodLabel: UILabel!
    @IBOutlet weak var cdLabel: UILabel!
    @IBOutlet weak var faceStep: UIStepper!
    @IBOutlet weak var periodStep: UIStepper!
    @IBOutlet weak var cdStep: UIStepper!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cdStep.wraps = true
        cdStep.autorepeat = true
        cdStep.maximumValue = 3600
        cdStep.value = 60
        cdLabel.text = "60"
        
        faceStep.wraps = true
        faceStep.autorepeat = true
        faceStep.maximumValue = 10
        faceStep.value = 1
        faceLabel.text = "1"
        
        periodStep.wraps = true
        periodStep.autorepeat = true
        periodStep.maximumValue = 60
        periodStep.value = 10
        periodLabel.text = "10"

        
        cdStep.addTarget(self, action: #selector(AlarmViewController.cdStepValChanged(_:)), for: .valueChanged)
        faceStep.addTarget(self, action: #selector(AlarmViewController.faceStepValChanged(_:)), for: .valueChanged)
        periodStep.addTarget(self, action: #selector(AlarmViewController.periodStepValChanged(_:)), for: .valueChanged)
        
        addButton.addTarget(self, action:#selector(self.add), for: .touchUpInside)
        cancelButton.addTarget(self, action:#selector(self.cancel), for: .touchUpInside)
    }
    
    @objc func cancel(_ sender:UIButton!)
    {
        NotificationCenter.default.post(name: NSNotification.Name("returnfromconfig"), object: nil)

    }
    
    @objc func add(_ sender:UIButton!)
    {
        let alarm = AlarmSetting(faces: Int(faceStep.value), period: periodStep.value, cooldown: cdStep.value)
        config.alarm = alarm
        NotificationCenter.default.post(name: NSNotification.Name("returnfromconfig"), object: nil)
    }
    
    
    @objc func cdStepValChanged(_ sender:UIStepper!)
    {
        cdLabel.text = String(Int(sender.value))
    }
    
    @objc func faceStepValChanged(_ sender:UIStepper!)
    {
        faceLabel.text = String(Int(sender.value))
    }

    @objc func periodStepValChanged(_ sender:UIStepper!)
    {
        periodLabel.text = String(Int(sender.value))
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
