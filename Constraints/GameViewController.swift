//
//  GameViewController.swift
//  Constraints
//
//  Created by Mikael Deurell on 2019-05-10.
//  Copyright © 2019 Mikael Deurell. All rights reserved.
//

import SceneKit
import QuartzCore
import SceneKit.ModelIO

class GameViewController: NSViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    var dotNode: SCNNode!
    var sphereNode: SCNNode!
    
    var dotNodes: [SCNNode]!
    var sphereNodes: [SCNNode]!
    var bezierNode: SCNNode!
    var bezierShape: SCNShape!
    
    var mPosition: simd_float3!
    
    var mTick: Float!
    
    var mPoints: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mPoints = 16
        
        mPosition = [0,0,0]
        mTick = 0
        scnView = self.view as? SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        
        scnScene = SCNScene()
        scnScene.background.contents = NSColor.black
        scnView.scene = scnScene
    
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x:0, y:0, z:100)
        cameraNode.camera?.zFar = 500
        scnScene.rootNode.addChildNode(cameraNode)
        
        let node = SCNNode()
        node.name = "PlaneNode"
        scnScene.rootNode.addChildNode(node)
        
        scnView.delegate = self
        scnView.rendersContinuously = true
        
        setupNodes()
    }
    
    func duplicateNode(node: SCNNode) -> SCNNode {
        let newNode:SCNNode = node.clone()
        newNode.geometry = node.geometry
        return newNode
    }
    
    func createNode() -> (dot: SCNNode, sphere: SCNNode) {
        let mdlDot = MDLMesh(icosahedronWithExtent: [1.5,1.5,1.5], inwardNormals: false, geometryType: .lines, allocator: nil)
        let dotNode = SCNNode(mdlObject: mdlDot)
        dotNode.simdPosition = [0,0,0]
        let dotMtrl = dotNode.geometry?.materials.first
        dotMtrl?.lightingModel = .phong
        dotMtrl?.metalness.contents = 1.0
        
        dotMtrl?.diffuse.contents = NSColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 1.0)
        
        let mdlSphere = MDLMesh(sphereWithExtent: [4,4,4], segments: [10,10], inwardNormals: false, geometryType: .lines, allocator: nil)
        let sphereNode = SCNNode(mdlObject: mdlSphere)
        sphereNode.simdPosition = [0,0,0]
        let sphereMtrl = sphereNode.geometry?.materials.first
        sphereMtrl?.lightingModel = .constant
        sphereMtrl?.diffuse.contents = NSColor.lightGray
        
        return (dotNode, sphereNode)
    }
    
    func setupNodes() {
        let root = scnScene.rootNode.childNode(withName: "PlaneNode", recursively: true)!
        
        sphereNodes = [SCNNode]()
        dotNodes = [SCNNode]()
        
        for _ in 0...mPoints-1 {
            let newNodes = createNode()
            sphereNodes.append(newNodes.sphere)
            dotNodes.append(newNodes.dot)
            root.addChildNode(newNodes.sphere)
            root.addChildNode(newNodes.dot)
        }
        
        bezierShape = SCNShape()
        bezierNode = SCNNode(geometry: bezierShape)
        bezierNode.position = SCNVector3(x: 0, y: 0, z: 0);
        scnScene.rootNode.addChildNode(bezierNode)
    }
    
    func ConstrainDistance(point:simd_float3, anchor:simd_float3, distance:Float) -> simd_float3 {
        return (simd_normalize(point - anchor) * distance) + anchor;
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
         
        mTick = mTick + Float.pi/180
        mPosition.x = 64 * cos(2.1*mTick) + 32 * cos(0.2*mTick)
        mPosition.y = 64 * cos(-1.2*mTick) + 64 * sin(0.7*mTick)
        mPosition.z = 32 * sin(1.3*mTick) - 32 * sin(-0.3*mTick)
        
        dotNodes[0].simdPosition = mPosition
        sphereNodes[0].simdPosition = mPosition
        
        for i in 1...dotNodes.count-1 {
            let dotPos = ConstrainDistance(point: dotNodes[i].simdPosition, anchor: dotNodes[i-1].simdPosition, distance: 4)
            dotNodes[i].simdPosition = dotPos
            sphereNodes[i].simdPosition = dotPos
        }
    
        dotNodes[dotNodes.count-1].simdPosition = [0,0,0]
        sphereNodes[dotNodes.count-1].simdPosition = [0,0,0]
        for i in stride(from:dotNodes.count-1,through:1,by:-1){
            let dotPos = ConstrainDistance(point: dotNodes[i-1].simdPosition, anchor: dotNodes[i].simdPosition, distance: 4)
            dotNodes[i-1].simdPosition = dotPos
            sphereNodes[i-1].simdPosition = dotPos
        }
        
        
        
        //cameraNode.simdPosition = sphereNodes[0].simdPosition
        //cameraNode.look(at: sphereNodes[4].position)
    }
}


