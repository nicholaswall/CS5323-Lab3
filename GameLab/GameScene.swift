//
//  GameScene.swift
//  GameLab
//
//  Created by Nick Wall on 10/19/22.
//

import Foundation
import SpriteKit
import CoreMotion


class GameScene: SKScene, SKPhysicsContactDelegate {
    let motion = CMMotionManager()
    weak var viewController: UIViewController?
    
    var stepCount: Int?
    
    
    func addScore(){
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.black
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.minY + 50)
        scoreLabel.zPosition = 100
        
        addChild(scoreLabel)
    }
    
    func addCountDown() {
        countdownLabel.text = """
Shake your device to
move the ball(s) faster.
More Bounces = More Points!
More Steps = More Balls!
You have 10 seconds!
"""
        countdownLabel.fontColor = SKColor.black
        countdownLabel.fontSize = 18
        countdownLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        countdownLabel.numberOfLines = 5
        countdownLabel.zPosition = 100;
        addChild(countdownLabel)
    }

    
    let left = SKSpriteNode()
    let right = SKSpriteNode()
    let top = SKSpriteNode()
    let bottom = SKSpriteNode()
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    let countdownLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    
    
    
    var score:Int = 0 {
        willSet(newValue){
            DispatchQueue.main.async{
                self.scoreLabel.text = "Score: \(newValue)"
            }
        }
    }
    
    var countdown: Int = 10;
    var gameRunning: Bool = false;
    
    var timer = Timer()
    var playTimer = Timer()
    var closeTimer = Timer()
    
    func startMotionUpdates(){
            if self.motion.isDeviceMotionAvailable{
                self.motion.deviceMotionUpdateInterval = 0.2
                self.motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: self.handleMotion )
            } else {
                print("Device Motion not available...")
            }
        }
    
    func handleMotion(_ motionData:CMDeviceMotion?, error: Error?) {
        if gameRunning {
            if let gravity = motionData?.gravity {
                        self.physicsWorld.gravity = CGVector(dx: CGFloat(9.8*gravity.x), dy: CGFloat(9.8*gravity.y))
            }
            
            if let acceleration = motionData?.userAcceleration {
                speed = abs(acceleration.y * acceleration.x) * 5 + 1;
                self.physicsWorld.speed = speed
            }
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        // If any of the contacts are a wall then we increment the score
        if gameRunning {
            if (contact.bodyA.node?.name == "wall" && contact.bodyB.node?.name == "ball") || (contact.bodyA.node?.name == "ball" && contact.bodyB.node?.name == "wall") {
                print("CONTACT")
                self.score += 1
            }
        }
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self;
        backgroundColor = SKColor.white
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
        playTimer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(gameOver), userInfo: nil, repeats: false)
        
        self.startMotionUpdates()
        self.addCountDown()
        self.addScore()
        self.addBorders()
        self.addBall()
        self.score = 0;
    }
    
    @objc func timerAction(){
        countdown = countdown - 1;
        
        if(countdown < 6) {
            self.countdownLabel.text = "Game Starting in \(countdown)..."
        }
        if countdown == 0 {
            gameRunning = true;
            countdownLabel.isHidden = true;
            timer.invalidate()
        }
    }
    
    @objc func gameOver() {
        if(gameRunning) {
            
            self.countdownLabel.isHidden = false
            self.countdownLabel.text = ""
            gameRunning = false;
            countdown = 10
            closeTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(gameOver), userInfo: nil, repeats: true)
            
        }
        else {
            if(countdown > 0) {
                countdown = countdown - 1;
                           self.countdownLabel.text = """
                   Game Over.
                   You Scored: \(score)
                   Returning to Activity
                   in ... \(countdown)
                   """
            } else {
                closeTimer.invalidate()
                self.viewController?.performSegue(withIdentifier: "backToHome", sender: self)
            }
        }
    }
    
    func addBorders() {
        left.size = CGSize(width:size.width*0.1,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        
        right.size = CGSize(width:size.width*0.1,height:size.height)
        right.position = CGPoint(x:size.width, y:size.height*0.5)
        
        top.size = CGSize(width:size.width,height:size.height*0.1)
        top.position = CGPoint(x:size.width*0.5, y:size.height)
        
        bottom.size = CGSize(width: size.width, height: size.height * 0.1)
        bottom.position = CGPoint(x: size.width * 0.5, y: 0)
        
        for obj in [left,right,top, bottom]{
            obj.color = UIColor.gray
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = true
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            obj.name = "wall"
            obj.physicsBody?.contactTestBitMask = 0x00000001
            obj.physicsBody?.collisionBitMask = 0x00000001
            obj.physicsBody?.categoryBitMask = 0x00000001
            self.addChild(obj)
        }
    }
    
    func addBall() {
        var numberOfBalls: Int = (self.stepCount ?? 1) / 250
        if numberOfBalls == 0 {
            numberOfBalls = 1;
        // Max ball count to prevent crashing, no idea what the limit is but just being safe
        } else if (numberOfBalls > 50) {
            numberOfBalls = 50;
        }

        for _ in 0..<numberOfBalls {
            let ball = SKShapeNode(circleOfRadius: size.width * 0.05 )
            ball.fillColor = UIColor.blue
            ball.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            ball.physicsBody = SKPhysicsBody(circleOfRadius: size.width * 0.05)
            ball.physicsBody?.isDynamic = true
            ball.physicsBody?.allowsRotation = true
            ball.physicsBody?.restitution = CGFloat(1.01)
            ball.physicsBody?.contactTestBitMask = 0x00000001
            ball.physicsBody?.collisionBitMask = 0x00000001
            ball.physicsBody?.categoryBitMask = 0x00000001
            ball.name = "ball"
            self.addChild(ball)
        }
        

    }
}
