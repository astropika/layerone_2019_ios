//
//  ViewController.swift

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    var player: AVPlayer!
    var avPlayerLayer: AVPlayerLayer!
    var url: URL?
    var pushed:Bool?

    var staticplayer: AVPlayer!
    var staticavPlayerLayer: AVPlayerLayer!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let path = Bundle.main.path(forResource: "vk", ofType:"mp4") else {
            debugPrint("vk.mp4 not found")
            return
        }
        guard let staticpath = Bundle.main.path(forResource: "static", ofType:"mov") else {
            debugPrint("static.mov not found")
            return
        }

        
        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        avPlayerLayer = AVPlayerLayer(player: player)
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        player.actionAtItemEnd = .none
        player.volume = 0
        avPlayerLayer.frame = view.layer.bounds
        view.backgroundColor = .clear
        view.layer.insertSublayer(avPlayerLayer, at: 0)
        scalingFactor()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
        
        
        let staticasset = AVAsset(url: URL(fileURLWithPath: staticpath))
        let staticplayerItem = AVPlayerItem(asset: staticasset)
        staticplayer = AVPlayer(playerItem: staticplayerItem)
        staticavPlayerLayer = AVPlayerLayer(player: staticplayer)
        staticavPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        staticplayer.actionAtItemEnd = .none
        staticplayer.volume = 0
        staticavPlayerLayer.frame = getScalingFactor()
        staticavPlayerLayer.cornerRadius = 4;
        staticavPlayerLayer.masksToBounds = true;

        view.layer.insertSublayer(staticavPlayerLayer, at: 1)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(staticPlayerItemDidReachEnd(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: staticplayer.currentItem)

        
        print("viewcontroller being inited")
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
        stream.image_outlet = 1;
        stream.hideImageView()
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: CMTime.zero, completionHandler: nil)
        scalingFactor()
    }
    
    @objc func staticPlayerItemDidReachEnd(notification: Notification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: CMTime.zero, completionHandler: nil)
    }

    
    func scalingFactor() {
        var vrect = UIScreen.main.bounds
        var widthfactor = (vrect.size.width / 1920)
        var heightfactor = (vrect.size.height / 1080)
        print("Heightfactor: \(heightfactor) widthFactor: \(widthfactor)")
        // 1080p origin 840:210
        //1080p width 730
        //1080p height 511
        imageView.left = (835*widthfactor)
        imageView.top = (360 * heightfactor)
        imageView.width = (735 * widthfactor)
        imageView.height = (515 * heightfactor)
        imageView.layer.cornerRadius = 4;
        imageView.layer.masksToBounds = true;
    }
    
    func getScalingFactor() -> CGRect {
        var vrect = UIScreen.main.bounds
        var widthfactor = (vrect.size.width / 1920)
        var heightfactor = (vrect.size.height / 1080)
        print("Heightfactor: \(heightfactor) widthFactor: \(widthfactor)")
        // 1080p origin 840:210
        //1080p width 730
        //1080p height 511
        let outrect = CGRect(x: (835*widthfactor), y: (360 * heightfactor), width: (735 * widthfactor), height: (515 * heightfactor))
        return outrect
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        stream.setImageView(view: imageView)
        stream.image_outlet = 1;
        player.play()
        staticplayer.play()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    

    
    // Make the Status Bar Light/Dark Content for this View
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
}
