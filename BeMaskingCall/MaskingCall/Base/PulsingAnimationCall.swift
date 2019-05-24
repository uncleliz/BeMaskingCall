//
//  PulsingAnimationCall.swift
//  CircularLoaderLBTA
//
//  Created by manh.le on 5/8/19.
//  Copyright © 2019 Lets Build That App. All rights reserved.
//

import UIKit
@objcMembers
public class PulsingAnimationCall: CAReplicatorLayer, CAAnimationDelegate
{
//    var pulsatingLayer: CAShapeLayer!
    var affect:CALayer!
    var prevSuperlayer:CALayer!
    var prevLayerIndex: UInt32 = 0
    var prevAnimation: CAAnimation!
    var shouldResume: Bool = false
    var animationGroup: CAAnimationGroup!
    var _animationDuration: CFTimeInterval!
    var animationDuration: CFTimeInterval!
    {
        get {
            return _animationDuration
        }
        set
        {
            _animationDuration = newValue
            self.instanceDelay = (_animationDuration + _pulseInterval)/Double(_layerNumber)
        }
    }
    var keyTimeForHalfOpacity: CFTimeInterval!
    var fromValueForRadius: CGFloat!
    var _layerNumber: NSInteger! = 0
    var layerNumber: NSInteger
    {
        get{
            return _layerNumber
        }
        set{
            _layerNumber = newValue
            self.instanceCount = _layerNumber
            self.instanceDelay = (animationDuration + pulseInterval)/Double(_layerNumber)
        }
    }
    var _radius: CGFloat!
    var radius: CGFloat
    {
        get{
            return _radius
        }
        set
        {
            _radius = newValue
            let diameter = _radius*2
            self.affect.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            self.affect.cornerRadius = _radius
        }
    }
    var _pulseInterval: CFTimeInterval! = 0.0
    var pulseInterval: CFTimeInterval!
    {
        get
        {
            return _pulseInterval
        }
        set
        {
            _pulseInterval = newValue
            affect.removeAnimation(forKey: "pulse")
        }
    }
    var _startInterval: TimeInterval!
    var startInterval: TimeInterval!
    {
        get {
            return _startInterval
        }
        set{
            _startInterval = newValue
            self.instanceDelay = _startInterval
        }
    }
    override public var backgroundColor: CGColor?
    {
        get{
            return super.backgroundColor
        }
        set{
            super.backgroundColor = newValue
            affect.backgroundColor = newValue
        }
    }
    override public var repeatCount: Float
    {
        get
        {
            return super.repeatCount
        }
        set{
            super.repeatCount = newValue
            if animationGroup != nil {
                animationGroup.repeatCount = newValue
            }
        }
    }
    override init() {
        super.init()
        affect = CALayer()
        affect.contentsScale = UIScreen.main.scale
        affect.opacity = 0
        addSublayer(affect)
        
        setupDefault()
        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(onDidEnterBackground),
//                                               name: NSNotification.Name.UIApplication.didEnterBackgroundNotification,
//                                               object: nil)
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(onWillEnterForeground),
//                                               name: NSNotification.Name.UIApplication.willEnterForegroundNotification,
//                                               object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupDefault()
    {
        shouldResume = true
        animationDuration = 3
        keyTimeForHalfOpacity = 0.2
        _pulseInterval = 0
        fromValueForRadius = 0.1
        radius = UIScreen.main.bounds.size.width
        startInterval = 1
        layerNumber = 5
        self.repeatCount = Float.infinity
        self.backgroundColor = UIColor.white.cgColor//UIColor(displayP3Red: 0.000, green: 0.455, blue: 0.756, alpha: 0.45).cgColor
//        affect.backgroundColor = self.backgroundColor

    }
    
    @objc public func start()
    {
        animatePulsatingLayer()
        affect.add(animationGroup, forKey: "pulse")
    }
    private func createCircleShapeLayer(strokeColor: UIColor, fillColor: UIColor, radius: CGFloat) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let circularPath = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        layer.path = circularPath.cgPath
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = 20
        layer.fillColor = fillColor.cgColor
//        layer.lineCap = CAShapeLayerLineCap.round
//        layer.position = self.center
        return layer
    }
    public func animatePulsatingLayer() {
        let aGroup = CAAnimationGroup()
        aGroup.duration = animationDuration + pulseInterval
        aGroup.repeatCount = self.repeatCount
//        aGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)

        let animation = CABasicAnimation(keyPath: "transform.scale.xy")
        animation.fromValue = fromValueForRadius
        animation.toValue = 1
        animation.duration = animationDuration
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.duration = animationDuration
//        let fromValueForAlpha = 1//self.backgroundColor?.alpha
        opacityAnimation.values = [0, 0.3, 0]
        opacityAnimation.keyTimes = ([0, keyTimeForHalfOpacity, 1] as! [NSNumber])
        
        aGroup.animations = [animation,opacityAnimation]
        animationGroup = aGroup
        animationGroup.delegate = self
    }
    @objc func onDidEnterBackground()
    {
        if self.superlayer != nil {
            self.prevSuperlayer = self.superlayer;
            if (self.prevSuperlayer != nil) {
                var layerIndex: UInt32 = 0
                for aSublayer in self.superlayer!.sublayers!
                {
                    if aSublayer == self
                    {
                        self.prevLayerIndex = layerIndex
                        break
                    }
                    layerIndex = layerIndex + 1
                }
            }
            self.prevAnimation = affect.animation(forKey: "pulse")
        }
    }
    @objc func onWillEnterForeground()
    {
        if (shouldResume)
        {
            resume()
        }
    }
    func resume() {
        self.addSublayer(affect)
        if(prevSuperlayer != nil)
        {
            prevSuperlayer.insertSublayer(self, at: prevLayerIndex)
        }
        if (prevAnimation != nil) {
            affect.add(prevAnimation, forKey: "pulse")
        }
    }
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
//        if let arrKey = affect.animationKeys(), arrKey.count > 0
//        {
//            affect.removeAllAnimations()
//        }
//        affect.removeFromSuperlayer()
//        self.removeFromSuperlayer()
    }
}
