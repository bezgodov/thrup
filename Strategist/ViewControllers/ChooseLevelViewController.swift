import SpriteKit
import Flurry_iOS_SDK

class ChooseLevelViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var findCharacterButton: UIButton!
    @IBOutlet var controlsSizeConstraint: [NSLayoutConstraint]!
    /// Размеры поля, на котором располагается меню
    var boardSize = Point(column: 5, row: 5)
    
    /// Размер ячейки поля
    var levelTileSize = CGSize(width: 50, height: 50)
    
    /// UIView, на которую крепятся все ячейки поля
    var tilesLayer: UIView!
    
    /// Расстояние по вертикали между ячейками уровней
    var distanceBetweenLevels = 3
    
    /// Доп. переменная, которая служит для фиксов различных случаем (на начальных и последних уровнях)
    var extraCountForExtremeLevels = 0
    
    /// Начальная точка главного персонажа
    var characterPointStart: Point!
    
    /// UIImageView ГП
    var character: UIImageView!
    
    /// Текстуры анимации ГП
    var walkFrames: [UIImage]!
    
    /// Координаты всех кнопок уровней
    var levelButtonsPositions = [Point]()
    
    /// Флаг, который определяет автоматическое перемещение персонажа при открытии меню
    var moveCharacterToNextLevel = false

    /// БГ модального окна
    var modalWindowBg: UIView!
    
    /// Модальное окно
    var modalWindow: UIView!
    
    /// Количество уровней, которое необходимо завершить для каждой секции для 1 секции -> 11, для второй -> 25
    var sections = [11, 25, 40]
    
    /// Заблокирована ли следующая секция (если не пройдено необходимо кол-во уровней за предыдущую секцию)
    var isNextSectionDisabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        menuSettings()
