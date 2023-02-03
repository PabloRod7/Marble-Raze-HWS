//
//  GameScene.swift
//  Project26
//
//  Created by Pablo Rodrigues on 28/01/2023.
//
import CoreMotion
import SpriteKit

enum CollisingTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    case porta = 32
}

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var lasTouchPosition: CGPoint?
    var motionManager: CMMotionManager?
    var isGameover = false
    var scoreLabel: SKLabelNode!
    var currentLevelLabel : SKLabelNode!
    
    
    
    var restartGameLabel: SKLabelNode!
    var restartLevelLabel: SKLabelNode!
    var nextLevelLabel: SKLabelNode!
    var finishNode: SKSpriteNode!
    
    var currentLevel = 1 {
        didSet {
            currentLevelLabel.text = "Level: \(currentLevel)"
        }
    }
    var maxLevel = 4
    
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.position = CGPoint(x: 16, y: 75)
        scoreLabel.zPosition = 2
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
        
        currentLevelLabel = SKLabelNode(fontNamed: "Chalkduster")
        currentLevelLabel.text = "Level: \(currentLevel)"
        currentLevelLabel.horizontalAlignmentMode = .left
        currentLevelLabel.position = CGPoint(x: 16, y: 710)
        currentLevelLabel.zPosition = 2
        currentLevelLabel.name = "currentLevel"
        addChild(currentLevelLabel)
        
        createLabels()
        
        loadLevel()
        createPlayer()
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        
        
    }
    
    func restart(){
        finishNode.removeFromParent()
        nextLevelLabel.removeFromParent()
        restartLevelLabel.removeFromParent()
        restartGameLabel.removeFromParent()
        destroyLevel()
        loadLevel()
        createPlayer()
        isGameover = false
    }
    func createLabels(){
        
        finishNode = SKSpriteNode(imageNamed: "finish")
        finishNode.position = CGPoint(x: 512, y: 544)
        finishNode.zPosition = 2
        
        nextLevelLabel = SKLabelNode(fontNamed: "Chalkduster")
        nextLevelLabel.text = "Next Level"
        nextLevelLabel.zPosition = 2
        nextLevelLabel.fontSize = 48
        nextLevelLabel.position = CGPoint(x: 512, y: 454)
        nextLevelLabel.name = "nextlevel"
        nextLevelLabel.horizontalAlignmentMode = .center
        
        restartLevelLabel = SKLabelNode(fontNamed: "Chalkduster")
        restartLevelLabel.text = "Restart Level"
        restartLevelLabel.zPosition = 2
        restartLevelLabel.position = CGPoint(x: 512, y: 384)
        restartLevelLabel.fontSize = 48
        restartLevelLabel.horizontalAlignmentMode = .center
        restartLevelLabel.name = "restartlevel"
        
        restartGameLabel = SKLabelNode(fontNamed: "Chalkduster")
        restartGameLabel.text = "Restart Game"
        restartGameLabel.zPosition = 2
        restartGameLabel.position = CGPoint(x: 512, y: 314)
        restartGameLabel.fontSize = 48
        restartGameLabel.horizontalAlignmentMode = .center
        restartGameLabel.name = "restartgame"
        
        
    }
    func loadLevel(){
        let name = "level\(currentLevel)"
        
        guard let levelUrl = Bundle.main.url(forResource: name, withExtension: "txt") else {
            fatalError("Could not find level1.txt in your Bundle.")
        }
        guard let urlString = try? String(contentsOf: levelUrl) else {
            fatalError("Could not load level1.txt from your bundle.")
        }
        let lines = urlString.split(separator: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                addLevelElement(withID: letter, to: position)
            }
        }
        
    }
    
    
    
    func addLevelElement(withID letter: Character,to position: CGPoint){
        if letter == "x" {
            addWall(to: position)
        } else if letter == "v" {
            addVortex(to: position)
        } else if letter == "s" {
            addStar(to: position)
        } else if letter == "f" {
            addFinish(to: position)
        } else if letter == "p" {
            addPorta(to: position)
        } else if letter == " " {
            //            nothing
        } else {
            fatalError("did not found the letter!")
        }
    }
    
    func destroyLevel(){
        for node in children {
            if ["blok", "vortex", "star", "finish","porta"].contains(node.name) {
                node.removeFromParent()
            }
        }
        player.removeFromParent()
    }
    
    func createPlayer(){
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisingTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisingTypes.star.rawValue | CollisingTypes.vortex.rawValue | CollisingTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisingTypes.wall.rawValue
        addChild(player)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        
        lasTouchPosition = location
        
        for node in nodes(at: location) {
            if node.name == "nextlevel" {
                currentLevel += 1
                if currentLevel > maxLevel {
                    currentLevel = 1
                }
                restart()
            }
            else if node.name == "restartlevel" {
                restart()
            }
            else if node.name == "restartgame" {
                score = 0
                currentLevel = 1
                restart()
            }
            else if node.name == "currenLevel" {
                player.removeFromParent()
                player.physicsBody?.isDynamic = false
                addChild(restartGameLabel)
                addChild(restartLevelLabel)
                addChild(nextLevelLabel)
            }
        }
        
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lasTouchPosition = nil
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        
        lasTouchPosition = location
    }
    override func update(_ currentTime: TimeInterval) {
        guard isGameover == false else {return}
#if targetEnvironment(simulator)
        if let lasTouchPosition = lasTouchPosition {
            let diff = CGPoint(x: lasTouchPosition.x - player.position.x, y: lasTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        } #else
        if let accelometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelometerData.acceleration.y * -50, dy: accelometerData.acceleration.x * 50)
        }
