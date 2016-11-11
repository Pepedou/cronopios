//
//  SinglePageViewController.swift
//  CronopiOS
//
//  Created by José Luis Valencia Herrera on 01/11/16.
//  Copyright © 2016 José Luis Valencia Herrera. All rights reserved.
//

import UIKit


class SinglePageViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var bookPage: BookPage!
    
    private var pageImageView: UIImageView!
    private var saveIconView: UIImageView!
    private var cloudIconView: UIImageView!
    private var overlayImage: UIImage!
    private var content: UITextView!
    private var activityIndicator: UIActivityIndicatorView!
    
    private var isKeyboardVisible: Bool = false
    private var keyboardAnimationDuration: NSNumber!
    private var keyboardHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view = ((Bundle.main.loadNibNamed("PageView", owner: self, options: nil)?[0] as? UIView)!)
        
        NotificationCenter.default.addObserver(self, selector:#selector(SinglePageViewController.keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(SinglePageViewController.keyboardWillDisappear), name: .UIKeyboardWillHide, object: nil)
                
        for subview in self.view.subviews {
            if subview.isKind(of: UILabel.self) {
                (subview as! UILabel).text = self.bookPage.pageTitle
            }
            else if subview.isKind(of: UIImageView.self) {
                let imageView = (subview as! UIImageView)
                imageView.isUserInteractionEnabled = true

                switch imageView.tag {
                case 0:
                    let singleTap = UITapGestureRecognizer(target: self, action: #selector(SinglePageViewController.onImageTap))
                    singleTap.numberOfTapsRequired = 1
                    imageView.addGestureRecognizer(singleTap)
                    imageView.image = bookPage?.pageImage
                    overlayImage = imageView.image
                    self.pageImageView = imageView
                case 1:
                    let singleTap = UITapGestureRecognizer(target: self, action: #selector(SinglePageViewController.savePage))
                    singleTap.numberOfTapsRequired = 1
                    imageView.addGestureRecognizer(singleTap)
                    self.cloudIconView = imageView
                case 2:
                    let singleTap = UITapGestureRecognizer(target: self, action: #selector(SinglePageViewController.saveImageToDevice))
                    singleTap.numberOfTapsRequired = 1
                    imageView.addGestureRecognizer(singleTap)
                    self.saveIconView = imageView
                default:
                    continue
                }

            }
            else if subview.isKind(of: UITextView.self) {
                let contentLabel = (subview as! UITextView)
                contentLabel.text = self.bookPage.pageContent

                self.content = contentLabel
            }
            else if subview.isKind(of: UIActivityIndicatorView.self) {
                self.activityIndicator = (subview as! UIActivityIndicatorView)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bookPage.pageContent = self.content.text
        self.bookPage.pageImage = self.pageImageView.image!
    }
    
    func onImageTap() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        if self.isKeyboardVisible == false {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                imagePicker.cameraCaptureMode = .photo
                imagePicker.cameraDevice = .rear
                
                let screenSize = UIScreen.main.bounds.size
                let cameraAspectRatio = CGFloat(4.0 / 3.0)
                let imageHeight = CGFloat(screenSize.width * cameraAspectRatio)
                var verticalAdjustment = CGFloat()
                
                if (screenSize.height - imageHeight > 54.0) {
                    verticalAdjustment = CGFloat((screenSize.height - imageHeight) / 2.0)
                    verticalAdjustment /= CGFloat(2.0);
                    verticalAdjustment += CGFloat(2.0)
                }
                
                let cameraFrame = imagePicker.view.frame
                let cameraOrigin = imagePicker.view.frame.origin
                
                let overlayView = OverlayView(frame: CGRect(x: cameraOrigin.x, y: cameraOrigin.y + verticalAdjustment, width: cameraFrame.width / 2.0, height: imageHeight))
                
                if (self.overlayImage != nil) {
                    overlayView.setImage(image: self.overlayImage!)
                }
                
                imagePicker.cameraOverlayView = overlayView
                
                present(imagePicker, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "¡Ups!", message: "El dispositivo no cuenta con cámara.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ni hablar", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
        else {
            self.onEditingEnd()
        }
        
    }
    
    func onEditingEnd() {
        if self.content.text != self.bookPage.pageContent {
            self.saveIconView.isUserInteractionEnabled = true
        }
        
        self.content.endEditing(true)
        self.animateContent(up: false)
    }
    
    func keyboardWillAppear(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
            let keyboardHeight = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.height
            
            self.keyboardAnimationDuration = animationDuration
            self.keyboardHeight = keyboardHeight
            self.animateContent(up: true)
            
            self.isKeyboardVisible = true
        }
    }
    
    func keyboardWillDisappear() {
        self.isKeyboardVisible = false
    }
    
    func animateContent(up: Bool) {
        var movement = self.keyboardHeight!
        
        if up {
            movement *= CGFloat(-1.0)
        }
        
        UIView.animate(withDuration: self.keyboardAnimationDuration as TimeInterval, animations: {
            let frame = self.view.frame
            self.view.frame = CGRect(x: frame.origin.x, y: frame.origin.y + CGFloat(movement), width: frame.size.width, height: frame.size.height)
            
        }, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if picker.sourceType == .camera
        {
            var chosenImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            let overlayImage = self.pageImageView.image
            
            let targetSize = (chosenImage?.size)!
            let targetRect = CGRect(x: 0.0, y: 0.0, width: targetSize.width, height: targetSize.height)
            let overlayRect = CGRect(x: 0.0, y: 0.0, width: targetSize.width / 2.0, height: targetSize.height)
            
            let croppedImage = self.cropImage(imageToCrop: overlayImage!, rect: overlayRect, fullRect: targetRect)
            
            UIGraphicsBeginImageContext(targetSize)
            
            let context = UIGraphicsGetCurrentContext()
            
            UIGraphicsPushContext(context!)
            
            if picker.cameraDevice == .front
            {
                chosenImage = UIImage(cgImage: (chosenImage?.cgImage)!, scale: 1.0, orientation: .leftMirrored)
            }
            
            chosenImage?.draw(in: targetRect)
            croppedImage?.draw(in: overlayRect)
            
            UIGraphicsPopContext()
            
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            self.pageImageView.image = renderedImage
            self.saveIconView.isUserInteractionEnabled = true
        }
        else
        {
            self.overlayImage = info[UIImagePickerControllerEditedImage] as? UIImage
            self.pageImageView.image = self.overlayImage
            self.saveIconView.isUserInteractionEnabled = false
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func cropImage(imageToCrop: UIImage, rect: CGRect, fullRect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContext(rect.size)
        
        let currentContext = UIGraphicsGetCurrentContext()
        
        UIGraphicsPushContext(currentContext!)
        
        imageToCrop.draw(in: fullRect)
        
        UIGraphicsPopContext()
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil )
    }
    
    func savePage() {
        if self.isKeyboardVisible == false {
            self.bookPage.pageContent = self.content.text
            self.bookPage.pageImage = self.pageImageView.image!
            self.updateRemoteBookPage()
        }
        else {
            self.onEditingEnd()
        }
    }
    
    func updateRemoteBookPage() {
        let bookUpdater = BookPageUpdater()
        
        self.activityIndicator.startAnimating()
        
        bookUpdater.updateBookPage(bookPage: self.bookPage, completion: {(success: Bool) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                if success {
                    let alert = UIAlertController(title: "¡Éxito!", message: "Página almacenada en el servidor.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "¡A todo dar, mano!", style: .default, handler: nil))
                    
                    self.activityIndicator.stopAnimating()
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let alert = UIAlertController(title: "Error", message: "No se pudo sincronizar la página en el servidor. Intenta nuevamente.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Rayos...", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            })
        })
    }
    
    func saveImageToDevice() {
        if self.isKeyboardVisible == false {
        UIImageWriteToSavedPhotosAlbum(self.pageImageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        else {
            self.onEditingEnd()
        }
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        guard error == nil else {
            let alert = UIAlertController(title: "¡Ups!", message: "No se pudo guardar la imagen en la biblioteca.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ni modo", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            self.saveIconView.isUserInteractionEnabled = true
            
            return
        }
        
        let alert = UIAlertController(title: "¡Éxito!", message: "Imagen guardada en la biblioteca.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "¡Genial!", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        self.saveIconView.isUserInteractionEnabled = false
        
        return
    }
}

