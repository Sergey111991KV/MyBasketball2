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

    
    @IBOutlet weak var labelCount: UILabel!
    
    @IBOutlet var sceneView: ARSCNView!
    
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
        ball.physicsBody?.contactTestBitMask = CollisionCategory.secondTargetCategory.rawValue
        
        print( ball.physicsBody?.collisionBitMask)
        sceneView.scene.rootNode.addChildNode(ball)

    }
    
    func createBoard(result: ARHitTestResult) {
     //   let textBoard = SCNText(string: <#T##Any?#>, extrusionDepth: <#T##CGFloat#>)
      
        let box = SCNBox(width: 1.8, height: 1.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        let backboard = UIImage(named: "SceneKit Asset Catalog.scnassets/backboard.jpg")!
        material.diffuse.contents = backboard
        box.materials = [material]
        let board = SCNNode(geometry: box)
        
        let mainTorus = SCNTorus(ringRadius: 0.45, pipeRadius: 0.01)
        let secondTorus = SCNTorus(ringRadius: 0.45, pipeRadius: 0.01)
        secondTorus.firstMaterial?.diffuse.contents = UIColor.black
        mainTorus.firstMaterial?.diffuse.contents = UIColor.red
        let mainTorusNode = SCNNode(geometry: mainTorus)
        let secondTorusNode = SCNNode(geometry: secondTorus)
        secondTorusNode.position.y = -0.30
        secondTorusNode.position.z = 0.45
        mainTorusNode.position.y = -0.25
        mainTorusNode.position.z = 0.45
        mainTorusNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: mainTorusNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
         mainTorusNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: mainTorusNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
         board.addChildNode(secondTorusNode)
        board.addChildNode(mainTorusNode)
        board.simdTransform = result.worldTransform
    
        board.eulerAngles.x -= .pi/2
        board.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: board))
        secondTorusNode.name = "RingSecond"
        mainTorusNode.name = "Ring"
        mainTorusNode.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
        mainTorusNode.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
        secondTorusNode.physicsBody?.categoryBitMask = CollisionCategory.secondTargetCategory.rawValue
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
    
    
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print ( " ** Collision !! "  + contact.nodeA.name!  +  " hit "  + contact.nodeB.name! )
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.missileCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.secondTargetCategory.rawValue {
            
          
               return
        } else{ if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.missileCategory.rawValue
            }
            DispatchQueue.main.async {
               
             
                self.labelCount.text = String(self.scoreResult)
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
    static let secondTargetCategory = CollisionCategory ( rawValue: 1 << 2)
    
}
