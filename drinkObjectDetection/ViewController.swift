//
//  ViewController.swift
//  drinkObjectDetection
//
//  Created by 심정민 on 2023/10/29.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate  {

    var audioPlayer: AVAudioPlayer?
    let welchs_url = Bundle.main.url(forResource:"웰치스포도맛",withExtension: "mp3")
    let gatolei_url = Bundle.main.url(forResource:"게토레이",withExtension: "mp3")
    let milkis_url = Bundle.main.url(forResource:"밀키스",withExtension: "mp3")
    let letsbe_url = Bundle.main.url(forResource:"레쓰비",withExtension: "mp3")
    let sprite_url = Bundle.main.url(forResource:"스프라이트",withExtension: "mp3")
    let fantaorange_url = Bundle.main.url(forResource:"환타오렌지맛",withExtension: "mp3")
    let cocacola_url = Bundle.main.url(forResource:"코카콜라",withExtension: "mp3")
    let pocarisweat_url = Bundle.main.url(forResource:"포카리스웨트",withExtension: "mp3")
    let janchijipsikhye_url = Bundle.main.url(forResource:"잔치집식혜",withExtension: "mp3")
    let galamandeunbae_url = Bundle.main.url(forResource:"갈아만든배",withExtension: "mp3")
    
    
    var captureSession = AVCaptureSession()
    var previewView = UIImageView()
    var previewLayer:AVCaptureVideoPreviewLayer!
    var videoOutput:AVCaptureVideoDataOutput!
    var frameCounter = 0
    var frameInterval = 1
    var videoSize = CGSize.zero
    let colors:[UIColor] = {
        var colorSet:[UIColor] = []
        for _ in 0...80 {
            let color = UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1)
            colorSet.append(color)
        }
        return colorSet
    }()
    let ciContext = CIContext()
    var classes:[String] = []
    
    lazy var yoloRequest:VNCoreMLRequest! = {
        do {
            let model = try drinkModel().model
            guard let classes = model.modelDescription.classLabels as? [String] else {
                fatalError()
            }
            self.classes = classes
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            return request
        } catch let error {
            fatalError("mlmodel error.")
        }
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideo()
        
    }
    func setupVideo(){
        previewView.frame = view.bounds
        view.addSubview(previewView)

        captureSession.beginConfiguration()

        let device = AVCaptureDevice.default(for: AVMediaType.video)
        let deviceInput = try! AVCaptureDeviceInput(device: device!)

        captureSession.addInput(deviceInput)
        videoOutput = AVCaptureVideoDataOutput()

        let queue = DispatchQueue(label: "VideoQueue")
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        captureSession.addOutput(videoOutput)
        if let videoConnection = videoOutput.connection(with: .video) {
            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = .portrait
            }
        }
        captureSession.commitConfiguration()