#endif
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodaA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        
        if nodaA == player {
            playerCollied(with: nodeB)
        } else if nodeB == player {
            playerCollied(with: nodaA)
        }
    }
    
    func playerCollied(with node: SKNode){
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameover = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(by: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.run(sequence) {[weak self] in
                self?.createPlayer()
                self?.isGameover = false
            }
            
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
        } else if node.name == "finish" {
            //
            player.physicsBody?.isDynamic = false
            addChild(finishNode)
            addChild(nextLevelLabel)
            addChild(restartLevelLabel)
            addChild(restartGameLabel)
        }
        else if node.name == "porta" {
           
            
        }
    }
        
        
        
        func addWall(to position: CGPoint){
            let node = SKSpriteNode(imageNamed: "block")
            node.name = "blok"
            node.position = position
            node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
            node.physicsBody?.categoryBitMask = CollisingTypes.wall.rawValue
            node.physicsBody?.isDynamic = false
            addChild(node)
        }
        
        func addVortex(to position: CGPoint){
            
            let node = SKSpriteNode(imageNamed: "vortex")
            node.name = "vortex"
            node.position = position
            node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
            
            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = CollisingTypes.vortex.rawValue
            node.physicsBody?.contactTestBitMask = CollisingTypes.player.rawValue
            node.physicsBody?.collisionBitMask = 0
            addChild(node)
        }
        
        func addStar(to position: CGPoint){
            let node = SKSpriteNode(imageNamed: "star")
            node.name = "star"
            node.position = position
            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = CollisingTypes.star.rawValue
            node.physicsBody?.contactTestBitMask = CollisingTypes.player.rawValue
            node.physicsBody?.collisionBitMask = 0
            addChild(node)
        }
        
        func addFinish(to position: CGPoint){
            
            let node = SKSpriteNode(imageNamed: "finish")
            node.name = "finish"
            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = CollisingTypes.finish.rawValue
            node.physicsBody?.collisionBitMask = CollisingTypes.player.rawValue
            node.physicsBody?.collisionBitMask = 0
            node.position = position
            addChild(node)
        }
        func addPorta(to position: CGPoint){
            let node = SKSpriteNode(imageNamed: "porta")
            node.name = "porta"
            node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
            node.size = CGSize(width: 30, height: 50)
            node.position = position
            node.physicsBody?.categoryBitMask = CollisingTypes.porta.rawValue
            node.physicsBody?.contactTestBitMask = CollisingTypes.player.rawValue
            node.physicsBody?.collisionBitMask = 0
            node.physicsBody?.isDynamic = false
            addChild(node)
        }
        
    }
    

