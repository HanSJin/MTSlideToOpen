//
//  MTSlideToOpenView.swift
//  driver
//
//  Created by SJin Han on 2021/09/08.
//

import UIKit

@objc public protocol MTSlideToOpenDelegate {
    func mtSlideToOpenDelegateDidFinish(_ sender: MTSlideToOpenView)
}

@objcMembers public class MTSlideToOpenView: UIView {
    // MARK: All Views
    public let animatedMaskLabel = AnimatedMaskLabel()
    public let sliderTextLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    public let thumnailImageView: UIImageView = {
        let view = MTRoundImageView()
        view.isUserInteractionEnabled = true
        view.contentMode = .center
        return view
    }()
    public let sliderHolderView: UIView = {
        let view = UIView()
        return view
    }()
    public let draggedView: UIView = {
        let view = UIView()
        return view
    }()
    public let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: properties
    public weak var delegate: MTSlideToOpenDelegate?
    public var animationVelocity: Double = 0.2
    public var sliderViewTopDistance: CGFloat = 8.0 {
        didSet {
            topSliderConstraint?.constant = sliderViewTopDistance
            layoutIfNeeded()
        }
    }
    public var thumbnailViewTopDistance: CGFloat = 0.0 {
        didSet {
            topThumbnailViewConstraint?.constant = thumbnailViewTopDistance
            layoutIfNeeded()
        }
    }
    public var thumbnailViewStartingDistance: CGFloat = 0.0 {
        didSet {
            leadingThumbnailViewConstraint?.constant = thumbnailViewStartingDistance
            trailingDraggedViewConstraint?.constant = thumbnailViewStartingDistance
            setNeedsLayout()
        }
    }
    public var textLabelLeadingDistance: CGFloat = 0 {
        didSet {
            leadingTextLabelConstraint?.constant = textLabelLeadingDistance
            setNeedsLayout()
        }
    }
    public var isEnabled:Bool = true {
        didSet {
            animationChangedEnabledBlock?(isEnabled)
            animatedMaskLabel.isEnabled = isEnabled
        }
    }
    public var showSliderText:Bool = false {
        didSet {
            sliderTextLabel.isHidden = !showSliderText
        }
    }
    public var animationChangedEnabledBlock:((Bool) -> Void)?
    
    // MARK: Default styles
    public var sliderCornerRadius: CGFloat = 30.0 {
        didSet {
            sliderHolderView.layer.cornerRadius = sliderCornerRadius
            draggedView.layer.cornerRadius = sliderCornerRadius
        }
    }
    public var sliderBackgroundColor: UIColor = UIColor(red:0.1, green:0.61, blue:0.84, alpha:0.1) {
        didSet {
            sliderHolderView.backgroundColor = sliderBackgroundColor
            sliderTextLabel.textColor = sliderBackgroundColor
        }
    }
    
    public var textColor:UIColor = UIColor(red:25.0/255, green:155.0/255, blue:215.0/255, alpha:0.7) {
        didSet {
            animatedMaskLabel.textColor = textColor
            sliderTextLabel.text = labelText
        }
    }
    
    public var slidingColor:UIColor = UIColor(red:25.0/255, green:155.0/255, blue:215.0/255, alpha:0.7) {
        didSet {
            draggedView.backgroundColor = slidingColor
        }
    }
    public var thumbnailColor:UIColor = UIColor(red:25.0/255, green:155.0/255, blue:215.0/255, alpha:1) {
        didSet {
            thumnailImageView.backgroundColor = thumbnailColor
        }
    }
    public var labelText: String = "Swipe to open" {
        didSet {
            animatedMaskLabel.text = labelText
            sliderTextLabel.text = labelText
        }
    }
    public var textFont: UIFont = UIFont.systemFont(ofSize: 15.0) {
        didSet {
            animatedMaskLabel.font = textFont
            sliderTextLabel.font = textFont
        }
    }
    // 드래깅과 함께 animatedMaskLabel 이 투명해짐
    public var transparentAnimatedMaskLabel = true
    