//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer?.frame = previewView.bounds
//        previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
//        previewView.layer.addSublayer(previewLayer!)
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func detection(pixelBuffer: CVPixelBuffer) -> UIImage? {
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
            try handler.perform([yoloRequest])
            guard let results = yoloRequest.results as? [VNRecognizedObjectObservation] else {
                return nil
            }
            var detections:[Detection] = []
            for result in results {
                let flippedBox = CGRect(x: result.boundingBox.minX, y: 1 - result.boundingBox.maxY, width: result.boundingBox.width, height: result.boundingBox.height)
                let box = VNImageRectForNormalizedRect(flippedBox, Int(videoSize.width), Int(videoSize.height))

                guard let label = result.labels.first?.identifier as? String,
                        let colorIndex = classes.firstIndex(of: label) else {
                        return nil
                }
            
                let detection = Detection(box: box, confidence: result.confidence, label: label, color: colors[colorIndex])
                detections.append(detection)
            }
            let drawImage = drawRectsOnImage(detections, pixelBuffer)
        
            
            return drawImage
        } catch _ {
            return nil
            
        }
    }
    
    func drawRectsOnImage(_ detections: [Detection], _ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
        let size = ciImage.extent.size
        guard let cgContext = CGContext(data: nil,
                                        width: Int(size.width),
                                        height: Int(size.height),
                                        bitsPerComponent: 8,
                                        bytesPerRow: 4 * Int(size.width),
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
        for detection in detections {
            let invertedBox = CGRect(x: detection.box.minX, y: size.height - detection.box.maxY, width: detection.box.width, height: detection.box.height)
            if let labelText = detection.label {
                cgContext.textMatrix = .identity
            
                var drinkName = labelText
                if drinkName == "letsbe" {
                   drinkName = "레쓰비"
                }
                if drinkName == "galamandeunbae" {
                   drinkName = "갈아만든배"
                }
                if drinkName == "sprite" {
                   drinkName = "스프라이트"
                }
                if drinkName == "welchsgrape" {
                   drinkName = "웰치스포도맛"
                }
                if drinkName == "cocacola" {
                   drinkName = "코카콜라"
                }
                if drinkName == "pocarisweat" {
                   drinkName = "포카리스웨트"
                }
                if drinkName == "fantaorange" {
                   drinkName = "환타오렌지"
                }
                if drinkName == "gatolei" {
                   drinkName = "게토레이"
                }
                if drinkName == "milkis" {
                   drinkName = "밀키스"
                }
                if drinkName == "janchijipsikhye" {
                   drinkName = "잔치집식혜"
                }
                
                
                //let text = "\(labelText) : \(round(detection.confidence*100))"
                let text = "\(drinkName) : \(round(detection.confidence*100))"
                
                let textRect  = CGRect(x: invertedBox.minX + size.width * 0.01, y: invertedBox.minY - size.width * 0.01, width: invertedBox.width, height: invertedBox.height)
                let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                
                let textFontAttributes = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: textRect.width * 0.1, weight: .bold),
                    NSAttributedString.Key.foregroundColor: detection.color,
                    NSAttributedString.Key.paragraphStyle: textStyle
                ]
                
                cgContext.saveGState()
                defer { cgContext.restoreGState() }
                let astr = NSAttributedString(string: text, attributes: textFontAttributes)
                let setter = CTFramesetterCreateWithAttributedString(astr)
                let path = CGPath(rect: textRect, transform: nil)
                
                let frame = CTFramesetterCreateFrame(setter, CFRange(), path, nil)
                cgContext.textMatrix = CGAffineTransform.identity
                CTFrameDraw(frame, cgContext)
                
                cgContext.setStrokeColor(detection.color.cgColor)
                cgContext.setLineWidth(9)
                cgContext.stroke(invertedBox)
                
                
                //
                switch labelText {
                case "welchsgrape":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: welchs_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "cocacola":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: cocacola_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "fantaorange":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: fantaorange_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "galamandeunbae":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: galamandeunbae_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "gatolei":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: gatolei_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "janchijipsikhye":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: janchijipsikhye_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "letsbe":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: letsbe_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "milkis":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: milkis_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "pocarisweat":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: pocarisweat_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                case "sprite":
                    if detection.confidence*100 >= 85 {
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: sprite_url!)
                            audioPlayer?.play()
                            sleep(1)
                        } catch{
                            print(error)
                        }
                        
                    }
                    break;
                default : break;
                }
                
            }
        }
        
        guard let newImage = cgContext.makeImage() else { return nil }
        return UIImage(ciImage: CIImage(cgImage: newImage))
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCounter += 1
        if videoSize == CGSize.zero {
            guard let width = sampleBuffer.formatDescription?.dimensions.width,
                  let height = sampleBuffer.formatDescription?.dimensions.height else {
                fatalError()
            }
            videoSize = CGSize(width: CGFloat(width), height: CGFloat(height))
        }
        if frameCounter == frameInterval {
            frameCounter = 0
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            guard let drawImage = detection(pixelBuffer: pixelBuffer) else {
                return
            }
            DispatchQueue.main.async {
                self.previewView.image = drawImage
            }
            
            
        }

    }

}

struct Detection {
    let box: CGRect
    let confidence: Float
    let label: String?
    let color: UIColor
}




