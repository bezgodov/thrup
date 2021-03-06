import Foundation
import SpriteKit

extension GameScene {

    @objc func longPressed(sender: UILongPressGestureRecognizer)
    {
        if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
            if !gameBegan && Model.sharedInstance.getShowTips() && !isLevelWithTutorial && !isPreviewing && !isModalWindowOpen {
                /// Был ли клик сделан по какому-либо объекту
                var objectTypeClicked: ObjectType?
                
                let point = self.convertPoint(fromView: sender.location(in: self.view))
                let pointNode = objectsLayer.scene?.convert(point, to: objectsLayer)
                let boardClick = convertPoint(point: pointNode!)
                
                if sender.state == UIGestureRecognizerState.began {
                    if boardClick.success {
                        
                        for object in movingObjects {
                            // Если клик был сделан по перемещающемуся объекту, то показываем его траекторию
                            if object.getPoint() == boardClick.point {
                                if object.pathLayer.parent != nil {
                                    object.path(hide: true)
                                }
                                else {
                                    object.path()
                                    objectTypeClicked = object.type
                                    isLastTapLongPress = true
                                }
                            }
                            else {
                                object.path(hide: true)
                            }
                        }
                        
                        for object in staticObjects {
                            if object.point == boardClick.point {
                                objectTypeClicked = object.type
                            }
                        }
                        
                        if boardClick.point == characterStart && !addedLastPointByMove {
                            objectTypeClicked = ObjectType.spaceAlien
                        }
                        
                        if boardClick.point == finish && !addedLastPointByMove {
                            objectTypeClicked = ObjectType.gem
                        }
                        
                        prepareObjectInfoView(objectTypeClicked, boardClick: boardClick.point)
                        
                        lastClickOnGameBoard = boardClick.point
                    }
                }
                
                if sender.state == UIGestureRecognizerState.ended {
                    isLastTapLongPress = false
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
            if !gameBegan && !isPreviewing && !isModalWindowOpen {
                if let touch = touches.first {
                    let touchLocation = touch.location(in: objectsLayer)
                    // Если не сделан ещё первый ход
                    if !isLastTapLongPress {
                        if move == 0 {
                            let boardClick = convertPoint(point: touchLocation)
                            // Если клик был сделан по игровому полю
                            if boardClick.success {
                                // Сохраняем точку где был сделан первый клик, чтобы при Moved можно было удалять ходы в обратную сторону
                                checkChoosingPath = boardClick.point
                                // Сохраняем все уже выбранные ходы ГП, чтобы при Moved не удалить эти ходы
                                checkChoosingPathArray = character.moves
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
            if !gameBegan && !isLevelWithTutorial && !isPreviewing && !isModalWindowOpen {
                if let touch = touches.first {
                    let touchLocation = touch.location(in: objectsLayer)
                    if !isLastTapLongPress {
                        if move == 0 {
                            let boardClick = convertPoint(point: touchLocation)
                            if boardClick.success {
                                // Если не исчерпали ещё все ходы
                                if moves > 0 {
                                    // Если клик не был сделан по начальной точки ГП
                                    if boardClick.point != characterStart {
                                        // Если расстояние от последнего хода в траектории и нового хода равно 1 (принимает значение 1, когда новый блок находится строго сверху, справа, снизу или слева. В противном случае блок примет большее значение. Данная проверка запрещает ходы по вертикали)
                                        if sqrt(pow(Double(character.moves.last!.column - boardClick.point.column), Double(2)) + pow(Double(character.moves.last!.row - boardClick.point.row), Double(2))) == 1 {
                                            // Если точка ещё не находится в траектории (так как нельзя делать ход в поле, в которое уже был сделан ход заранее)
                                            if !pointExists(points: character.moves, point: boardClick.point) {
                                                
                                                character.moves.append(boardClick.point)
                                                checkChoosingPath = boardClick.point
                                                checkChoosingPathArray = character.moves
                                                
                                                SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                                                
                                                updateMoves(-1)
                                                character.path()
                                                
                                                // Так как мы начали строить траекторию ГП, то спрятать все траектории остальных объектов)
                                                for object in movingObjects {
                                                    object.path(hide: true)
                                                }
                                                
                                                // Флаг, который указывает, что последний ход был сделан с помощью Move, но не с помощью Touched
                                                addedLastPointByMove = true
                                            }
                                        }
                                    }
                                }
                                
                                // Следующие проверки предназначены для того, чтобы удостовериться, что позиция в траектории, которую уже выбрали для ГП существует
                                if checkChoosingPathArray.last != nil {
                                    if checkChoosingPathArray.last! == checkChoosingPath {
                                        if pointExists(points: character.moves, point: boardClick.point) {
                                            if getMoveIndex(move: checkChoosingPath, moves: character.moves) - getMoveIndex(move: boardClick.point, moves: character.moves) == 1 {
                                                
                                                character.moves.remove(at: character.moves.count - 1)
                                                checkChoosingPathArray.removeLast()
                                                checkChoosingPath = character.moves[character.moves.count - 1]
                                                
                                                SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                                                
                                                updateMoves(1)
                                                character.path()
                                                
                                                removedLastPointByMove = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections != 0 {
            if !gameBegan && !isLevelWithTutorial && !isPreviewing && !isModalWindowOpen {
                if let touch = touches.first {
                    if !isLastTapLongPress {
                        if move == 0 {
                            let touchLocation = touch.location(in: objectsLayer)
                            let boardClick = convertPoint(point: touchLocation)
                            
                            /// Был ли клик сделан по какому-либо объекту
                            var objectTypeClicked: ObjectType?
                            
                            if boardClick.success {
                                if boardClick.point == checkChoosingPath {
                                    if character.moves.count == 1 {
                                        for object in movingObjects {
                                            // Если клик был сделан по перемещающемуся объекту, то показываем его траекторию
                                            if object.getPoint() == boardClick.point {
                                                if object.pathLayer.parent != nil {
                                                    object.path(hide: true)
                                                }
                                                else {
                                                    object.path()
                                                }
                                                
                                                objectTypeClicked = object.type
                                            }
                                            else {
                                                object.path(hide: true)
                                            }
                                        }
                                        
                                        for object in staticObjects {
                                            // Если клик был сделан по статичному объекту
                                            if boardClick.point == object.point {
                                                // Если клик был сделан по объекту "мост", то поворачиваем на 90 deg.
                                                if object.type == ObjectType.bridge {
                                                    if object.active {
                                                        object.active = false
                                                        
                                                        object.rotate = object.rotate.nextPoint()
                                                        self.animateBridgeWall(object: object)
                                                        
                                                        object.run(SKAction.rotate(toAngle: object.zRotation - CGFloat(90 * Double.pi / 180), duration: 0.35), completion: {
                                                            object.active = true
                                                        })
                                                    }
                                                }
                                                
                                                if object.type == ObjectType.button {
                                                    changeButtonsState(object)
                                                }
                                                objectTypeClicked = object.type
                                            }
                                        }
                                    }
                                    else {
                                        if !isLastTapLongPress {
                                            for object in movingObjects {
                                                if object.pathLayer.parent != nil {
                                                    object.path(hide: true)
                                                }
                                            }
                                        }
                                    }
                                
                                    if boardClick.point != characterStart {
                                        // Если расстояние от последнего хода в траектории и нового хода равно 1 (принимает значение 1, когда новый блок находится строго сверху, справа, снизу или слева. В противном случае блок примет большее значение. Данная проверка запрещает ходы по вертикали)
                                            // + Если ещё не добавляли эту позицию в траеткорию
                                        if sqrt(pow(Double(character.moves.last!.column - boardClick.point.column), Double(2)) + pow(Double(character.moves.last!.row - boardClick.point.row), Double(2))) == 1 && !pointExists(points: character.moves, point: boardClick.point) {
                                            // Если не исчерпали ещё все ходы
                                            if moves > 0 {
                                                
                                                character.moves.append(boardClick.point)
                                                
                                                updateMoves(-1)
                                                character.path()
                                                
                                                SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                                                
                                                // Так как мы начали строить траекторию ГП, то спрятать все траектории остальных объектов)
                                                for object in movingObjects {
                                                    object.path(hide: true)
                                                }
                                            }
                                        }
                                        else {
                                            // Если кликнуть в любую точку пути, то путь стирается до этой позиции
                                            if !addedLastPointByMove && !removedLastPointByMove {
                                                let isContainMove = pointExists(points: character.moves, point: boardClick.point)
                                                
                                                if isContainMove {
                                                    var indexFromRemove = 0
                                                    
                                                    for move in character.moves {
                                                        
                                                        if move != boardClick.point {
                                                            indexFromRemove += 1
                                                        }
                                                        else {
                                                            if move == character.moves.last! {
                                                                updateMoves(1)
                                                                character.moves.removeLast()
                                                            }
                                                            else {
                                                                updateMoves(character.moves.endIndex - indexFromRemove - 1)
                                                                character.moves.removeSubrange(indexFromRemove + 1..<character.moves.endIndex)
                                                            }
                                                            break
                                                        }
                                                    }
                                                    
                                                    SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                                                    character.path()
                                                }
                                            }
                                        }
                                    }
                                    else {
                                        if character.moves.count == 1 && !addedLastPointByMove {
                                            objectTypeClicked = ObjectType.spaceAlien
                                        }
                                        
                                        if !addedLastPointByMove && !removedLastPointByMove && boardClick.point == checkChoosingPath {
                                            updateMoves(character.moves.endIndex - 1)
                                            character.moves.removeSubrange(1..<character.moves.endIndex)
                                            SKTAudio.sharedInstance().playSoundEffect(filename: "GrassStep.mp3")
                                            character.path()
                                        }
                                    }
                                
                                    if boardClick.point == finish && character.moves.count == 1 && !addedLastPointByMove {
                                        objectTypeClicked = ObjectType.gem
                                    }
                                
                                
                                    if !removedLastPointByMove && objectTypeClicked != ObjectType.bridge && objectTypeClicked != ObjectType.button && Model.sharedInstance.getShowTips() {
                                        prepareObjectInfoView(objectTypeClicked, boardClick: boardClick.point)
                                    }

                                    if objectTypeClicked == ObjectType.bridge || objectTypeClicked == ObjectType.button {
                                        removeObjectInfoView(toAlpha: 0)
                                    }
                                    lastClickOnGameBoard = boardClick.point
                                }
                            }
                        }
                    }
                }
                addedLastPointByMove = false
                removedLastPointByMove = false
            }
        }
    }
    
    func prepareObjectInfoView(_ objectTypeClicked: ObjectType?, boardClick: Point) {
        
        if lastClickOnGameBoard == boardClick && isOpenInfoView {
            removeObjectInfoView(toAlpha: 0)
            SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
        }
        else {
            var toAlpha: CGFloat = 0
            if objectTypeClicked != nil {
                toAlpha = 1
            }
            
            removeObjectInfoView(toAlpha: toAlpha)
            
            if objectTypeClicked != nil {
                
                var sprite = objectTypeClicked!.spriteName
                
                if objectTypeClicked == ObjectType.lock || objectTypeClicked == ObjectType.key || objectTypeClicked == ObjectType.button {
                    for object in staticObjects {
                        if object.point == boardClick {
                            var prefix = "Button"
                            
                            if objectTypeClicked != ObjectType.button {
                                prefix = objectTypeClicked == ObjectType.lock ? "Lock" : "Key"
                            }
                            
                            sprite = "\(prefix)_\(object.lockKeyColor!)"
                            
                            break
                        }
                    }
                }
                
                presentObjectInfoView(spriteName: sprite, description: objectTypeClicked!.description)
            }
        }
    }
    
    func removeObjectInfoView(toAlpha: CGFloat = 1) {
        if isOpenInfoView {
            let lastInfoView = objectInfoView
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25, animations: {
                    if lastInfoView != nil {
                        if lastInfoView?.superview != nil {
                            lastInfoView?.frame.origin.x = -1 * (Model.sharedInstance.gameScene.view?.frame.size.width)!
                            lastInfoView?.alpha = toAlpha
                        }
                    }
                }, completion: { (_) in
                    if lastInfoView != nil {
                        if lastInfoView?.superview != nil {
                            lastInfoView?.removeFromSuperview()
                        }
                    }
                })
            }
        }
        
        isOpenInfoView = false
    }
    
    func presentObjectInfoView(spriteName: String?, description: String, infoViewHeight: CGFloat = 85, isUserInteractionEnabled: Bool = false) {
        isOpenInfoView = true
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
        
        let objectInfoViewSize = CGSize(width: (Model.sharedInstance.gameScene.view?.frame.width)!, height: infoViewHeight)
        
        // ((Model.sharedInstance.gameScene.frame.height - (Model.sharedInstance.gameScene.frame.height - (TileHeight * CGFloat(boardSize.row)))) / 2) - (TileHeight * CGFloat(boardSize.row))
        let ypos = -(TileHeight * CGFloat(boardSize.row)) / 2
        let objectInfoViewPosConverted = Model.sharedInstance.gameScene.convertPoint(toView: CGPoint(x: 0, y: ypos))
        
        objectInfoView = UIView(frame: CGRect(x: (Model.sharedInstance.gameScene.view?.frame.size.width)!, y: objectInfoViewPosConverted.y, width: objectInfoViewSize.width, height: objectInfoViewSize.height))
        objectInfoView!.backgroundColor = UIColor.darkGray
        
        // Пропускать ли клик по подсказке "через себя"
        objectInfoView?.isUserInteractionEnabled = isUserInteractionEnabled
        
        Model.sharedInstance.gameScene.view?.addSubview(objectInfoView!)
        
        if spriteName != nil {
            let objectIcon = UIImageView(image: UIImage(named: spriteName!))
            objectIcon.alpha = 0.0
            objectIcon.frame.size = CGSize(width: 45, height: objectIcon.frame.size.height / (objectIcon.frame.size.width / 45))
            objectIcon.frame.origin = CGPoint(x: 10, y: (objectInfoViewSize.height / 2) - (objectIcon.frame.size.height / 2))
        
            objectInfoView!.addSubview(objectIcon)
        
            let objectDescription = UILabel(frame: CGRect(x: objectIcon.frame.size.width + 10 + 10, y: 0, width: objectInfoView!.frame.size.width - objectIcon.frame.size.width - 20 - 10 - 10, height: objectInfoView!.frame.size.height))
            objectDescription.alpha = 0.0
            objectDescription.lineBreakMode = NSLineBreakMode.byWordWrapping
            objectDescription.numberOfLines = 4
            objectDescription.font = UIFont(name: "Avenir Next", size: 14)
            
            if Model.sharedInstance.isDeviceIpad() {
                objectDescription.font = UIFont(name: "Avenir Next", size: 20)
            }
            
            objectDescription.text = description
            objectDescription.textColor = UIColor.white
            objectInfoView!.addSubview(objectDescription)
            
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5, animations: {
                    if spriteName != nil {
                        objectIcon.alpha = 1.0
                        objectDescription.alpha = 1.0
                    }
                })
            }
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.objectInfoView!.frame.origin.x = 0
            })
        }
    }
    
    /// Функция, которая анимирует стены (мост)
    func animateBridgeWall(object: StaticObject) {
        
        /// Переменная, которая определяет на сколько нужно уменьшить размер стен
        let downScale: CGFloat = 2.5
        
        var scaleFactorForIpad: CGFloat = 1
        
        if Model.sharedInstance.isDeviceIpad() {
            scaleFactorForIpad = 2.5
        }
    
        var defaultRightLeft = CGSize(width: 5 * scaleFactorForIpad, height: 0)
        var defaultTopBottom = CGSize(width: 0, height: 5 * scaleFactorForIpad)

        var rightLeft = CGSize(width: 5 * scaleFactorForIpad, height: 0)
        var topBottom = CGSize(width: 0, height: 5 * scaleFactorForIpad)

        if object.rotate == RotationDirection.top || object.rotate == RotationDirection.bottom {
            defaultRightLeft.height = 0
            rightLeft.height = TileHeight / (downScale / 2)

            defaultTopBottom.width = TileWidth / (downScale / 2)
            topBottom.width = 0
        }
        else {
            defaultRightLeft.height = TileHeight / (downScale / 2)
            rightLeft.height = 0

            defaultTopBottom.width = 0
            topBottom.width = TileWidth / (downScale / 2)
        }
        
        /// Координаты блока (моста)
        let bridgeTilePos = pointFor(column: object.point.column, row: object.point.row)
        let countOfWalls = 4
        
        // Коэффициенты, которые определяют в какую сторону от блока сместить стену
        let xPositions = [1, -1, -1, 1]
        let yPositions = [-1, 1, 1, -1]
        
        let defaultAnchorPoint = [CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 0)]
        
        for index in 0..<countOfWalls {
            let bridgeWall = objectsLayer.childNode(withName: "BridgeWall_\(index)-Object_\(object.hash)") as! SKSpriteNode
            
            if index == 0 || index == 2 {
                bridgeWall.run(SKAction.resize(toHeight: rightLeft.height, duration: 0.3), completion: {
                    if rightLeft.height == 0 {
                        bridgeWall.anchorPoint = CGPoint(x: defaultAnchorPoint[index].x, y: abs(defaultAnchorPoint[index].y - 1))
                        bridgeWall.position = CGPoint(x: bridgeTilePos.x + (TileWidth / downScale) * CGFloat(xPositions[index]), y: bridgeTilePos.y + (TileHeight / downScale) * CGFloat(yPositions[index]) * -1)
                    }
                    else {
                        bridgeWall.anchorPoint = defaultAnchorPoint[index]
                        bridgeWall.position = CGPoint(x: bridgeTilePos.x + (TileWidth / downScale) * CGFloat(xPositions[index]), y: bridgeTilePos.y + (TileHeight / downScale) * CGFloat(yPositions[index]))
                    }
                })
            }
            else {
                bridgeWall.run(SKAction.resize(toWidth: topBottom.width, duration: 0.3), completion: {
                    if topBottom.width == 0 {
                        bridgeWall.anchorPoint = defaultAnchorPoint[index]
                        bridgeWall.position = CGPoint(x: bridgeTilePos.x + (TileWidth / downScale) * CGFloat(xPositions[index]), y: bridgeTilePos.y + (TileHeight / downScale) * CGFloat(yPositions[index]))
                    }
                    else {
                        bridgeWall.anchorPoint.y = abs(defaultAnchorPoint[index].y - 1)
                        bridgeWall.position = CGPoint(x: bridgeTilePos.x + (TileWidth / downScale) * CGFloat(xPositions[index]), y: bridgeTilePos.y + (TileHeight / downScale) * CGFloat(yPositions[index]) * -1)
                    }
                })
            }
        }
    }
}
