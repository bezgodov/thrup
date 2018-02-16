import Foundation
import SpriteKit

class BossLevel: NSObject, SKPhysicsContactDelegate {
    
    enum CollisionTypes: UInt32 {
        case enemy = 1
        case character = 2
        case star = 3
    }
    
    /// таймер, который для объектов-врагов
    var timerEnemy: Timer!
    
    /// таймер, который для звёзж
    var timerStar: Timer!
    
    /// Если уровень проигран/выйгран, то запретить любые действия
    var isFinishedLevel = false
    
    /// Можно ли уделать следующий ход
//    var isAvailableNextMove = true
    
    /// Текстуры всех объектов
    var textures = [ObjectType: SKTexture]()
    
    var gameScene: GameScene!
    
    /// Количество звёзд, которые должны быть собраны на уровне (задаются в json)
    var countStars = 1
    
    override init() {
        super.init()
        
        gameScene = Model.sharedInstance.gameScene
        gameScene.physicsWorld.contactDelegate = self
        
        countStars = gameScene.moves
        setCountStars(countStars)
        
        Model.sharedInstance.gameViewControllerConnect.buyLevelButton.isHidden = true
        Model.sharedInstance.gameViewControllerConnect.startRightEdgeOutlet.constant = -35
        Model.sharedInstance.gameViewControllerConnect.startLevel.isHidden = true
        
        texturesSettings()
        
        characterSettings()
        
        bgSettings()
        
        // Добавляем свайпы
        let directions: [UISwipeGestureRecognizerDirection] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
            gesture.direction = direction
            gameScene.view!.addGestureRecognizer(gesture)
        }
        
        timersSettings()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Функция, которая инициализирует таймеры для генерации объектов
    func timersSettings() {
        let timerKoef = Double(Model.sharedInstance.currentLevel / Model.sharedInstance.distanceBetweenSections / 10)
        
        gameScene.objectsLayer.speed += CGFloat(timerKoef)
        
        timerEnemy = Timer.scheduledTimer(withTimeInterval: 0.745 - timerKoef, repeats: true) { (timerEnemy) in
            self.newObject()
        }
        
        timerStar = Timer.scheduledTimer(withTimeInterval: 4.183 - timerKoef, repeats: true) { (timerStar) in
            self.newStar()
        }
    }
    
    func texturesSettings() {
        let objectsTypes = [ObjectType.bee, ObjectType.spinner, ObjectType.star, ObjectType.spaceAlien]
        for type in objectsTypes {
            let texture = SKTexture(imageNamed: type.spriteName)
            textures[type] = texture
        }
    }
    