    // MARK: Private Properties
    private var leadingThumbnailViewConstraint: NSLayoutConstraint?
    private var leadingTextLabelConstraint: NSLayoutConstraint?
    private var topSliderConstraint: NSLayoutConstraint?
    private var topThumbnailViewConstraint: NSLayoutConstraint?
    private var trailingDraggedViewConstraint: NSLayoutConstraint?
    private var xPositionInThumbnailView: CGFloat = 0
    private var xEndingPoint: CGFloat {
        get {
            return (self.containerView.frame.maxX - thumnailImageView.bounds.width - thumbnailViewStartingDistance)
        }
    }
    private var isFinished: Bool = false
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }
    
    private func setupView() {
        self.addSubview(containerView)
        containerView.addSubview(thumnailImageView)
        containerView.addSubview(sliderHolderView)
        containerView.addSubview(draggedView)
        draggedView.addSubview(sliderTextLabel)
        sliderHolderView.addSubview(animatedMaskLabel)
        containerView.bringSubviewToFront(self.thumnailImageView)
        setupConstraint()
        setStyle()
        // Add pan gesture
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        thumnailImageView.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func setupConstraint() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        thumnailImageView.translatesAutoresizingMaskIntoConstraints = false
        sliderHolderView.translatesAutoresizingMaskIntoConstraints = false
        animatedMaskLabel.translatesAutoresizingMaskIntoConstraints = false
        sliderTextLabel.translatesAutoresizingMaskIntoConstraints = false
        draggedView.translatesAutoresizingMaskIntoConstraints = false
        // Setup for view
        containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        // Setup for circle View
        leadingThumbnailViewConstraint = thumnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        leadingThumbnailViewConstraint?.isActive = true
        topThumbnailViewConstraint = thumnailImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: thumbnailViewTopDistance)
        topThumbnailViewConstraint?.isActive = true
        thumnailImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        thumnailImageView.heightAnchor.constraint(equalTo: thumnailImageView.widthAnchor).isActive = true
        // Setup for slider holder view
        topSliderConstraint = sliderHolderView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: sliderViewTopDistance)
        topSliderConstraint?.isActive = true
        sliderHolderView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sliderHolderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        sliderHolderView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        // Setup for textLabel
        animatedMaskLabel.topAnchor.constraint(equalTo: sliderHolderView.topAnchor).isActive = true
        animatedMaskLabel.centerYAnchor.constraint(equalTo: sliderHolderView.centerYAnchor).isActive = true
        leadingTextLabelConstraint = animatedMaskLabel.leadingAnchor.constraint(equalTo: sliderHolderView.leadingAnchor, constant: textLabelLeadingDistance)
        leadingTextLabelConstraint?.isActive = true
        animatedMaskLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: CGFloat(-8)).isActive = true
        // Setup for sliderTextLabel
        sliderTextLabel.topAnchor.constraint(equalTo: animatedMaskLabel.topAnchor).isActive = true
        sliderTextLabel.centerYAnchor.constraint(equalTo: animatedMaskLabel.centerYAnchor).isActive = true
        sliderTextLabel.leadingAnchor.constraint(equalTo: animatedMaskLabel.leadingAnchor).isActive = true
        sliderTextLabel.trailingAnchor.constraint(equalTo: animatedMaskLabel.trailingAnchor).isActive = true
        // Setup for Dragged View
        draggedView.leadingAnchor.constraint(equalTo: sliderHolderView.leadingAnchor).isActive = true
        draggedView.topAnchor.constraint(equalTo: sliderHolderView.topAnchor).isActive = true
        draggedView.centerYAnchor.constraint(equalTo: sliderHolderView.centerYAnchor).isActive = true
        trailingDraggedViewConstraint = draggedView.trailingAnchor.constraint(equalTo: thumnailImageView.trailingAnchor, constant: thumbnailViewStartingDistance)
        trailingDraggedViewConstraint?.isActive = true
    }
    
    private func setStyle() {
        thumnailImageView.backgroundColor = thumbnailColor
        animatedMaskLabel.text = labelText
        animatedMaskLabel.font = textFont
        animatedMaskLabel.textColor = textColor
        animatedMaskLabel.textAlignment = .center

        sliderTextLabel.text = labelText
        sliderTextLabel.font = textFont
        sliderTextLabel.textColor = sliderBackgroundColor
        sliderTextLabel.textAlignment = .center
        sliderTextLabel.isHidden = !showSliderText
        
        if isOnRightToLeftLanguage() {
            animatedMaskLabel.mt_flipView()
            sliderTextLabel.mt_flipView()
        }

        sliderHolderView.backgroundColor = sliderBackgroundColor
        sliderHolderView.layer.cornerRadius = sliderCornerRadius
        draggedView.backgroundColor = slidingColor
        draggedView.layer.cornerRadius = sliderCornerRadius
        draggedView.clipsToBounds = true
        draggedView.layer.masksToBounds = true
    }
    
    private func isTapOnThumbnailViewWithPoint(_ point: CGPoint) -> Bool{
        return self.thumnailImageView.frame.contains(point)
    }
    
    private func updateThumbnailXPosition(_ x: CGFloat, _ animated: Bool = false) {
        leadingThumbnailViewConstraint?.constant = x
        setNeedsLayout()
    }
    
    // MARK: UIPanGestureRecognizer
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        if isFinished || !isEnabled {
            return
        }
        let translatedPoint = sender.translation(in: containerView).x * (self.isOnRightToLeftLanguage() ? -1 : 1)
        switch sender.state {
        case .began:
            break
        case .changed:
            if translatedPoint >= xEndingPoint {
                updateThumbnailXPosition(xEndingPoint)
                return
            }
            if translatedPoint <= thumbnailViewStartingDistance {
                animatedMaskLabel.alpha = 1
                updateThumbnailXPosition(thumbnailViewStartingDistance)
                return
            }
            updateThumbnailXPosition(translatedPoint)
            animatedMaskLabel.alpha = transparentAnimatedMaskLabel ? (xEndingPoint - translatedPoint) / xEndingPoint : 1
            break
        case .ended:
            let velocity = sender.velocity(in: containerView).x
            let velocityWeight: CGFloat = velocity > 100 ? 0.7 : 0.9
            
            if translatedPoint >= xEndingPoint * velocityWeight {
                animatedMaskLabel.alpha = transparentAnimatedMaskLabel ? 0 : 1
                updateThumbnailXPosition(xEndingPoint)
                
                // Finish action
                isFinished = true
                delegate?.mtSlideToOpenDelegateDidFinish(self)
                
                UIView.animate(withDuration: animationVelocity) {
                    self.leadingThumbnailViewConstraint?.constant = (self.xEndingPoint)
                    self.layoutIfNeeded()
                }
                return
            }
            if translatedPoint <= thumbnailViewStartingDistance {
                animatedMaskLabel.alpha = 1
                updateThumbnailXPosition(thumbnailViewStartingDistance)
                return
            }
            UIView.animate(withDuration: animationVelocity) {
                self.leadingThumbnailViewConstraint?.constant = self.thumbnailViewStartingDistance
                self.animatedMaskLabel.alpha = 1
                self.layoutIfNeeded()
            }
            break
        default:
            break
        }
    }
    
    // Others
    public func resetStateWithAnimation(_ animated: Bool) {
        let action = {
            self.leadingThumbnailViewConstraint?.constant = self.thumbnailViewStartingDistance
            self.animatedMaskLabel.alpha = 1
            self.layoutIfNeeded()
            //
            self.isFinished = false
        }
        if animated {
            UIView.animate(withDuration: animationVelocity) {
               action()
            }
        } else {
            action()
        }
    }
    
    // MARK: Helpers
    
    func isOnRightToLeftLanguage() -> Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }
}

extension UIView {
   func mt_flipView() {
       self.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
   }
}

class MTRoundImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let radius: CGFloat = self.bounds.size.width / 2.0
        self.layer.cornerRadius = radius
    }
}