//        UserDefaults.standard.removeObject(forKey: "isPaidPreviewMode")
//        Model.sharedInstance.setCountGems(amountGems: 50)
        characterInitial()
        
        // Если самое начало игры, то делаем анимацию перехода на 1-ый уровень
        if Model.sharedInstance.getCountCompletedLevels() == 0 {
            moveToPoint(from: Point(column: levelButtonsPositions[Model.sharedInstance.currentLevel - 1].column, row: levelButtonsPositions[Model.sharedInstance.currentLevel - 1].row - distanceBetweenLevels), to: levelButtonsPositions[Model.sharedInstance.currentLevel - 1], delay: 0.5)
        }
        else {
            if !isNextSectionDisabled {
                if Model.sharedInstance.currentLevel - 1 < Model.sharedInstance.countLevels {
                    // Если перешли в меню после прохождения уровня, то запускаем анимацию перехода на след. уровень
                    if moveCharacterToNextLevel {
                        // Если последний пройденный уровень больше, чем последний максимальный
                        if Model.sharedInstance.currentLevel > Model.sharedInstance.getCountCompletedLevels() {
                            var levelFrom = Model.sharedInstance.getCountCompletedLevels() - 1
                            if Model.sharedInstance.currentLevel > 2 {
                                if !Model.sharedInstance.isCompletedLevel(levelFrom) {
                                    levelFrom -= 1
                                }
                            }
                            
                            moveToPoint(from: levelButtonsPositions[levelFrom], to: levelButtonsPositions[Model.sharedInstance.getCountCompletedLevels()], delay: 0.5)
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // Если обучение было "прервано" после 1-ого уровня
        if !moveCharacterToNextLevel && Model.sharedInstance.currentLevel == 2 && Model.sharedInstance.getCountCompletedLevels() == 1 && !Model.sharedInstance.isCompletedLevel(2) {
            modalWindowPresent()
        }
    }
    
    func characterInitial() {
        /// Задаём анимацию для ГП
        let playerAnimatedAtlas = SKTextureAtlas(named: "PlayerWalks")
        walkFrames = [UIImage]()
        let numImages = playerAnimatedAtlas.textureNames.count
        for i in 1...numImages {
            let playerTextureName = "PlayerWalks_\(i)"
            walkFrames.append(UIImage(cgImage: playerAnimatedAtlas.textureNamed(playerTextureName).cgImage()))
        }
        
        let pointCharacter = pointFor(column: characterPointStart.column, row: characterPointStart.row - (Model.sharedInstance.getCountCompletedLevels() == 0 ? distanceBetweenLevels : 0))
        let textureCharacter = UIImage(named: "PlayerStaysFront")?.cgImage
        let sizeCharacter = CGSize(width: levelTileSize.width * 0.5, height: CGFloat(textureCharacter!.height) / (CGFloat(textureCharacter!.width) / (levelTileSize.width * 0.5)))
        
        character = UIImageView(frame: CGRect(x: pointCharacter.x - sizeCharacter.width / 2, y: pointCharacter.y - sizeCharacter.height / 2, width: sizeCharacter.width, height: sizeCharacter.height))
        character.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        character.image = UIImage(named: "PlayerStaysFront")
        
        scrollView.addSubview(character)
    }
    
    func menuSettings() {
        
        /// коэф. для планшетов (настройки, найти ГП)
        var sizeForControls: CGFloat = 1
        if Model.sharedInstance.isDeviceIpad() {
            sizeForControls = 2
        }
        
        for constraint in controlsSizeConstraint {
            constraint.constant *= sizeForControls
        }
        
         // Если нахожимся на последних уровнях, то подфиксиваем так, чтобы последний уровень фиксировался по центру и не уходил дальше
        if Model.sharedInstance.countLevels - (Model.sharedInstance.getCountCompletedLevels()) < distanceBetweenLevels {
            extraCountForExtremeLevels = Model.sharedInstance.countLevels - Model.sharedInstance.getCountCompletedLevels() - distanceBetweenLevels + 1
        }
        
        boardSize.row = (Model.sharedInstance.getCountCompletedLevels() + distanceBetweenLevels + extraCountForExtremeLevels) * distanceBetweenLevels
        
        levelTileSize.width = self.view.bounds.width / CGFloat(boardSize.column)
        levelTileSize.height = levelTileSize.width
        
        tilesLayer = UIView(frame: CGRect(x: -levelTileSize.width * CGFloat(boardSize.column) / 2, y: 0, width: self.view.bounds.width, height: CGFloat(boardSize.row) * levelTileSize.height))
        
        scrollView.addSubview(tilesLayer)
        addTiles()

        if !isNextSectionDisabled {
            if Model.sharedInstance.currentLevel <= Model.sharedInstance.getCountCompletedLevels() {
                var lastLevelKoef = 0
                if Model.sharedInstance.getCountCompletedLevels() >= levelButtonsPositions.count {
                    lastLevelKoef = 1
                }
                
                characterPointStart = levelButtonsPositions[Model.sharedInstance.getCountCompletedLevels() - lastLevelKoef]
            }
            else {
                if Model.sharedInstance.currentLevel > Model.sharedInstance.countLevels {
                    characterPointStart = levelButtonsPositions.last!
                }
                else {
                    var levelFrom = Model.sharedInstance.getCountCompletedLevels() - 1
                    if Model.sharedInstance.currentLevel > 2 {
                        if moveCharacterToNextLevel {
                            if !Model.sharedInstance.isCompletedLevel(levelFrom) {
                                levelFrom -= 1
                            }
                            
                            characterPointStart = levelButtonsPositions[levelFrom]
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Почему-то было сложно сделать scroll снизу вверх, то просто перевернул на 180 слой, а потом все кнопки тоже на 180
        scrollView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        let koefisNextSectionDisabled = isNextSectionDisabled ? 1 : 0
        
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: CGFloat((Model.sharedInstance.getCountCompletedLevels() + distanceBetweenLevels + extraCountForExtremeLevels - koefisNextSectionDisabled) * distanceBetweenLevels) * levelTileSize.height)
        
        scrollView.contentOffset.y = CGFloat((Model.sharedInstance.getCountCompletedLevels() - 1) * distanceBetweenLevels) * levelTileSize.height
        
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        
        if Model.sharedInstance.lastYpositionLevels != nil {
            scrollView.contentOffset.y = Model.sharedInstance.lastYpositionLevels!
        }
    }
    
    @objc func buttonAction(sender: UIButton!) {
        let buttonSenderAction: UIButton = sender
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
        
        // Если уровень не заблокирован
        if buttonSenderAction.tag != -1 {
            Model.sharedInstance.currentLevel = buttonSenderAction.tag
            moveCharacterToNextLevel = false

            self.modalWindowPresent()
        }
    }
    
    /// Функция, которая вызывает анимацию следования ГП по кривой Безье
    func moveToPoint(from: Point, to: Point, delay: CFTimeInterval = 0) {
        // Если конечная позиция не совпадает с начальной
        if from != to {
            
            /// Конечный путь до какой-либо точки через остальные, которые попадаются на пути
            var path = (bezier: UIBezierPath(), count: 0)
            
            /// текущая Y-позиция
            var row = from.row - 1
            
            /// Кол-во кнопок между началом и концом пермещения (расстояние)
            var countButtonsThrough = (to.row - from.row) / distanceBetweenLevels
            
            // Если самое начало игры, то перемещаем на 1-ую ячейку
            if Model.sharedInstance.getCountCompletedLevels() == 0 {
                path = pathToPoint(from: from, to: to)
            }
            else {
                while row < to.row - 1 {
                    // В общем, бесполезная проверка, ибо всегда передаётся число кратное 3, а после добавляется 3, но мало ли :3
                    if row % 3 == 0 {
                        let path2point = pathToPoint(from: levelButtonsPositions[row / 3], to: levelButtonsPositions[row / 3 + 1])
                        
                        // Если последняя кнопка, то ГП должен двигаться в верную сторону
                        if countButtonsThrough == 1 {
                            if levelButtonsPositions[row / 3].column < levelButtonsPositions[row / 3 + 1].column {
                                character.transform = CGAffineTransform(scaleX: 1, y: -1)
                            }
                            else {
                                character.transform = CGAffineTransform(scaleX: -1, y: -1)
                            }
                        }
                        
                        countButtonsThrough -= 1
                        
                        path.bezier.append(path2point.bezier)
                        path.count += path2point.count
                        row += 3
                    }
                }
            }
            
            // Если предыдущая анимация ещё не закончилась
            if character.layer.animation(forKey: "movement") == nil {
                let movement = CAKeyframeAnimation(keyPath: "position")
                scrollView.isScrollEnabled = false
                
                // Анимации ходьбы ГП
                character.animationImages = walkFrames
                character.animationRepeatCount = 0
                character.animationDuration = TimeInterval(0.05 * Double(walkFrames.count))
                character.startAnimating()
                
                CATransaction.begin()
                
                // Пока ГП перемещается, то блокируем клики
                scrollView.isUserInteractionEnabled = false
                
                if to.row != 1 {
                    DispatchQueue.main.async {
                        
                        /// Время, через которое анимации начнёт воспроизводиться
                        var delayForAnimation: CFTimeInterval = 0
                        if self.moveCharacterToNextLevel {
                            delayForAnimation = delay
                        }
                        
                        UIView.animate(withDuration: 0.25 * Double(path.count), delay: delayForAnimation, options: UIViewAnimationOptions.curveLinear, animations: {
                            self.scrollView.contentOffset.y = CGFloat((Model.sharedInstance.currentLevel - 2) * self.distanceBetweenLevels) * self.levelTileSize.height
                        })
                    }
                }
                
                CATransaction.setCompletionBlock({
                    self.character.layer.position = self.pointFor(column: to.column, row: to.row)
                    self.character.layer.removeAnimation(forKey: "movement")
                    self.character.stopAnimating()
                    self.scrollView.isScrollEnabled = true
                    
                    self.modalWindowPresent()
                    self.characterPointStart = to
                    
                    self.scrollView.isUserInteractionEnabled = true
                })
                
                movement.beginTime = CACurrentMediaTime() + delay
                movement.path = path.bezier.cgPath
                movement.fillMode = kCAFillModeForwards
                movement.isRemovedOnCompletion = false
                movement.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                movement.duration = 0.25 * Double(path.count)
//                movement.rotationMode = kCAAnimationRotateAuto
                
                character.layer.add(movement, forKey: "movement")
                CATransaction.commit()
            }
        }
        else {
            self.modalWindowPresent()
            self.characterPointStart = to
        }
    }
    
    /// Функция показывает модальное окно с информацией об уровне
    func modalWindowPresent() {
        // Добавляем бг, чтобы при клике на него закрыть всё модальное окно
        modalWindowBg = UIView(frame: scrollView.bounds)
        modalWindowBg.backgroundColor = UIColor.black
        modalWindowBg.restorationIdentifier = "modalWindowBg"
        modalWindowBg.alpha = 0
        
        // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
        if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
            modalWindowBg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        }
        modalWindowBg.isUserInteractionEnabled = true
        
        scrollView.addSubview(modalWindowBg)
        scrollView.isScrollEnabled = false
        
        // Добавляем модальное окно
        modalWindow = UIView(frame: CGRect(x: scrollView.bounds.minX - 200, y: scrollView.bounds.midY - 200 / 2, width: 200, height: 200))
        modalWindow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        modalWindow.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        modalWindow.layer.cornerRadius = 15
        modalWindow.layer.shadowColor = UIColor.black.cgColor
        modalWindow.layer.shadowOffset = CGSize.zero
        modalWindow.layer.shadowOpacity = 0.35
        modalWindow.layer.shadowRadius = 10
        
        scrollView.addSubview(modalWindow)
        
        UIView.animate(withDuration: 0.215, animations: {
            self.settingsButton.alpha = 0
            self.findCharacterButton.alpha = 0
            self.modalWindowBg.alpha = 0.5
            self.modalWindow.frame.origin.x = self.scrollView.bounds.midX - self.modalWindow.frame.width / 2
        })
        
        // Если уровни без начального обучения, то можно скрыть окно с выбором уровня
        if (Model.sharedInstance.currentLevel != 1 && Model.sharedInstance.currentLevel != 2) || Model.sharedInstance.getCountCompletedLevels() > 1 {
            modalWindow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.bgClick(_:))))
        }
        
        /// Название выбранного уровня
        let levelNumberLabel = UILabel(frame: CGRect(x: 20, y: 25, width: modalWindow.frame.size.width - 40, height: 35))
        levelNumberLabel.text = "Level \(Model.sharedInstance.currentLevel)"
        
        if Model.sharedInstance.currentLevel % Model.sharedInstance.distanceBetweenSections == 0 {
            let bossNumberTitle = Model.sharedInstance.currentLevel / Model.sharedInstance.distanceBetweenSections
            levelNumberLabel.text = "BOSS #\(bossNumberTitle)"
        }
        
        levelNumberLabel.textAlignment = NSTextAlignment.left
        levelNumberLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 24)
        levelNumberLabel.textColor = UIColor.white
        modalWindow.addSubview(levelNumberLabel)
        
        // Кнопка "старт" в модальном окне, которая переносит на выбранный уровень
        let btnStart = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.bounds.midY - 50 / 2, width: modalWindow.frame.width - 40, height: 50))
        btnStart.layer.cornerRadius = 10
        btnStart.backgroundColor = UIColor.init(red: 217 / 255, green: 29 / 255, blue: 29 / 255, alpha: 1)
        btnStart.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19)
        btnStart.addTarget(self, action: #selector(startLevel), for: .touchUpInside)
        btnStart.setTitle("START", for: UIControlState.normal)
        modalWindow.addSubview(btnStart)
        
        if !Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel) {
            let countOfGemsImage = UIImageView(image: UIImage(named: "Heart"))
            countOfGemsImage.frame.size = CGSize(width: countOfGemsImage.frame.size.width * 0.75, height: countOfGemsImage.frame.size.height * 0.75)
            countOfGemsImage.frame.origin = CGPoint(x: modalWindow.frame.size.width - 35 - 20, y: 22)
            modalWindow.addSubview(countOfGemsImage)
        
            let countGemsModalWindowLabel = UILabel(frame: CGRect(x: countOfGemsImage.frame.width / 2 - 75 / 2, y: countOfGemsImage.frame.height / 2 - 50 / 2, width: 75, height: 50))
            countGemsModalWindowLabel.font = UIFont(name: "AvenirNext-Bold", size: 18)
            countGemsModalWindowLabel.text = String(Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel))
            countGemsModalWindowLabel.textAlignment = NSTextAlignment.center
            countGemsModalWindowLabel.textColor = UIColor.white
            countOfGemsImage.addSubview(countGemsModalWindowLabel)
        }
        else {
            let completedLevelLabel = UIImageView(image: UIImage(named: "Checked"))
            completedLevelLabel.frame.size = CGSize(width: 32, height: 32)
            completedLevelLabel.frame.origin = CGPoint(x: modalWindow.frame.size.width - 45, y: 22)
            modalWindow.addSubview(completedLevelLabel)
        }
        
        // Кнопка "дополнительная жизнь" или "настройки" в модальном окне в зависимости от кол-ва жизней
        let secondButton = UIButton(frame: CGRect(x: modalWindow.bounds.midX - ((modalWindow.frame.width - 40) / 2), y: modalWindow.frame.size.height - 50 - 15, width: modalWindow.frame.width - 40, height: 50))
        secondButton.layer.cornerRadius = 10
        secondButton.backgroundColor = UIColor.init(red: 165 / 255, green: 240 / 255, blue: 16 / 255, alpha: 1)
        secondButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19)
        secondButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        modalWindow.addSubview(secondButton)
        
        // Если количество жизенй на уровне меньше 0, то добавляем кнопку получения новой жизни
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) <= 0 {
            btnStart.backgroundColor = UIColor.init(red: 187 / 255, green: 36 / 255, blue: 36 / 255, alpha: 0.9)
            btnStart.removeTarget(self, action: nil, for: .allEvents)
            btnStart.addTarget(self, action: #selector(shakeBtnStart), for: .touchUpInside)
            
            secondButton.setTitle("EXTRA LIFE", for: UIControlState.normal)
            secondButton.addTarget(self, action: #selector(addExtraLife), for: .touchUpInside)
        }
        else {
            secondButton.setTitle("SETTINGS", for: UIControlState.normal)
            secondButton.addTarget(self, action: #selector(goToMenuFromModalWindow), for: .touchUpInside)
        }
    }
    
    @objc func startLevel() {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        Model.sharedInstance.lastYpositionLevels = scrollView.contentOffset.y
        
        goToLevel()
    }
    
    @objc func bgClick(_ sender: UITapGestureRecognizer) {
        if sender.view?.restorationIdentifier == "modalWindowBg" {
            SKTAudio.sharedInstance().playSoundEffect(filename: "Swish.wav")
            
            UIView.animate(withDuration: 0.215, animations: {
                self.settingsButton.alpha = 1
                self.findCharacterButton.alpha = 1
                self.modalWindow.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
                self.modalWindowBg.alpha = 0
            }, completion: { (_) in
                self.modalWindowBg.removeFromSuperview()
                self.modalWindow.removeFromSuperview()
                self.scrollView.isScrollEnabled = true
            })
        }
    }
    
    @objc func shakeBtnStart(_ button: UIButton) {
        shakeView(button)
    }
    
    @objc func shakeScreen() {
        shakeView(self.view)
        
        SKTAudio.sharedInstance().playSoundEffect(filename: "Disable.wav")
    }
    
    @objc func goToMenuFromModalWindow(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        presentMenu(dismiss: true)
    }
    
    func buyExtraLife() {
        // Отнимаем 10 драг. камней
        Model.sharedInstance.setCountGems(amountGems: -EXTRA_LIFE_PRICE)
        
        Model.sharedInstance.setLevelLives(level: Model.sharedInstance.currentLevel, newValue: Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) + 1)
        UIView.animate(withDuration: 0.215, animations: {
            self.modalWindow.frame.origin.x = self.view.bounds.minX - self.modalWindow.frame.size.width
        }, completion: { (_) in
            self.modalWindowBg.removeFromSuperview()
            
            // Ищем кнопку-уровень на scrollView
            var tileLevelSubView: UIView!
            for tileSubview in self.scrollView.subviews {
                if tileSubview.restorationIdentifier == "levelTile_\(Model.sharedInstance.currentLevel)" {
                    tileLevelSubView = tileSubview
                }
            }
            // Ищем view, который выводит состояние уровня
            for subview in tileLevelSubView.subviews {
                if subview.restorationIdentifier == "levelStateImage" {
                    subview.removeFromSuperview()
                }
            }
            
            self.modalWindowPresent()
        })
    }
    
    @objc func addExtraLife(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click_ModalWindow.wav")
        
        // Если больше 10 драг. камней, то добавляем новую жизнь
        if Model.sharedInstance.getCountGems() >= EXTRA_LIFE_PRICE {
            
            let alert = UIAlertController(title: "Buying an extra life", message: "An extra life is worth \(EXTRA_LIFE_PRICE) GEMS (you have \(Model.sharedInstance.getCountGems()) GEMS)", preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_extra_life_levels", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: "Buy one life", style: UIAlertActionStyle.default, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                self.buyExtraLife()
                
                Flurry.logEvent("Buy_extra_life_levels", withParameters: eventParams)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: "Not enough GEMS", message: "You do not have enough GEMS to buy an extra life. You need \(EXTRA_LIFE_PRICE) GEMS, but you have only \(Model.sharedInstance.getCountGems()) GEMS", preferredStyle: UIAlertControllerStyle.alert)
            
            let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Cancel_buy_extra_life_levels_not_enough_gems", withParameters: eventParams)
            })
            
            let actionOk = UIAlertAction(title: "Buy GEMS", style: UIAlertActionStyle.default, handler: { (_) in
                let eventParams = ["level": Model.sharedInstance.currentLevel, "countGems": Model.sharedInstance.getCountGems()]
                
                Flurry.logEvent("Buy_gems_extra_life_levels_not_enough_gems", withParameters: eventParams)
                
                self.presentMenu(dismiss: true)
            })
            
            alert.addAction(actionOk)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func shakeView(_ viewToShake: UIView, repeatCount: Float = 3, amplitude: CGFloat = 5) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = repeatCount
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x - amplitude, y: viewToShake.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x + amplitude, y: viewToShake.center.y))
        
        viewToShake.layer.add(animation, forKey: "position")
    }
    
    func goToLevel() {
        if Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel) > 0 {
            if Model.sharedInstance.gameScene != nil {
                Model.sharedInstance.gameScene.cleanLevel()
            }
            
            let eventParams = ["level": Model.sharedInstance.currentLevel, "isCompletedLevel": Model.sharedInstance.isCompletedLevel(Model.sharedInstance.currentLevel), "countLives": Model.sharedInstance.getLevelLives(Model.sharedInstance.currentLevel)] as [String : Any]
            
            Flurry.logEvent("Go_to_level", withParameters: eventParams)
            
            if let storyboard = storyboard {
                let gameViewController = storyboard.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
                navigationController?.pushViewController(gameViewController, animated: true)
            }
        }
    }
    
    /// Функция, которая возвращает близжайший путь между точками
    func pathToPoint(from: Point, to: Point) -> (bezier: UIBezierPath, count: Int) {
        let path = UIBezierPath()
        var count = 0
        
        path.move(to: pointFor(column: from.column, row: from.row))
        
        var direction = 1
        if to.column <= from.column {
            direction = -1
        }
        
        var col = from.column
        var row = from.row
        
        while col != to.column {
            col += direction
            path.addLine(to: pointFor(column: col, row: row))
            count += 1
        }
        
        direction = 1
        if to.row <= from.row {
            direction = -1
        }
        
        while row != to.row {
            row += direction
            path.addLine(to: pointFor(column: col, row: row))
            count += 1
        }
        
        return (bezier: path, count: count)
    }
    
    func addLevelImageState(spriteName: String = "Locked", buttonToPin: UIButton, sizeKoef: CGSize = CGSize(width: 0.275, height: 0.275)) {
        let levelStateImage = UIImageView(image: UIImage(named: spriteName))
        levelStateImage.frame.size = CGSize(width: buttonToPin.frame.size.width * sizeKoef.width, height: buttonToPin.frame.size.height * sizeKoef.height)
        levelStateImage.restorationIdentifier = "levelStateImage"
        levelStateImage.frame.origin = CGPoint(x: buttonToPin.frame.size.width - levelStateImage.frame.size.width - 5, y: buttonToPin.frame.size.height - levelStateImage.frame.size.height - 5)
        buttonToPin.addSubview(levelStateImage)
    }

    /// Функция получает значение кол-ва уровней, которые должны быть завершены. чтобы получить доступ к следующей секции
    func getCountCompleteLevelsForNextSection(_ level: Int) -> Int {
        return sections[level / Model.sharedInstance.distanceBetweenSections - 1]
    }
    
    /// Функция, считает количество пройденных уровней в интервале [0; maxLevel]
    func countCompletedLevelsForPreviousSection(_ maxLevel: Int) -> Int {
        var level = maxLevel
        
        var countOfCompletedLevels = 0
        
        while level > 0 {
            if Model.sharedInstance.isCompletedLevel(level) {
                countOfCompletedLevels += 1
            }
            
            level -= 1
        }
        
        return countOfCompletedLevels
    }
    
    func addTiles() {
        /// Флаг, который запоминает последнюю строку, на которой была вставлена кнопка уровня
        var lastRowWhereBtnAdded = Int.min
        
        /// Нужно ли заблокировать все уровни, если текущая секция не пройдена
        var isLevelsAfterSectionDisabled = false
        
        /// Позиции ячеек уровней
        var buttonsPositions = UserDefaults.standard.array(forKey: "levelsTilesPositions") as? [Int]
        
        // Если позиции для кнопок уровней не заданы
        if buttonsPositions == nil {
            for _ in 1...Model.sharedInstance.countLevels {
                Model.sharedInstance.generateTilesPosition()
            }
            buttonsPositions = UserDefaults.standard.array(forKey: "levelsTilesPositions") as? [Int]
        }
        
        var nearestBossPos = 0
        
        // -5 и 5 для того, чтобы при "bounce" были сверху и снизу ячейки
        for row in -10..<boardSize.row + 10 {
            for column in 0..<boardSize.column {
                var tileSprite: String = "center"
                var rotation: Double = 0.0
                
                if column == 0 {
                    tileSprite = "top"
                    rotation = (-90 * Double.pi / 180)
                }
                
                if column == boardSize.column - 1 {
                    tileSprite = "top"
                    rotation = (90 * Double.pi / 180)
                }
                
                let pos = pointFor(column: column, row: row)
                
                let tileImage = UIImageView(frame: CGRect(x: pos.x + self.view.bounds.width / 2 - levelTileSize.width / 2, y: pos.y - levelTileSize.height / 2, width: levelTileSize.width, height: levelTileSize.height))
                tileImage.image = UIImage(named: "Tile_\(tileSprite)")
                tileImage.transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
                tilesLayer.addSubview(tileImage)
                
                if (lastRowWhereBtnAdded != row) && (row >= 0 && row < boardSize.row + distanceBetweenLevels * distanceBetweenLevels) && ((row / distanceBetweenLevels + 1) <= Model.sharedInstance.countLevels) && (row % 3 == 0) {
                    
                    var randColumn = Int(arc4random_uniform(3)) + 1
                    if buttonsPositions != nil {
                        randColumn = buttonsPositions![row / distanceBetweenLevels]
                    }
                    
                    let buttonPos = pointFor(column: randColumn, row: row + 1)
                    
                    let button = UIButton(frame: CGRect(x: buttonPos.x - levelTileSize.width / 2, y: buttonPos.y - levelTileSize.height / 2, width: levelTileSize.width, height: levelTileSize.height))
                    
                    if row / 3 == Model.sharedInstance.getCountCompletedLevels() || ((row / 3) + 1 == Model.sharedInstance.countLevels && (Model.sharedInstance.countLevels == Model.sharedInstance.getCountCompletedLevels())) {
                        button.setBackgroundImage(UIImage(named: "Tile_center"), for: UIControlState.normal)
                    }
                    
                    var sizeLabel: CGFloat = 24
                    if Model.sharedInstance.isDeviceIpad() {
                        sizeLabel *= 2.5
                    }
                    
                    button.titleLabel?.font = UIFont(name: "Avenir Next", size: sizeLabel)
                    button.setTitle("\(row / distanceBetweenLevels + 1)", for: UIControlState.normal)
                    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                    button.tag = row / distanceBetweenLevels + 1
                    button.adjustsImageWhenHighlighted = false
                    // Переворачиваем кнопку, т. к. перевернул весь слой
                    button.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    
                    if (row > 0) && ((row / distanceBetweenLevels + 1) % Model.sharedInstance.distanceBetweenSections == 0) {
                        button.setTitle("BOSS", for: UIControlState.normal)
                    }
                    
                    var koefForLastLevel = 0
                    
                    if Model.sharedInstance.countLevels == Model.sharedInstance.getCountCompletedLevels() {
                        koefForLastLevel = 0
                    }
                    else {
                        if !moveCharacterToNextLevel {
                            koefForLastLevel = 1
                        }
                    }
                    
                    // Если уровень (который отображает кнопка) равен тому уровню, который был пройден последним, то запомнить координаты этой позиции, чтобы вывести туда персонажа
                    if row / distanceBetweenLevels + 1 == Model.sharedInstance.getCountCompletedLevels() + koefForLastLevel {
                        characterPointStart = Point(column: randColumn, row: row + 1)
                    }
                    
                    // Если уровень пройден, то добавляем соответствующую метку
                    if Model.sharedInstance.isCompletedLevel(row / distanceBetweenLevels + 1) {
                        addLevelImageState(spriteName: "Checked", buttonToPin: button)
                    }
                    
                    if (row > 0) && ((row / distanceBetweenLevels) % Model.sharedInstance.distanceBetweenSections == 0) && (row > Model.sharedInstance.getCountCompletedLevels()) {
                        /// Количество пройденных уровней [0; ближайшая граница секции]
                        let completedLevels = countCompletedLevelsForPreviousSection(row / distanceBetweenLevels - 1)
                        
                        /// Кол-во уровней, которое разблокирует новую секцию
                        let needCompleteLevelsPreviousSection = getCountCompleteLevelsForNextSection(row / distanceBetweenLevels)
                        
                        // Если не пройдено достаточное кол-во уровней, чтобы разблокировать или босс не пройден
                        if completedLevels < needCompleteLevelsPreviousSection || !Model.sharedInstance.isCompletedLevel(row / distanceBetweenLevels) {
                            isLevelsAfterSectionDisabled = true
                            
                            if Model.sharedInstance.getCountCompletedLevels() >= (row / distanceBetweenLevels - 1) {
                                isNextSectionDisabled = true
                                nearestBossPos = row / distanceBetweenLevels
                                characterPointStart = levelButtonsPositions.last!
                            }
                            
                            let textAboutLevels = "at least \(needCompleteLevelsPreviousSection - completedLevels) more levels"
                            let textAboutFinalLevel = "section's final level"
                            let ifBothTrue = (completedLevels < needCompleteLevelsPreviousSection && !Model.sharedInstance.isCompletedLevel(row / distanceBetweenLevels)) ? " and " : ""
                            let disabledSectionText = "Complete \(completedLevels < needCompleteLevelsPreviousSection ? textAboutLevels : "")\(ifBothTrue)\(!Model.sharedInstance.isCompletedLevel(row / distanceBetweenLevels) ? textAboutFinalLevel : "") to unlock next section"
                            
                            presentInfoBlock(point: Point(column: 1, row: row - 2), message: disabledSectionText)
                        }
                    }
                    
                    // Если последний уровень пройден, то выводим надпись о том, что новые уровни разрабатываются
                    if ((row / distanceBetweenLevels + 1) == Model.sharedInstance.getCountCompletedLevels()) && (Model.sharedInstance.getCountCompletedLevels() == Model.sharedInstance.countLevels) {
                        presentInfoBlock(point: Point(column: 1, row: row + 1), message: "New levels are coming. We are already designing new levels. Wait for updates")
                    }
                    
                    if (row / distanceBetweenLevels) <= Model.sharedInstance.getCountCompletedLevels() + 1 && !isLevelsAfterSectionDisabled {
                        if Model.sharedInstance.emptySavedLevelsLives() == false {
                            // Если на уровне не осталось жизней, то добавляем соответствующую метку
                            if Model.sharedInstance.getLevelLives(row / distanceBetweenLevels + 1) <= 0 {
                                addLevelImageState(spriteName: "Heart_empty-unfilled", buttonToPin: button, sizeKoef: CGSize(width: 0.275, height: 0.25))
                            }
                        }
                    }
                    else {
                        button.tag = -1
                        button.addTarget(self, action: #selector(shakeScreen), for: .touchUpInside)
                        addLevelImageState(spriteName: "Locked", buttonToPin: button, sizeKoef: CGSize(width: 0.3, height: 0.3))
                    }
                    
                    button.restorationIdentifier = "levelTile_\(button.tag)"
                    
                    levelButtonsPositions.append(Point(column: randColumn, row: row + 1))
                    scrollView.addSubview(button)
                    
                    lastRowWhereBtnAdded = row
                }
            }
        }
        
        /// Последняя ячейка, от которой отрисовывается путь
        var lastPos = Point(column: buttonsPositions!.first!, row: -15)
        
        let koefForDisabledSection = isNextSectionDisabled ? (2 - (nearestBossPos % Model.sharedInstance.getCountCompletedLevels())) : 0
        
        /// Y-координата
        var row = 1
        for pos in buttonsPositions! {
            
            var to = Point(column: pos, row: row * 3 - 2)
            if isNextSectionDisabled && row == Model.sharedInstance.getCountCompletedLevels() + 2 - koefForDisabledSection + 1 {
                to = Point(column: lastPos.column, row: lastPos.row + 1)
            }
            else {
                if row > Model.sharedInstance.getCountCompletedLevels() + 2 - koefForDisabledSection {
                    break
                }
            }
            
            var sizeCircle = CGSize(width: levelTileSize.width / 1.625, height: levelTileSize.height / 1.625)
            
            if row % Model.sharedInstance.distanceBetweenSections == 0 {
                sizeCircle = CGSize(width: levelTileSize.width, height: levelTileSize.height)
            }
            
            let pinkCircleLevelTile = UIView(frame: CGRect(origin: pointFor(column: to.column, row: to.row), size: sizeCircle))
            pinkCircleLevelTile.frame.origin.x -= sizeCircle.width / 2
            pinkCircleLevelTile.frame.origin.y -= sizeCircle.height / 2
            
            pinkCircleLevelTile.layer.backgroundColor = UIColor.init(red: 250 / 255, green: 153 / 255, blue: 137 / 255, alpha: 1).cgColor
            
            if row % Model.sharedInstance.distanceBetweenSections != 0 {
                pinkCircleLevelTile.layer.cornerRadius = pinkCircleLevelTile.frame.size.width / 2
            }
            else {
                pinkCircleLevelTile.layer.cornerRadius = pinkCircleLevelTile.frame.size.width / 7
            }
            
            if !isNextSectionDisabled || row < nearestBossPos {
                scrollView.insertSubview(pinkCircleLevelTile, at: 3)
            }

            /// Путь от последней кнопки до текущей
            let path2point = pathToPoint(from: lastPos, to: to)
            lastPos = Point(column: pos, row: row * 3 - 2)
            row += 1
            
            let layer = CAShapeLayer()
            
            layer.path = path2point.bezier.cgPath
            layer.strokeColor = UIColor.init(red: 250 / 255, green: 153 / 255, blue: 137 / 255, alpha: 1).cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineCap = kCALineCapRound
            layer.lineJoin = kCALineJoinRound
            layer.lineWidth = 7
            
            if Model.sharedInstance.isDeviceIpad() {
                layer.lineWidth *= 2
            }
            
            scrollView.layer.insertSublayer(layer, at: 4)
        }
        
        if characterPointStart == nil {
            characterPointStart = levelButtonsPositions.first!
        }
    }
    
    /// Функция, которая ппереводим координаты игрового поля в физические
    func pointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(
            x: CGFloat(column) * levelTileSize.width + levelTileSize.width / 2,
            y: CGFloat(row) * levelTileSize.height + levelTileSize.height / 2)
    }
    
    /// Функция конвертирует CGPoint в позицию на игровом поле, если клик был сделан по игровому полю
    func convertPoint(point: CGPoint) -> (success: Bool, point: Point) {
        if point.x >= 0 && point.x < CGFloat(boardSize.column) * levelTileSize.width &&
            point.y >= 0 && point.y < CGFloat(boardSize.row) * levelTileSize.height {
            return (true, Point(column: Int(point.x / levelTileSize.width), row: Int(point.y / levelTileSize.height)))
        }
        else {
            return (false, Point(column: 0, row: 0))
        }
    }
    
    /// Переход в настройки
    @IBAction func goToMenu(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        presentMenu(dismiss: true)
    }
    
    /// Найти ГП
    @IBAction func findCharacter(_ sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect(filename: "Click.wav")
        
        let koefIfLastLevel = Model.sharedInstance.countLevels == Model.sharedInstance.getCountCompletedLevels() || isNextSectionDisabled ? 1 : 0
        let point = CGPoint(x: 0, y: CGFloat((Model.sharedInstance.getCountCompletedLevels() - 1 - koefIfLastLevel) * distanceBetweenLevels) * levelTileSize.height)
        scrollView.setContentOffset(point, animated: true)
    }
    
    func presentMenu(dismiss: Bool = false) {
        if let storyboard = storyboard {
            let menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
            menuViewController.isDismissed = dismiss
            navigationController?.pushViewController(menuViewController, animated: true)
        }
    }
    
    /// Окно на scrollView, которое выводит какое-либо сообщение
    func presentInfoBlock(point: Point, message: String) {
        let pointOnScrollView = pointFor(column: point.column, row: point.row)
        let infoBlockBgView = UIView(frame: CGRect(x: pointOnScrollView.x - levelTileSize.width, y: pointOnScrollView.y + 3 * levelTileSize.height / 4, width: levelTileSize.width * 4, height: levelTileSize.height * 1.5))
        infoBlockBgView.backgroundColor = UIColor.init(red: 0, green: 109 / 255, blue: 240 / 255, alpha: 1)
        infoBlockBgView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
        infoBlockBgView.layer.cornerRadius = 15
        infoBlockBgView.layer.shadowColor = UIColor.black.cgColor
        infoBlockBgView.layer.shadowOffset = CGSize.zero
        infoBlockBgView.layer.shadowOpacity = 0.35
        infoBlockBgView.layer.shadowRadius = 10
        scrollView.addSubview(infoBlockBgView)
        
        let infoBlockLabel = UILabel(frame: CGRect(x: 10, y: 0, width: infoBlockBgView.frame.width - 20, height: infoBlockBgView.frame.height))
        
        let textAboutFinishedLastLevel = message
        
        infoBlockLabel.text = textAboutFinishedLastLevel
        infoBlockLabel.textAlignment = NSTextAlignment.center
        infoBlockLabel.numberOfLines = 3
        
        var scaleFactorForIpad: CGFloat = 1
        
        if Model.sharedInstance.isDeviceIpad() {
            scaleFactorForIpad = 2
        }
        
        infoBlockLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 18 * scaleFactorForIpad)
        infoBlockLabel.textColor = UIColor.white
        infoBlockBgView.addSubview(infoBlockLabel)
    }
    
    override var prefersStatusBarHidden: Bool {
        return Model.sharedInstance.isHiddenStatusBar()
    }
}
