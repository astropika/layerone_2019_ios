//
//  FullViewController.swift
//  layerone2019swift


import Foundation
import AVKit
import AVFoundation


class FullViewController: UIViewController {
    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    var staticplayer: AVPlayer!
    var staticavPlayerLayer: AVPlayerLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let staticpath = Bundle.main.path(forResource: "static", ofType:"mov") else {
            debugPrint("static.mov not found")
            return
        }
        let staticasset = AVAsset(url: URL(fileURLWithPath: staticpath))
        let staticplayerItem = AVPlayerItem(asset: staticasset)
        staticplayer = AVPlayer(playerItem: staticplayerItem)
        staticavPlayerLayer = AVPlayerLayer(player: staticplayer)
        staticavPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        staticplayer.actionAtItemEnd = .none
        staticplayer.volume = 0
        staticavPlayerLayer.frame = UIScreen.main.bounds
        staticavPlayerLayer.masksToBounds = true;
        
        view.layer.insertSublayer(staticavPlayerLayer, at: 1)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(staticPlayerItemDidReachEnd(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: staticplayer.currentItem)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(gothold))
        view.addGestureRecognizer(longPressRecognizer)
        if stream == nil {
            if config.badge_url.isEmpty {
                NotificationCenter.default.post(name: NSNotification.Name("badgeurlfailure"), object: nil)
            }
            // Set the ImageView to the stream object
            stream = MJPEGStreamLib(imageView: imageView)
            let url = URL(string: config.badge_url)
            stream.contentURL = url
            stream.play() // Play the stream
        }
        stream.setImageView(view: imageView)
        stream.image_outlet = 3;
        stream.hideImageView()
    }
    @objc func staticPlayerItemDidReachEnd(notification: Notification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: CMTime.zero, completionHandler: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        stream.setImageView(view: imageView)
        staticplayer.play()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func gothold(sender: UILongPressGestureRecognizer) {
        showMenuDialog(actionTitle:[1:"Laugh", 2:"Features", 3:"Highlight", 4: "Eye",5:"Nothing"]) {
            (input:Int?) in
            switch (input){
            // eye highlight mode
            case 1:
                stream.setOutlet(4)
            case 2:
                stream.setOutlet(5)
            case 3:
                stream.setOutlet(2)
            case 4:
                stream.setOutlet(1)
            case 5:
                stream.setOutlet(3)
            default:
                break
            }
        }

    }
}
