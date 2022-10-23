//
//  GameViewController.swift
//  GameLab
//
//  Created by Nick Wall on 10/19/22.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var stepsTaken: Int?;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup game scene
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView // the view in storyboard must be an SKView'
        
        scene.stepCount = stepsTaken;
        
        
        
        scene.viewController = self
        skView.showsFPS = true // show some debugging of the FPS
                skView.showsNodeCount = true // show how many active objects are in the scene
                skView.ignoresSiblingOrder = true // don't track who entered scene first
                scene.scaleMode = .resizeFill
                skView.presentScene(scene)

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override var prefersStatusBarHidden : Bool {
            return true
    }

}
