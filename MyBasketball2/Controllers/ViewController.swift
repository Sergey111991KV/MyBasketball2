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

class ViewController: UIViewController {

    
    
    @IBOutlet var sceneView: ARSCNView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        sceneView.delegate = self
        
        sceneView.showsStatistics = true
        
      
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    
    func createBoard() -> SCNNode{
        
      
        let box = SCNBox(width: 1.8, height: 1.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = back
        box.materials =
        let board = SCNNode(geometry: box)
        
        return board
    }
    
    
    
    
}

     //MARK: - ARSCNViewDelegate
    extension ViewController: ARSCNViewDelegate    {
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }

}
