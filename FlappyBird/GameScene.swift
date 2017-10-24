import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
	
	var scrollNode:SKNode!
	var wallNode:SKNode!
	var bird:SKSpriteNode!
	var itemNode:SKNode!
	
	var groundTexture:SKTexture!
	
	// 衝突判定カテゴリー
	let birdCategory: UInt32 = 1 << 0       // 0...00001
	let groundCategory: UInt32 = 1 << 1     // 0...00010
	let wallCategory: UInt32 = 1 << 2       // 0...00100
	let scoreCategory: UInt32 = 1 << 3      // 0...01000
	
	// スコア
	var score = 0
	var scoreLabelNode:SKLabelNode!
	var bestScoreLabelNode:SKLabelNode!
	let userDefaults:UserDefaults = UserDefaults.standard
	
	
	// SKView上にシーンが表示されたときに呼ばれるメソッド
	override func didMove(to view: SKView) {
		
		// 重力を背景色を設定
		physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
		physicsWorld.contactDelegate = self
		
		// 背景色を設定
		backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
		
		// スクロールするスプライトの親ノード
		scrollNode = SKNode()
		addChild(scrollNode)
		
		// 壁用のノード
		wallNode = SKNode()
		scrollNode.addChild(wallNode)
		
		// アイテムのノード
		itemNode = SKNode()
		scrollNode.addChild(itemNode)
		
		// 各種スプライトを生成する処理をメソッドに分割
		setupGround()
		setupCloud()
		setupWall()
		setupBird()
		wait1sec()
		setupItem()
		
		setupScoreLabel()
	}
	
	func setupItem() {
		// 壁の画像を読み込む
		let itemTexture = SKTexture(imageNamed: "item")
		itemTexture.filteringMode = SKTextureFilteringMode.linear
		
		// 移動する距離を計算
		let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
		
		// 画面外まで移動するアクションを作成
		let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
		
		// 自身を取り除くアクションを作成
		let removeItem = SKAction.removeFromParent()
		
		// 2つのアニメーションを順に実行するアクションを作成
		let itemAnimation = SKAction.sequence([moveItem, removeItem])
		
		// 壁を生成するアクションを作成
		let createItemAnimation = SKAction.run({
			// 壁関連のノードを乗せるノードを作成
			let item = SKNode()
			item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
			item.zPosition = -50.0 // 雲より手前、地面より奥
			
			let xP = CGFloat( movingDistance / 4  )
			
			
			// 壁のY座標を上下ランダムにさせるときの最大値
			let random_y_range = self.frame.size.height - self.groundTexture.size().height - itemTexture.size().height
			
			// 下の壁のY軸の下限
			let under_wall_lowest_y = UInt32( self.groundTexture.size().height + itemTexture.size().height / 2)
			
			// 1〜random_y_rangeまでのランダムな整数を生成
			let random_y = arc4random_uniform( UInt32(random_y_range) )
			
			// Y軸の下限にランダムな値を足して、下の壁のY座標を決定
			let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
			
			// 下側の壁を作成
			let under = SKSpriteNode(texture: itemTexture)
			under.position = CGPoint(x: 0.0, y: under_wall_y)
			item.addChild(under)
			
			// スプライトに物理演算を設定する
			under.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
			under.physicsBody?.categoryBitMask = self.wallCategory    // ←追加
			
			// 衝突の時に動かないように設定する
			under.physicsBody?.isDynamic = false
			
//			// スコアアップ用のノード --- ここから ---
//			let scoreNode = SKNode()
//			scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
//			scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
//			scoreNode.physicsBody?.isDynamic = false
//			scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
//			scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
//			
//			item.addChild(scoreNode)
//			// --- ここまで追加 ---
			
			item.run(itemAnimation)
			
			self.itemNode.addChild(item)
		})
		
		
		// 次の壁作成までの待ち時間のアクションを作成
		let waitAnimation = SKAction.wait(forDuration: 2)
		
		// 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
		let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
		
		itemNode.run(repeatForeverAnimation)
	}
	
	func wait1sec() {
		let waitAnimationB = SKAction.wait(forDuration: 10)
		itemNode.run(waitAnimationB)
	}
	
	
	func setupGround() {
		// 地面の画像を読み込む
		groundTexture = SKTexture(imageNamed: "ground")
		groundTexture.filteringMode = SKTextureFilteringMode.nearest
		
		// 必要な枚数を計算
		let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
		
		// スクロールするアクションを作成
		// 左方向に画像一枚分スクロールさせるアクション
		let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5.0)
		
		// 元の位置に戻すアクション
		let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
		
		// 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
		let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
		
		// groundのスプライトを配置する
		stride(from: 0.0, to: needNumber, by: 1.0).forEach { i in
			let sprite = SKSpriteNode(texture: groundTexture)
			
			// スプライトの表示する位置を指定する
			sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)
			
			// スプライトにアクションを設定する
			sprite.run(repeatScrollGround)
			
			// スプライトに物理演算を設定する
			sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
			
			// 衝突のカテゴリー設定
			sprite.physicsBody?.categoryBitMask = groundCategory
			
			// 衝突の時に動かないように設定する
			sprite.physicsBody?.isDynamic = false
			
			// スプライトを追加する
			scrollNode.addChild(sprite)
		}
	}
	
	
	func setupCloud() {
		let cloudTextue = SKTexture(imageNamed: "cloud")
		cloudTextue.filteringMode = SKTextureFilteringMode.nearest
		
		let needCloudNunber = 2.0 + (frame.size.width / cloudTextue.size().width)
		
		let moveCloud = SKAction.moveBy(x: -cloudTextue.size().width, y: 0, duration: 20.0)
		
		let resetCloud = SKAction.moveBy(x: cloudTextue.size().width, y: 0, duration: 20.0)
		
		let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
		
		stride(from: 0.0, to: needCloudNunber, by: 1.0).forEach { i in
			let sprite = SKSpriteNode(texture: cloudTextue)
			sprite.zPosition = -100
			
			sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTextue.size().height / 2)
			
			sprite.run(repeatScrollCloud)
			
			scrollNode.addChild(sprite)
			
		}
	}
	
	
	func setupWall() {
		// 壁の画像を読み込む
		let wallTexture = SKTexture(imageNamed: "wall")
		wallTexture.filteringMode = SKTextureFilteringMode.linear
		
		// 移動する距離を計算
		let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
		
		// 画面外まで移動するアクションを作成
		let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
		
		// 自身を取り除くアクションを作成
		let removeWall = SKAction.removeFromParent()
		
		// 2つのアニメーションを順に実行するアクションを作成
		let wallAnimation = SKAction.sequence([moveWall, removeWall])
		
		// 壁を生成するアクションを作成
		let createWallAnimation = SKAction.run({
			// 壁関連のノードを乗せるノードを作成
			let wall = SKNode()
			wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
			wall.zPosition = -50.0 // 雲より手前、地面より奥
			
			// 画面のY軸の中央値
			let center_y = self.frame.size.height / 2
			// 壁のY座標を上下ランダムにさせるときの最大値
			let random_y_range = self.frame.size.height / 4
			// 下の壁のY軸の下限
			let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
			// 1〜random_y_rangeまでのランダムな整数を生成
			let random_y = arc4random_uniform( UInt32(random_y_range) )
			// Y軸の下限にランダムな値を足して、下の壁のY座標を決定
			let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
			
			// キャラが通り抜ける隙間の長さ
			let slit_length = self.frame.size.height / 6
			
			// 下側の壁を作成
			let under = SKSpriteNode(texture: wallTexture)
			under.position = CGPoint(x: 0.0, y: under_wall_y)
			wall.addChild(under)
			
			// スプライトに物理演算を設定する
			under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
			under.physicsBody?.categoryBitMask = self.wallCategory    // ←追加
			
			// 衝突の時に動かないように設定する
			under.physicsBody?.isDynamic = false
			
			// 上側の壁を作成
			let upper = SKSpriteNode(texture: wallTexture)
			upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
			
			// スプライトに物理演算を設定する
			upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
			upper.physicsBody?.categoryBitMask = self.wallCategory    // ←追加
			
			// 衝突の時に動かないように設定する
			upper.physicsBody?.isDynamic = false
			
			wall.addChild(upper)
			
			// スコアアップ用のノード --- ここから ---
			let scoreNode = SKNode()
			scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
			scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
			scoreNode.physicsBody?.isDynamic = false
			scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
			scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
			
			wall.addChild(scoreNode)
			// --- ここまで追加 ---
			
			wall.run(wallAnimation)
			
			self.wallNode.addChild(wall)
		})
		
		// 次の壁作成までの待ち時間のアクションを作成
		let waitAnimation = SKAction.wait(forDuration: 2)
		
		// 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
		let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
		
		wallNode.run(repeatForeverAnimation)
	}
	
	
	func setupBird() {
		// 鳥の画像を2種類読み込む
		let birdTextureA = SKTexture(imageNamed: "bird_a")
		birdTextureA.filteringMode = SKTextureFilteringMode.linear
		let birdTextureB = SKTexture(imageNamed: "bird_b")
		birdTextureB.filteringMode = SKTextureFilteringMode.linear
		
		// 2種類のテクスチャを交互に変更するアニメーションを作成
		let texuresAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
		let flap = SKAction.repeatForever(texuresAnimation)
		
		// スプライトを作成
		bird = SKSpriteNode(texture: birdTextureA)
		bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
		
		// 物理演算を設定
		bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
		
		// 衝突した時に回転させない
		bird.physicsBody?.allowsRotation = false
		
		// 衝突のカテゴリー設定
		bird.physicsBody?.categoryBitMask = birdCategory
		bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
		bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
		
		// アニメーションを設定
		bird.run(flap)
		
		// スプライトを追加する
		addChild(bird)
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if scrollNode.speed > 0 {
			// 鳥の速度をゼロにする
			bird.physicsBody?.velocity = CGVector.zero
			
			// 鳥に縦方向の力を与える
			bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
		} else if bird.speed == 0 { // --- ここから ---
			restart()
		}
	}
	