    func characterSettings() {
        let character = gameScene.character
        character.physicsBody = SKPhysicsBody(texture: textures[ObjectType.spaceAlien]!, size: CGSize(width: character.size.width / 1.1, height: character.size.height / 1.15))
        character.physicsBody?.isDynamic = false
        character.physicsBody?.categoryBitMask = CollisionTypes.character.rawValue
        character.physicsBody?.contactTestBitMask = CollisionTypes.enemy.rawValue | CollisionTypes.star.rawValue
        character.physicsBody?.collisionBitMask = 0
        
        character.run(SKAction.repeatForever(SKAction.animate(with: gameScene.playerWalkingFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "playerWalking")
    }
    
    func bgSettings() {
        generateBg(sprite: "TopMenuViewBorderDown", row: gameScene.boardSize.row - 1)
        generateBg(sprite: "TopMenuViewBorderUp", row: 0)
    }
    
    func generateBg(sprite: String, row: Int) {
        for index in 0...2 {
            let topMovingSpikes = SKSpriteNode(imageNamed: sprite)
            
            var position = gameScene.pointFor(column: 0, row: row)
            position.x = CGFloat(index) * topMovingSpikes.size.width
            
            if row == 0 {
                position.y -= TileHeight / 2 - topMovingSpikes.size.height / 2
            }
            else {
                position.y += TileHeight / 2 - topMovingSpikes.size.height / 2
            }
            
            topMovingSpikes.position = position
            topMovingSpikes.zPosition = 2
            
            gameScene.objectsLayer.addChild(topMovingSpikes)
            
            topMovingSpikes.run(SKAction.repeatForever(SKAction.sequence([SKAction.moveBy(x: -topMovingSpikes.size.width, y: 0, duration: TimeInterval(5)), SKAction.moveBy(x: topMovingSpikes.size.width, y: 0, duration: 0)])))
        }
    }
    
    func getSizeKoef(_ type: ObjectType) -> CGFloat {
        switch type {
            case ObjectType.star:
                return 0.5
            default:
                return 0.65
        }
    }
    
    func newObject() {
        let objectsToMove = [ObjectType.bee, ObjectType.spinner]
        let randomObject = objectsToMove[Int(arc4random_uniform(UInt32(objectsToMove.count)))]
        createObject(type: randomObject)
        
    }
    
    func newStar() {
        createObject(type: ObjectType.star)
    }
    
    func createObject(type: ObjectType) {
        let randomPos = Point(column: gameScene.boardSize.column + 3, row: Int(arc4random_uniform(5)))
        
        let sizeKoef: CGFloat = getSizeKoef(type)
        
        let object = SKSpriteNode(imageNamed: type.spriteName)
        object.position = gameScene.pointFor(column: randomPos.column, row: randomPos.row)
        object.zPosition = 4
        object.size = CGSize(width: TileWidth * sizeKoef, height: object.size.height / (object.size.width / (TileWidth * sizeKoef)))
        
        object.physicsBody = SKPhysicsBody(texture: textures[type]!, size: CGSize(width: object.size.width / 1.1, height: object.size.height / 1.15))
        object.physicsBody?.affectedByGravity = false
        object.physicsBody?.collisionBitMask = 0
        object.physicsBody?.contactTestBitMask = CollisionTypes.character.rawValue
        
        gameScene.objectsLayer.addChild(object)
        
        objectExtraParams(type: type, object: object)
        
        let moveToPos = gameScene.pointFor(column: -1, row: randomPos.row)
        let randomSpeed = TimeInterval(CGFloat(arc4random_uniform(3) + 2) + CGFloat(Float(arc4random()) / Float(UINT32_MAX)))
        
        object.run(SKAction.moveTo(x: moveToPos.x, duration: randomSpeed)) {
            object.removeFromParent()
        }
    }
    
    func objectExtraParams(type: ObjectType, object: SKSpriteNode) {
        object.physicsBody?.categoryBitMask = CollisionTypes.enemy.rawValue
        
        if type == ObjectType.spinner {
            object.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi * 2), duration: 1)))
        }
        
        if type == ObjectType.star {
            object.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
            
            let pulseUp = SKAction.scale(to: 1.225, duration: 1.5)
            let pulseDown = SKAction.scale(to: 1, duration: 1.5)
            let pulse = SKAction.sequence([pulseUp, pulseDown])
            let repeatPulse = SKAction.repeatForever(pulse)
            object.run(repeatPulse)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if !isFinishedLevel {
            if contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.star.rawValue {
                if contact.bodyB.node?.parent != nil {
                    countStars -= 1
                    contact.bodyB.node?.removeFromParent()
                    setCountStars(countStars)
                }
            }
            
            if contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.star.rawValue {
                if contact.bodyA.node?.parent != nil {
                    countStars -= 1
                    contact.bodyA.node?.removeFromParent()
                    setCountStars(countStars)
                }
            }
            
            if contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.enemy.rawValue {
                loseLevelBoss()
            }
            
            if contact.bodyA.node?.physicsBody?.categoryBitMask == CollisionTypes.character.rawValue && contact.bodyB.node?.physicsBody?.categoryBitMask == CollisionTypes.enemy.rawValue {
                loseLevelBoss()
            }
        }
    }
    
    func loseLevelBoss() {
        isFinishedLevel = true
        cleanTimers()
        gameScene.loseLevel()
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if !isFinishedLevel {
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                var point = gameScene.convertPoint(point: gameScene.character.position)
                
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.right {
                    point.point.column += 1
                }
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.up {
                    point.point.row += 1
                }
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.left {
                    point.point.column -= 1
                }
                if swipeGesture.direction == UISwipeGestureRecognizerDirection.down {
                    point.point.row -= 1
                }
                
                if point.point.column >= 0 && point.point.column < gameScene.boardSize.column && point.point.row >= 0 && point.point.row < gameScene.boardSize.row {
//                    isAvailableNextMove = false
                    gameScene.character.run(SKAction.move(to: gameScene.pointFor(column: point.point.column, row: point.point.row), duration: 0.25), completion: {
//                        self.isAvailableNextMove = true
                    })
                }
                else {
                    gameScene.shakeView(gameScene.view!, repeatCount: 2, amplitude: 3)
                }
            }
        }
    }
    
    func setCountStars(_ amount: Int) {
        Model.sharedInstance.gameViewControllerConnect.movesRemainLabel.text = String(amount)
        
        isWinLevel(amount)
    }
    
    func isWinLevel(_ starsAmount: Int) {
        if starsAmount <= 0 {
            isFinishedLevel = true
            cleanTimers()
            gameScene.winLevel()
        }
    }
    
    func cleanTimers() {
        timerEnemy.invalidate()
        timerStar.invalidate()
    }
}
