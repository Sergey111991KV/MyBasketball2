//
//  ViewController.swift
//  MyBasketball2
//
//  Created by Сергей Косилов on 13/07/2019.
//  Copyright © 2019 Сергей Косилов. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController,SCNPhysicsContactDelegate{

    // MARK: - Outlets
    @IBOutlet weak var labelCount: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    
    
      // MARK: - Variables
    var isHoodPlaced = false{
        didSet{
            if isHoodPlaced{
                guard  let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration else {return}
                configuration.planeDetection = []
                sceneView.session.run(configuration)
            }
        }
    }
    
    var scoreResult = 0
    var firstRing = 0
    var secondRing = 0
    
      // MARK: - ViewController functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
       sceneView.scene.physicsWorld.contactDelegate = self
        
        sceneView.delegate = self
        
        sceneView.showsStatistics = true
        
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    
    
     // MARK: - Tapped Action
    @IBAction func screenTaped(_ sender: UITapGestureRecognizer) {
        
        if isHoodPlaced {
            addBall()
           
        } else{
           
    
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if let nearestResult = hitTestResult.first{
            
            createBoard(result: nearestResult)
            isHoodPlaced = true
            
        }
    }
    
    }
    
     // MARK: - Create Nodes
    func addBall(){
        guard let frame = sceneView.session.currentFrame else{ return}
        let sphere = SCNSphere(radius: 0.25)
        let material = SCNMaterial()
        let ballMaterial = UIImage(named: "SceneKit Asset Catalog.scnassets/ball texture.jpg")!
        material.diffuse.contents = ballMaterial
        sphere.materials = [material]
        let ball = SCNNode(geometry: sphere)
        ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        let transform = SCNMatrix4(frame.camera.transform)
        ball.transform = transform
        let power = Float(10)
        let force = SCNVector3(-transform.m31 * power, -transform.m32 * power, -transform.m33 * power)
        ball.physicsBody?.applyForce(force, asImpulse: true)
        ball.name = "Ball"
        ball.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
        ball.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
       
        sceneView.scene.rootNode.addChildNode(ball)

    }
    
    func createBoard(result: ARHitTestResult) {
       let textBoard = SCNText(string: String(scoreResult), extrusionDepth: 0.2)
        
      textBoard.firstMaterial?.diffuse.contents = UIColor.red
        let textNode = SCNNode(geometry: textBoard)
        let box = SCNBox(width: 1.8, height: 1.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        let backboard = UIImage(named: "SceneKit Asset Catalog.scnassets/backboard.jpg")!
        material.diffuse.contents = backboard
        box.materials = [material]
        let board = SCNNode(geometry: box)
        
        let mainTorus = SCNTorus(ringRadius: 0.45, pipeRadius: 0.01)
        let secondTorus = SCNTorus(ringRadius: 0.30, pipeRadius: 0.01)
        secondTorus.firstMaterial?.diffuse.contents = UIColor.black
        mainTorus.firstMaterial?.diffuse.contents = UIColor.red
        let mainTorusNode = SCNNode(geometry: mainTorus)
        let secondTorusNode = SCNNode(geometry: secondTorus)
        secondTorusNode.position.y = -0.50
        secondTorusNode.position.z = 0.45
        mainTorusNode.position.y = -0.25
        mainTorusNode.position.z = 0.45
        
        textNode.scale = SCNVector3(0.2, 0.2, 0)
        mainTorusNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: mainTorusNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
         secondTorusNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: secondTorusNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
         board.addChildNode(secondTorusNode)
        board.addChildNode(mainTorusNode)
        board.addChildNode(textNode)
        board.simdTransform = result.worldTransform
    
        board.eulerAngles.x -= .pi/2
        board.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: board))
        secondTorusNode.name = "RingSecond"
        mainTorusNode.name = "Ring"
        mainTorusNode.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
        mainTorusNode.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
        secondTorusNode.physicsBody?.categoryBitMask = CollisionCategory.otherCategory.rawValue
        secondTorusNode.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
        sceneView.scene.rootNode.addChildNode(board)
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Wall"{
                node.removeFromParentNode()
            }
        }
        

        
    }
    
    func createWall(planeAnchor: ARPlaneAnchor) -> SCNNode{
        let extent = planeAnchor.extent
        let width = CGFloat(extent.x)
        let height = CGFloat(extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIColor.red
        let wall = SCNNode(geometry: plane)
        wall.name = "Wall"
        wall.eulerAngles.x = -.pi/2
        wall.opacity = 0.125
        
        return wall
    }
    
    
    
    func createBomb(){
        let sphera = SCNSphere(radius: 0.3)
        let material = SCNMaterial()
        let colorSphere = UIColor.black
        material.diffuse.contents = colorSphere
        sphera.materials = [material]
        let bomb = SCNNode(geometry: sphera)
       
        let distanses = Float(signOf: 1.0, magnitudeOf: 10.0)
        bomb.position = SCNVector3(-distanses.arc4random, distanses.arc4random / 3, -distanses.arc4random)
        bomb.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: bomb, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        bomb.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
        bomb.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
        bomb.physicsBody?.isAffectedByGravity = false
        bomb.name = "Bomb"
            sceneView.scene.rootNode.addChildNode(bomb)
    }
    
    
     // MARK: - Collision func
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print ( " ** Collision !! "  + contact.nodeA.name!  +  " hit "  + contact.nodeB.name! )
        print(firstRing,secondRing)
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            
            if (contact.nodeA.name! == "Ball" || contact.nodeB.name! == "Ring") {
                if secondRing == 1{ return}else{
                    firstRing = 1
                }
            }else{if (contact.nodeA.name! == "Ball" || contact.nodeB.name! == "Bomb"){
                   scoreResult = 0
                DispatchQueue.main.async {
                 
                    self.labelCount.text = String(self.scoreResult);
                    self.sceneView.reloadInputViews()
                    print(self.scoreResult)
                }           }}
        };
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.otherCategory.rawValue{
            if (contact.nodeA.name! == "Ball" || contact.nodeB.name! == "RingSecond") {
                
                
                if firstRing == 1{
                    scoreResult += 1
                    firstRing = 0
                    
                    DispatchQueue.main.async {
                      self.createBomb()
                        contact.nodeA.physicsBody?.categoryBitMask = CollisionCategory.defaultCategory.rawValue;       self.labelCount.text = String(self.scoreResult)
                        self.sceneView.reloadInputViews()
                        print(self.scoreResult)
                    }
                    
                }
                
            }
        }
        
    }
    
    
    
   

}
    
    


     //MARK: - ARSCNViewDelegate
    extension ViewController: ARSCNViewDelegate    {
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return}
            let wall = createWall(planeAnchor: planeAnchor)
            node.addChildNode(wall)
            }
        

}












struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let missileCategory = CollisionCategory (rawValue: 1 << 0)
    static let targetCategory = CollisionCategory (rawValue: 1 << 1)
    static let otherCategory = CollisionCategory (rawValue: 1 << 2)
    static let defaultCategory = CollisionCategory (rawValue: 1 << 3)
    
}

extension Float{
    var arc4random: Float{
        if self > 0{
            return Float(arc4random_uniform(UInt32(self)))}
        else if self < 0 {
            return -Float(arc4random_uniform(UInt32(self))) }
        else {
            return 0
        }
    }
}
