//
//  ARViewController.swift
//  projectA
//
//  Created by Shivachandra Javalagi on 04/01/18.
//  Copyright © 2018 Shivachandra Javalagi. All rights reserved.
//

import ARKit
import MapKit
import CoreLocation

class ARViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var userLocation = CLLocation()
    var objectLocation = CLLocation()
    var distanceToObject : Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("User Location from Map: %f %f", userLocation.coordinate.latitude, userLocation.coordinate.longitude)
        print("Object Location from Map: %f %f", objectLocation.coordinate.latitude, objectLocation.coordinate.longitude)
        
        // NOTE: uncomment below line to add box geometry
        // addBox()
        
        addBall()   //add 3d-object (dae file format)
    }
    
    func addBox() {
        
       let boxGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let boxNode = SCNNode()
        boxNode.geometry = boxGeometry
        boxGeometry.firstMaterial?.diffuse.contents = UIColor.red
        
        self.getdistance()
        //boxNode.position = SCNVector3(0, 0, 0) //to test
        boxNode.position = translateNode(userLocation,objectLocation)
        
        let scene = SCNScene()
        scene.rootNode.addChildNode(boxNode)
        sceneView.scene = scene
    }
    
    func addBall() {
        let ballScene = SCNScene(named: "art.scnassets/ball.dae")!
        let ballNode = ballScene.rootNode.childNodes[0]

        self.getdistance()
        ballNode.position = translateNode(userLocation,objectLocation)
        
        let scene = SCNScene()
        scene.rootNode.addChildNode(ballNode)
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        
        //Set y-axis to the direction of gravity as detected by the device, and the x-axis and z-axis to the longitude and latitude directions as measured by Location Services.
        configuration.worldAlignment = .gravityAndHeading
        
        // run session
        sceneView.session.run(configuration)
    }
    
    //calculate distance between user and object locations
    func getdistance() {
        self.distanceToObject = Float(objectLocation.distance(from: self.userLocation))
        print("Distance = %f",self.distanceToObject)
    }
    
    //Reference Material:
    //https://medium.com/journey-of-one-thousand-apps/arkit-and-corelocation-part-two-7b045fb1d7a1
    func translateNode (_ userLocation: CLLocation, _ objectLocation : CLLocation) -> SCNVector3 {
        let locationTransform =
            transformMatrix(matrix_identity_float4x4, userLocation, objectLocation)
        return positionFromTransform(locationTransform)
    }
    
    func positionFromTransform(_ transform: simd_float4x4) -> SCNVector3 {
        return SCNVector3Make(
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z
        )
    }
    
    func transformMatrix(_ matrix: simd_float4x4, _ userLocation: CLLocation, _ objectLocation: CLLocation) -> simd_float4x4 {
        let bearing = bearingBetweenLocations(userLocation, objectLocation)
        let rotationMatrix = rotateAroundY(matrix_identity_float4x4, Float(bearing))
        
        let position = vector_float4(0.0, 0.0, -distanceToObject, 0.0)
        let translationMatrix = getTranslationMatrix(matrix_identity_float4x4, position)
        
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        
        return simd_mul(matrix, transformMatrix)
    }
    
    //rotate based on actual direction of object
    func rotateAroundY(_ matrix: simd_float4x4, _ degrees: Float) -> simd_float4x4 {
        var matrix = matrix
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    func getTranslationMatrix(_ matrix: simd_float4x4, _ translation : vector_float4) -> simd_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    
    //Haversine Formula distance = atan2 ( X, Y )
    //X equals: sin(long2 - long1) * cos(long2)
    //Y equals:cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(long2 - long1)
    func bearingBetweenLocations(_ originLocation: CLLocation, _ objectLocation: CLLocation) -> Double {
        let lat1 = originLocation.coordinate.latitude * .pi / 180
        let lon1 = originLocation.coordinate.longitude * .pi / 180
        let lat2 = objectLocation.coordinate.latitude * .pi / 180
        let lon2 = objectLocation.coordinate.longitude * .pi / 180
        let longitudeDiff = lon2 - lon1
        let y = sin(longitudeDiff) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longitudeDiff);
        return atan2(y, x)
    }
    
    func scaleNode (_ location: CLLocation) -> SCNVector3 {
        let scale = min( max( Float(1000/distanceToObject), 1.5 ), 3 )
        return SCNVector3(x: scale, y: scale, z: scale)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension ARViewController: ARSKViewDelegate {
    func session(_ session: ARSession,
                 didFailWithError error: Error) {
        print("Session Failed - probably due to lack of camera access")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session resumed")
        sceneView.session.run(session.configuration!,
                              options: [.resetTracking,
                                        .removeExistingAnchors])
    }
}
