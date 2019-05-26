//
//  RootViewController.swift
//  layerone2019swift


import Foundation
import UIKit
import CoreGraphics

var stream: MJPEGStreamLib!
var config:Config!

class RootViewController: UINavigationController {
    
    var index: integer_t!
    var eyeViewController:ViewController!
    var fullViewController:FullViewController!
    let swipeRight = UISwipeGestureRecognizer();
    let swipeLeft = UISwipeGestureRecognizer();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config = Config()
        print("rootviewcontroller loading")
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        self.eyeViewController = storyBoard.instantiateViewController(withIdentifier: "VKView") as! ViewController
        self.fullViewController = storyBoard.instantiateViewController(withIdentifier: "FullView") as!FullViewController
        
        addGestures()
        
        NotificationCenter.default.addObserver(self, selector: #selector(badge_url_entry), name: NSNotification.Name("badgeurlfailure"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(returnFromConfig), name: NSNotification.Name("returnfromconfig"), object: nil)

        index = 0
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func addGestures() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        singleTapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(singleTapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubletapped))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        singleTapGesture.require(toFail: doubleTapGesture)
        
        
        swipeLeft.addTarget(self,action: #selector(respondToSwipeLeft))
        swipeLeft.direction = .left;
        self.view.addGestureRecognizer(swipeLeft)
        
        swipeRight.addTarget(self,action: #selector(respondToSwipeRight))
        swipeRight.direction = .right;
        self.view.addGestureRecognizer(swipeRight)

    }

    @objc private func badge_url_entry() {
        showInputDialog(title: "Badge IP",
                        subtitle: "Please enter the badge IP",
                        actionTitle: "Connect",
                        cancelTitle: nil,
                        inputPlaceholder: nil,
                        inputKeyboardType: .decimalPad)
        { (input:String?) in
            config.badge_url =  "http://\(input ?? "")/jpg_stream"
            stream.stop()
            let url = URL(string: config.badge_url)
            stream.contentURL = url
            stream.play()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    @objc func respondToSwipeRight()
    {
        print("swipedright")
        if index != 1 {
            self.index = 1
                self.pushViewController(fullViewController, animated: true)
        }
        }
    
    @objc func returnFromConfig()
    {
        self.popViewController(animated: true)
        self.addGestures()
    }
    
    @objc func respondToSwipeLeft()
    {
        print("swipedleft")
        if index != 0 {
            self.index = 0
                self.popViewController(animated: true)
        }
    }
    
    @objc func tapped() {
        // nothing for now
        return
    }
    
    @objc func imageSave(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            self.flashAlert(title: "Save error", message: error.localizedDescription)
        } else {
            self.flashAlert(title: "Saved", message: "Saved to your photos")
        }
    }

    @objc func videoSave(_ video: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let tempPath = FileManager.default.temporaryDirectory
        let videoOutputURL =  tempPath.appendingPathComponent("AssembledVideo.mov")
        if let error = error {
            // we got back an error!
            self.flashAlert(title: "Save error", message: error.localizedDescription)
        } else {
            self.flashAlert(title: "Saved", message: "Saved video")
        }
        do {
            try FileManager.default.removeItem(atPath: videoOutputURL.path)
        }
        catch {
            print("error deleting temp video")
        }
    }

    func createAlarmConfig() -> AlarmViewController {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let alarmView = storyBoard.instantiateViewController(withIdentifier: "AlarmView") as! AlarmViewController
        return alarmView
    }
    
    @objc func filtermenu()
    {
        let filters = [1:"cartoon", 2:"sketch", 3:"pixellate",4:"polkadot",5:"halftone",6:"cga", 7:"solarize", 8:"none" ]
        showMenuDialog(actionTitle:filters) {
            (input:Int?) in
            if input != nil {
                if input == 8 {
                    stream.filter = nil
                }
                else {
                    stream.filter = filters[input!]
                }
            }
        }

    }
    
    @objc func doubletapped()
    {
        var recstring:String
        var alarmstring:String
        if stream.recording {
            recstring = "Stop Recording"
        }
        else {
            recstring = "Start Recording"
        }
        
        if config.alarm == nil {
            alarmstring = "Set alarm"
        }
        else {
            alarmstring = "Cancel alarm"
        }
        
        showMenuDialog(actionTitle:[1:"Debug", 2:"Reset Stream", 3:"Rotate 90",4:"Save",5: recstring, 6:alarmstring,7:"Filter", 8:"Cancel"]) {
            (input:Int?) in
            switch (input){
            // eye highlight mode
            case 1:
                config.debug = !config.debug
            case 2:
                stream.stop()
                stream.play()
            case 3:
                if config.prerotate <= 2 {
                    config.prerotate = config.prerotate+1
                }
                else {
                    config.prerotate = 0
                }
            case 4:
                stream.save(#selector(self.imageSave(_:didFinishSavingWithError:contextInfo:)), inst: self as UIViewController)
            case 5:
                if stream.recording {
                    stream.stop_recording(#selector(self.videoSave(_:didFinishSavingWithError:contextInfo:)), inst: self as UIViewController)
                }
                else {
                    stream.start_recording()
                }
            case 6:
                if config.alarm == nil {
                    self.view.gestureRecognizers?.removeAll()
                    self.pushViewController(self.createAlarmConfig(), animated: true)
                }
                else {
                    config.alarm = nil
                }
            case 7:
                self.filtermenu()
            default:
                break
            }
        }
    }
    
}