//	// SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
//	func didBegin(_ contact: SKPhysicsContact) {
//		// ゲームオーバーのときは何もしない
//		if scrollNode.speed <= 0 {
//			return
//		}
//		
//		if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
//			// スコア用の物体と衝突した
//			print("ScoreUp")
//			score += 1
//			scoreLabelNode.text = "Score:\(score)"
//			
//			// ベストスコア更新か確認する
//			var bestScore = userDefaults.integer(forKey: "BEST")
//			if score > bestScore {
//				bestScore = score
//				bestScoreLabelNode.text = "Best Score:\(bestScore)"
//				userDefaults.set(bestScore, forKey: "BEST")
//				userDefaults.synchronize()
//			}
//		} else {
//			// 壁か地面と衝突した
//			print("GameOver")
//			
//			// スクロールを停止させる
//			scrollNode.speed = 0
//			
//			bird.physicsBody?.collisionBitMask = groundCategory
//			
//			let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
//			bird.run(roll, completion:{
//				self.bird.speed = 0
//			})
//		}
//	}
	
	func restart() {
		score = 0
		scoreLabelNode.text = String("Score:\(score)")
		
		bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
		bird.physicsBody?.velocity = CGVector.zero
		bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
		bird.zRotation = 0.0
		
		wallNode.removeAllChildren()
		
		bird.speed = 1
		scrollNode.speed = 1
	}
	
	
	func setupScoreLabel() {
		score = 0
		scoreLabelNode = SKLabelNode()
		scoreLabelNode.fontColor = UIColor.black
		scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
		scoreLabelNode.zPosition = 100 // 一番手前に表示する
		scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
		scoreLabelNode.text = "Score:\(score)"
		self.addChild(scoreLabelNode)
		
		bestScoreLabelNode = SKLabelNode()
		bestScoreLabelNode.fontColor = UIColor.black
		bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
		bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
		bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
		
		let bestScore = userDefaults.integer(forKey: "BEST")
		bestScoreLabelNode.text = "Best Score:\(bestScore)"
		self.addChild(bestScoreLabelNode)
	}
	
}





























// end
