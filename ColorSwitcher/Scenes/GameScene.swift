//
//  GameScene.swift
//  ColorSwitcher
//
//  Created by Rob Daly on 7/5/18.
//  Copyright © 2018 Rob Daly. All rights reserved.
//

import SpriteKit

enum ColorCircleState: Int {
    case red, yellow, green, blue
}

class GameScene: SKScene {
    
    //MARK: - Overrides
    override func didMove(to view: SKView) {
        self.setupPhysics()
        self.layoutScene()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.turnColorCircle()
    }
    
    //MARK: - Private API
    private var colorCircle: SKSpriteNode!
    private var colorCircleState: ColorCircleState = .red
    private var currentColorIndex: Int?
    private var score = 0
    private let scoreLabel = SKLabelNode(text: "0")
    private var ballSpeed = 2.0
    private let maxBallSpeed = 12.0
    private let ballColors = [
        UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0),
        UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1.0),
        UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0),
        UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
    ]
    
    private func setupPhysics() {
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: self.ballSpeed * -1)
        self.physicsWorld.contactDelegate = self
    }
    
    private func layoutScene() {
        self.backgroundColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1.0)
        
        self.scoreLabel.fontName = "AvenirNext-Bold"
        self.scoreLabel.fontSize = 60.0
        self.scoreLabel.fontColor = UIColor.white
        self.scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        self.scoreLabel.zPosition = ZPositions.label
        self.addChild(self.scoreLabel)
        
        self.spawnColorCircle()
        self.spawnBall()
    }
    
    private func updateScoreLabel() {
        self.scoreLabel.text = "\(self.score)"
    }
    
    private func spawnColorCircle() {
        self.colorCircle = SKSpriteNode(imageNamed: "ColorCircle")
        self.colorCircle.size = CGSize(width: frame.size.width / 3, height: frame.size.width / 3)
        self.colorCircle.position = CGPoint(x: frame.midX, y: frame.minY + self.colorCircle.size.height)
        self.colorCircle.zPosition = ZPositions.colorCircle
        self.colorCircle.physicsBody = SKPhysicsBody(circleOfRadius: self.colorCircle.size.width / 2)
        self.colorCircle.physicsBody?.categoryBitMask = PhysicsCategories.colorCircleCategory
        self.colorCircle.physicsBody?.isDynamic = false
        
        self.addChild(self.colorCircle)
    }
    
    private func spawnBall() {
        // random number between 0 & 3
        self.currentColorIndex = Int(arc4random_uniform(UInt32(4)))
        
        let ball = SKSpriteNode(texture: SKTexture(imageNamed: "ball"), color: self.ballColors[self.currentColorIndex!], size: CGSize(width: 30.0, height: 30.0))
        ball.colorBlendFactor = 1.0 // make sure color is displayed instead of tetures default color
        ball.name = "Ball"
        ball.position = CGPoint(x: frame.midX, y: frame.maxY)
        ball.zPosition = ZPositions.ball
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
        ball.physicsBody?.categoryBitMask = PhysicsCategories.ballCategory
        ball.physicsBody?.contactTestBitMask = PhysicsCategories.colorCircleCategory
        ball.physicsBody?.collisionBitMask = PhysicsCategories.none
        
        self.addChild(ball)
    }
    
    private func turnColorCircle() {
        // if this fails we're at a value too high for our enum so reset the state
        if let newState = ColorCircleState(rawValue: self.colorCircleState.rawValue + 1) {
            self.colorCircleState = newState
        } else {
            self.colorCircleState = .red
        }
        
        self.colorCircle.run(SKAction.rotate(byAngle: .pi/2, duration: 0.25))
    }
    
    private func gameOver() {
        self.saveScore()
        
        let menuScene = MenuScene(size: view!.bounds.size)
        view?.presentScene(menuScene)
    }
    
    private func saveScore() {
        UserDefaults.standard.set(self.score, forKey: "LastScore")
        
        if self.score > UserDefaults.standard.integer(forKey: "HighScore") {
            UserDefaults.standard.set(self.score, forKey: "HighScore")
        }
    }
    
    private func increaseBallSpeed() {
        if self.ballSpeed >= self.maxBallSpeed { return }
        self.ballSpeed += 0.3
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: self.ballSpeed * -1)
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // 01 - colorCircle
        // 10 - ball
        // bitwise or operator combines the bitmasks:
        // 11
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Normally would use a switch, but only one contact in this case so if statement sufficient
        
        if contactMask == PhysicsCategories.ballCategory | PhysicsCategories.colorCircleCategory {
            // check which body is the ball then check if it's the same color as the colorCircle
            if let ball = contact.bodyA.node?.name == "Ball" ? contact.bodyA.node as? SKSpriteNode : contact.bodyB.node as? SKSpriteNode {
                if self.currentColorIndex == self.colorCircleState.rawValue {
                    self.run(SKAction.playSoundFileNamed("bling.wav", waitForCompletion: false))
                    self.score += 1
                    
                    // Increase ball speed every 10 points
                    if self.score % 10 == 0 {
                        self.increaseBallSpeed()
                    }
                    
                    self.updateScoreLabel()
                    ball.run(SKAction.fadeOut(withDuration: 0.25), completion: {
                        ball.removeFromParent()
                        self.spawnBall()
                    })
                } else {
                    self.gameOver()
                }
            }
        }
    }
}
