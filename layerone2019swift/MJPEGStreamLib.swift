// from https://github.com/WrathChaos/MJPEGStreamLib

import UIKit
import Vision
import GPUImage

open class MJPEGStreamLib: NSObject, URLSessionDataDelegate {
    
    fileprivate enum StreamStatus {
        case stop
        case loading
        case play
    }
    
    fileprivate var receivedData: NSMutableData?
    fileprivate var dataTask: URLSessionDataTask?
    fileprivate var session: Foundation.URLSession!
    fileprivate var status: StreamStatus = .stop
    
    open var authenticationHandler: ((URLAuthenticationChallenge) -> (Foundation.URLSession.AuthChallengeDisposition, URLCredential?))?
    open var didStartLoading: (()->Void)?
    open var didFinishLoading: (()->Void)?
    open var contentURL: URL?
    open var imageView: UIView
    open var image_outlet: Int
    open var laugh_face:UIImage
    open var laugh_banner:UIImage
    open var errors = 0;
    open var recording:Bool = false
    open var recordingPath:URL?
    open var recordingCounter:Int = 0
    open var recordingStarted:NSDate?
    var lastAlarmTrigger:AlarmTrigger?
    open var filter:String?
    open var lastrotate:Int?
    
    
    open var face_draw_layers = [CALayer]();
    
    var facedetector: FaceDetector
    
    public init(imageView: UIView) {
        self.facedetector = FaceDetector.init()
        self.imageView = imageView
        self.image_outlet = 1;
        laugh_face = UIImage(named:"laughingmanface")!;
        laugh_banner = UIImage(named:"laughingmantext")!;
        super.init()
        self.session = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        lastrotate = config.prerotate
        
    }
    
    public convenience init(imageView: UIView, contentURL: URL) {
        self.init(imageView: imageView)
        self.contentURL = contentURL
    }
    
    deinit {
        dataTask?.cancel()
    }
    
    func applyFilter(_ source: UIImage) -> UIImage {
        //incredibly inefficient
        if self.filter != nil {
            switch (self.filter){
            case "cartoon":
                return source.filterWithOperation(SmoothToonFilter())
            case "sketch":
                return source.filterWithOperation(SketchFilter())
            case "pixellate":
                return source.filterWithOperation(Pixellate())
            case "polkadot":
                return source.filterWithOperation(PolkaDot())
            case "halftone":
                return source.filterWithOperation(Halftone())
            case "cga":
                return source.filterWithOperation(CGAColorspaceFilter())
            case "solarize":
                return source.filterWithOperation(Solarize())
            default:
                return source
            }

        }
        return source
    }
    
    open func blankImageview() {
        let blank = UIImage.emptyImage(with: CGSize(width: 80, height: 80))
        DispatchQueue.main.async { self.imageView.layer.contents = blank!.cgImage;}
    }
    
    // Play function with url parameter
    open func play(url: URL){
        // Checking the status for it is already playing or not
        if status == .play || status == .loading {
            stop()
        }
        contentURL = url
        play()
    }
    
    open func setOutlet(_ mode: Int)
    {
        image_outlet = mode;
        imageView.layer.sublayers = nil
        face_draw_layers = [CALayer]()
    }
    
    open func setImageView(view: UIView){
        self.imageView = view;
        self.imageView.layer.zPosition = 99
    }
    
    open func getImageView() -> UIView {
        return self.imageView;
    }
    
    open func hideImageView() {
        self.imageView.isHidden = true
    }
    
    open func showImageView()
    {
        self.imageView.isHidden = false
    }

    func canAlarm() -> Bool {
        let alarm = config.alarm
        if alarm != nil {
            if lastAlarmTrigger != nil {
                let endoftrigger = (lastAlarmTrigger!.start) + lastAlarmTrigger!.period
                if endoftrigger.timeIntervalSinceNow <= -(config.alarm?.cooldown)! {
                    return true
                }
                return false
            }
            return true
        }
        return false
    }
    
    open func handleAlarm(faces: [VNFaceObservation], source: UIImage) {
        let alarm = config.alarm
        if alarm != nil {
            if faces.count >= alarm!.faces && recording == false {
                start_recording()
                let when = DispatchTime.now() + (alarm?.period)!
                DispatchQueue.main.asyncAfter(deadline: when){
                    self.stop_recording(nil,inst: nil)
                }

            }
        }
    }
    
