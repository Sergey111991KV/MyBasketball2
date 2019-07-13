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

class ViewController: UIViewController{

    
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
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
        let transform = frame.camera.transform
        sceneView.scene.rootNode.addChildNode(ball)
        
    }
    
    func createBoard(result: ARHitTestResult) {
        
      
        let box = SCNBox(width: 1.8, height: 1.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        let backboard = UIImage(named: "SceneKit Asset Catalog.scnassets/backboard.jpg")!
        material.diffuse.contents = backboard
        box.materials = [material]
        let board = SCNNode(geometry: box)
        
        let mainTorus = SCNTorus(ringRadius: 0.45, pipeRadius: 0.01)
        
        mainTorus.firstMaterial?.diffuse.contents = UIColor.red
        let mainTorusNode = SCNNode(geometry: mainTorus)
        mainTorusNode.position.y = -0.25
        mainTorusNode.position.z = 0.45
        board.addChildNode(mainTorusNode)
        board.simdTransform = result.worldTransform
    
        board.eulerAngles.x = -.pi
     
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
    
    
}

     //MARK: - ARSCNViewDelegate
    extension ViewController: ARSCNViewDelegate    {
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return}
            let wall = createWall(planeAnchor: planeAnchor)
            node.addChildNode(wall)
            }
        

}