    open func imageDispatch(source: UIImage)
    {
        // inefficient and bad
        if config.alarm != nil && image_outlet != 1 {
            if canAlarm(){
                facedetector.getFaces(for: source, complete: handleAlarm )
            }
        }
        
        
        switch (image_outlet){
            // eye highlight mode
            case 1:
                self.facedetector.showEye(for: source, complete: onNewImage)
            // face highlight mode
            case 2:
                stream.showImageView()
                self.facedetector.highlightFaces(for: source, complete: onNewImage)
            //passthru
            case 3:
                stream.showImageView()
                onNewImage(source: source)
            case 4:
                stream.showImageView()
                self.facedetector.getFaces(for: source, complete: drawLaugh )
            case 5:
                stream.showImageView()
                self.facedetector.drawFeatures(for: source, complete: onNewImage)
            default:
                break
        }
    }
    
    open func translateToView(view: CGRect, op: CGRect) -> CGRect {
        let x = op.minX * view.width
        let y = op.minY * view.height
        let width = op.size.width * view.width
        let height = op.size.height * view.height
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -view.size.height)
        return rect.applying(transform)
    }
    
    open func centerZoom(factor:CGFloat = 2.0, rect: CGRect) -> CGRect {
        var x:CGFloat
        var y:CGFloat
        var width:CGFloat
        var height:CGFloat
        
        if factor > 1.0 {
            x = rect.midX - rect.width/2 * factor
            y = rect.midY - rect.height/2 * factor
        }
        else {
            x = rect.midX + rect.width/2 * factor
            y = rect.midY + rect.height/2 * factor
        }
        width = rect.width * factor
        height = rect.height * factor
        return CGRect(x: x, y: y, width: width, height:height)
    }
    
    open func drawLaugh(faces: [VNFaceObservation], source: UIImage){
        if config.debug{
            var bg = source
            for i in faces{
                var landmarks = [VNFaceLandmarkRegion2D]()
                bg = facedetector.drawOnImage(source: bg,boundingRect: i.boundingBox, roiRect: i.boundingBox,faceLandmarkRegions: landmarks)
            }
            onNewImage(source: bg)
        }
        else{
            onNewImage(source: source)
        }
        var current = [CALayer]();
        for faceObservation in faces {
            if lastrotate != config.prerotate{
                lastrotate = config.prerotate
                face_draw_layers = [CALayer]()
            }
            var found = false;
            for layer in face_draw_layers {
                let newrect = translateToView(view:self.imageView.layer.frame , op: faceObservation.boundingBox)
                let centerpoint = CGPoint(x: newrect.midX, y: newrect.midY)
                if layer.frame.contains(centerpoint){
                    var placement = translateToView(view:self.imageView.layer.frame , op: faceObservation.boundingBox);
                    
                    if placement.width > placement.height {
                        let diff = placement.width-placement.height
                        placement = placement.insetBy(dx:0.0, dy:-(diff/2))
                    }
                    if placement.width < placement.height {
                        let diff = placement.height-placement.width
                        placement = placement.insetBy(dx:-(diff/2),dy:0.0)
                    }
                    
                    layer.frame = centerZoom(factor: 2.0, rect: placement);
                    
                    for i in layer.sublayers! {
                        switch (i.zPosition){
                        case 1:
                            var banx:CGFloat = 0
                            var bany:CGFloat = 0
                            
                            switch(config.prerotate)
                                {
                                case 1:
                                    banx = 0-(layer.frame.height*0.05)
                                    bany = 0-(layer.frame.width*0.085)
                                case 2:
                                    banx = 0-(layer.frame.width*0.015)
                                    bany = 0-(layer.frame.height*0.05)
                                case 3:
                                    bany = 0-(layer.frame.width*0.015)
                                    banx = 0-(layer.frame.height*0.05)
                                default:
                                    banx = 0-(layer.frame.width*0.085)
                                    bany = 0-(layer.frame.height*0.05)
                            }
                            i.frame = CGRect(x: banx,y:bany,width:layer.frame.width*1.1,height:layer.frame.height*1.1)
                        default:
                            i.frame = CGRect(x:0,y:0,width:layer.frame.width,height:layer.frame.height)
                        }
                    }
                    current.append(layer)
                    found = true;
                }
            }
            if !found {
                let newlayer = CALayer()
                let newbanner = CALayer()
                let overlayer = CALayer()
                var placement = translateToView(view:self.imageView.layer.frame , op: faceObservation.boundingBox);
                
                if placement.width > placement.height {
                    let diff = placement.width-placement.height
                    placement = placement.insetBy(dx:0.0, dy:-(diff/2))
                }
                if placement.width < placement.height {
                    let diff = placement.height-placement.width
                    placement = placement.insetBy(dx:-(diff/2),dy:0.0)
                }
                
                placement = centerZoom(factor: 2.0, rect: placement);
                overlayer.frame = placement
                if config!.prerotate != 0 {
                    newlayer.contents = laugh_face.imageRotatedByDegrees(degrees: CGFloat(90*config.prerotate), flip: false).cgImage
                }
                else {
                    newlayer.contents = laugh_face.cgImage;
                }
                
                newlayer.shouldRasterize = true;
                
                
                
                newlayer.frame = CGRect(x:0,y:0,width:overlayer.frame.width,height:overlayer.frame.height)
    
                var banx:CGFloat = 0
                var bany:CGFloat = 0
                
                switch(config.prerotate)
                {
                    case 1:
                        banx = 0-(overlayer.frame.height*0.05)
                        bany = 0-(overlayer.frame.width*0.085)
                    case 2:
                        banx = 0-(overlayer.frame.width*0.015)
                        bany = 0-(overlayer.frame.height*0.05)
                    case 3:
                        bany = 0-(overlayer.frame.width*0.015)
                        banx = 0-(overlayer.frame.height*0.05)
                    default:
                        banx = 0-(overlayer.frame.width*0.085)
                        bany = 0-(overlayer.frame.height*0.05)
                }
                newbanner.frame = CGRect(x:banx,y:bany,width:overlayer.frame.width*1.1,height:overlayer.frame.height*1.1)
                
                newbanner.contents = laugh_banner.cgImage
                let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
                rotate.fromValue = 0.0
                rotate.toValue = CGFloat(Double.pi * 2.0)
                rotate.duration = 4.0
                rotate.repeatCount = Float.infinity
                newbanner.add(rotate, forKey: nil)
                newbanner.zPosition = 1
                newlayer.zPosition = 2
                overlayer.addSublayer(newbanner)
                overlayer.addSublayer(newlayer)
                current.append(overlayer)
            }
        }
        face_draw_layers = current;
        imageView.layer.sublayers = nil;
        for layer in face_draw_layers {
            imageView.layer.addSublayer(layer)
        }
    }

    // Play function without URL parameter
    open func play() {
        guard let url = contentURL , status == .stop else {
            return
        }
        
        status = .loading
        DispatchQueue.main.async { self.didStartLoading?() }
        
        receivedData = NSMutableData()
        let request = URLRequest(url: url, timeoutInterval: 5.0)
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
    }
    
    
    // Stop the stream function
    open func stop(){
        status = .stop
        dataTask?.cancel()
    }
    
    open func errorHandler(data: Data?, response: URLResponse?, error: Error?)
    {
        if let unwrappedError = error {
            print(unwrappedError)
        }
    }
    
    // NSURLSessionDataDelegate
    
    open func onNewImage(source: UIImage){
        if self.filter != nil {
            DispatchQueue.main.async { self.imageView.layer.contents = self.applyFilter(source).cgImage }
        }
        else {
            DispatchQueue.main.async { self.imageView.layer.contents = source.cgImage; }
        }
        if self.recording {
            if recordingCounter == 0 {
                self.recordingStarted = NSDate()
            }
            recordingCounter += 1
            let path = recordingPath?.appendingPathComponent("\(recordingCounter).png")
            grab()!.save(path!)
        }
    }
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        // Controlling the imageData is not nil
        if let imageData = receivedData , imageData.length > 0,
            let receivedImage = UIImage(data: imageData as Data) {
            if status == .loading {
                status = .play
                DispatchQueue.main.async { self.didFinishLoading?() }
            }
            if config!.prerotate != 0 {
                DispatchQueue.main.async{ self.imageDispatch(source: receivedImage.imageRotatedByDegrees(degrees: CGFloat(90*config.prerotate), flip: false))}
            }
            else {
                DispatchQueue.main.async{ self.imageDispatch(source: receivedImage)}
            }
        }
        
        receivedData = NSMutableData()
        completionHandler(.allow)
    }
    
    open func grab() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.imageView.frame.size, false, 0.0)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
   
    open func save(_ f:Selector, inst:UIViewController) {
        let oneimage = UIImage(cgImage: self.imageView.layer.contents as! CGImage)
        guard let image = grab() else { return }
        DispatchQueue.main.async {UIImageWriteToSavedPhotosAlbum(image, inst, f , nil)}
    }
    
    
    
    open func start_recording()
    {
        self.recording = true
        let tmpdir = FileManager.default.temporaryDirectory
        let timeInterval = NSDate().timeIntervalSince1970
        self.recordingPath = tmpdir.appendingPathComponent(String(Int(timeInterval)))
        do {
            try FileManager.default.createDirectory(atPath: self.recordingPath!.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }
    
    open func stop_recording(_ f:Selector?, inst:UIViewController?)
    {
        var framecount:Int32 = 0
        self.recording = false
        self.recordingCounter = 0
        var files:[String]?
        do {
            files = try FileManager.default.contentsOfDirectory(atPath: (recordingPath?.path)!)
            framecount = Int32(files!.count)
        }
        catch let error as NSError
        {
            NSLog("Unable to count recording directory \(error.debugDescription)")
        }
        
        let end = NSDate()
        let duration: Double = end.timeIntervalSince(recordingStarted! as Date)
        let fps = Double(framecount)/duration

        if f == nil {
            self.lastAlarmTrigger = AlarmTrigger(period: (config.alarm?.period)!, start: recordingStarted! as Date)
        }
        
        self.recordingStarted = nil
        
        let first = UIImage(fileURLWithPath: (recordingPath?.appendingPathComponent("1.png"))!)
        
        let size:CGSize = first!.size
        var absofiles = [String]()
        for i in files!.sorted(by: { Int($0.replace(target: ".png",withString: ""))! < Int($1.replace(target: ".png",withString: ""))! }) {
            absofiles.append((recordingPath?.appendingPathComponent(i).absoluteString)!)
        }
        let videoBuilder = VideoBuilder(photoURLs: absofiles, size:size, fps: fps)
        videoBuilder.build({ progress in
           // print(progress)
        }, success: { url in
            UISaveVideoAtPathToSavedPhotosAlbum(
                url.path,
                inst,
                f,
                nil)
            self.cleanup_video()
        }, failure: { error in
            print(error)
            self.cleanup_video()
        })
    }
    
    fileprivate func cleanup_video() {
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: (recordingPath?.path)!)
            for filePath in filePaths {
                try FileManager.default.removeItem(atPath: (recordingPath?.appendingPathComponent(filePath).path)!)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
        recordingPath = nil

    }
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData?.append(data)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let unwrappedError = error {
            print(unwrappedError.localizedDescription)
            switch (unwrappedError.localizedDescription) {
            case "cancelled":
                 break
            default:
            // add to errors then restart
            errors+=1
            if errors >= config.error_tries{
                NotificationCenter.default.post(name: NSNotification.Name("badgeurlfailure"), object: nil)
                stop()
                errors = 0
            } else {
              stop()
              play()
            }
            }
        }
    }
    // NSURLSessionTaskDelegate
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        var credential: URLCredential?
        var disposition: Foundation.URLSession.AuthChallengeDisposition = .performDefaultHandling
        // Getting the authentication if stream asks it
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trust = challenge.protectionSpace.serverTrust {
                credential = URLCredential(trust: trust)
                disposition = .useCredential
            }
        } else if let onAuthentication = authenticationHandler {
            (disposition, credential) = onAuthentication(challenge)
        }
        
        completionHandler(disposition, credential)
    }
}
