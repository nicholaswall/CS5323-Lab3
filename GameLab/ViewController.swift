//
//  ViewController.swift
//  GameLab
//
//  Created by Nick Wall on 10/19/22.
//

import UIKit
import GradientProgressBar
import CoreMotion

let userStepGoalPreferenceKey: String = "user_stepGoal";
let userDefaults = UserDefaults(suiteName: "default_user");


class ViewController: UIViewController {
    

    var stepGoal: Int = {
        let defaultStepGoal = 5000;
        
        // TODO: Get default preferences
        let userStepGoal = userDefaults?.integer(forKey: userStepGoalPreferenceKey) ?? 0;
        if userStepGoal > 0 {
            return userStepGoal;
        } else {
            return defaultStepGoal;
        }
    }()
    
    var stepCount: Int = 0;
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    
    
    
    @IBOutlet weak var stepGoalInput: UITextField!
    
    @IBAction func saveStepGoalButtonPressed(_ sender: UIButton) {
        if let newGoal = Int(self.stepGoalInput.text!), newGoal > 0 {
            print(newGoal)
            self.stepGoal = newGoal;
            self.updateProgress(steps: self.stepCount)
            
            userDefaults?.set(stepGoal, forKey: userStepGoalPreferenceKey)
            
            self.view.endEditing(true)
        }
    }
    
    @IBOutlet weak var stepProgressBar: GradientProgressBar!
    @IBOutlet weak var stepsTakenLabel: UILabel!
    @IBOutlet weak var stepsRemainingLabel: UILabel!
    @IBOutlet weak var stepsYesterdayLabel: UILabel!

    @IBOutlet weak var navigateToGameButton: UIButton!
    
    @IBOutlet weak var currentActivityLabel: UILabel!
    
    @IBAction func navigateToGameButtonPressed(_ sender: UIButton) {
        let destinationVC = GameViewController()
        destinationVC.stepsTaken = self.stepCount;
        
        self.performSegue(withIdentifier: "goToGame", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToGame" {
            if let destinationVC = segue.destination as? GameViewController {
                destinationVC.stepsTaken = self.stepCount
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stepGoalInput.text = String(stepGoal)
        self.stepGoalInput.keyboardType = .numberPad;
        
        
        self.stepProgressBar.animationDuration = 2.0;
        self.stepProgressBar.maskLayer.cornerRadius = 12;
        
        self.stepsYesterdayLabel.text = "Steps Taken Yesterday: 0"
        
        self.updateProgress(steps: self.stepCount)
        self.currentActivityLabel.text = "Current Activty: Unknown"

        self.startPedometerMonitoring()
        self.startActivityMonitoring()
        
    }
    
    func updateActivity(activity: CMMotionActivity) {
        
        var activityLabel = "";
        
        if activity.confidence == .high{
            if activity.unknown { activityLabel = "Unknown" }
            if activity.automotive { activityLabel = "Driving" }
            if activity.cycling { activityLabel = "Cycling" }
            if activity.running { activityLabel = "Running" }
            if activity.walking { activityLabel = "Walking" }
            if activity.stationary {activityLabel = "Stationary"}
            if activityLabel == "" { activityLabel = "Unknown" }
        }
        
        self.currentActivityLabel.text = "Current Activty: \(activityLabel)"
    }
    
    func updateProgress(steps: Int) {
        self.stepCount = steps;
        self.stepsTakenLabel.text = "Steps Taken: \(self.stepCount)"
        
        var progress = Float(stepCount) / Float(stepGoal)
        if progress < 0 { progress = 0.0 }
        if progress > 1.0 { progress = 1.0; }
        self.stepProgressBar.setProgress(progress, animated: true)

        
        if progress == 1.0 { self.navigateToGameButton.isEnabled = true }
        else { self.navigateToGameButton.isEnabled = false; }
        
        var remainingStepCount = self.stepGoal - self.stepCount;
        if remainingStepCount < 0 { remainingStepCount = 0; }
        self.stepsRemainingLabel.text = "Steps Remaining: \(remainingStepCount)"
    }
    
    func startActivityMonitoring() {
        print("Starting Activity Monitoring")
        
        if CMMotionActivityManager.isActivityAvailable() {
            
            print("Activity Monitoring is Available...")
            self.activityManager.startActivityUpdates(to: .main) {(activity:CMMotionActivity?)->Void in
                if let unwrappedActivity = activity {
                    print("Recieved activity data, currently: \(unwrappedActivity.description)")
                    DispatchQueue.main.async {
                        self.updateActivity(activity: unwrappedActivity)
                    }
                } else {
                    print("Something went wrong when handling activity change...")
                }
            }
        }
    }
    
    func startPedometerMonitoring() {
        
        print("Starting pedometer monitoring")
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .full
        dateFormatter.timeZone = .init(abbreviation: "CDT")
        
        if CMPedometer.isStepCountingAvailable(){
            let startDate = Calendar.current.startOfDay(for: Date());
            
            let nowDate = Date();
            
            print("Step Counting is Available...")
            print("Gathering Today's pedometry data from \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: nowDate))")
            
            pedometer.queryPedometerData(from: startDate, to: nowDate) {(pedData:CMPedometerData?, error:Error?)->Void in
                if let data = pedData {
                    print("Recieved pedometer data, starting steps: \(data.numberOfSteps.intValue)")
                    DispatchQueue.main.async {
                        self.updateProgress(steps: data.numberOfSteps.intValue)
                    }
                } else {
                    print("Something went wrong when gathering pedometry data...")
                }
            }
            
            if let yesterdayStart = Calendar.current.date(byAdding: .day, value: -1, to: startDate) {
                print("Gathering Yesterday's pedometry data from \(dateFormatter.string(from: yesterdayStart)) to \(dateFormatter.string(from: startDate))")

                pedometer.queryPedometerData(from: yesterdayStart, to: startDate) {
                    (pedData: CMPedometerData?, error: Error?) ->Void in
                    if let data = pedData {
                        print("Recieved yesterday's pedometer data: steps: \(data.numberOfSteps.intValue)")
                        DispatchQueue.main.async {
                            self.stepsYesterdayLabel.text = "Steps Taken Yesterday: \(data.numberOfSteps.intValue)"
                        }
                    } else {
                        print("Something went wrong when gathering yesterday's pedometry data...")
                    }
                }
            }
            
            
            pedometer.startUpdates(from: startDate)
            {(pedData:CMPedometerData?, error:Error?)->Void in
                if let data = pedData {
                    print("Recieved pedometer data update... \(data.numberOfSteps.intValue)")
                    DispatchQueue.main.async {
                        self.updateProgress(steps: data.numberOfSteps.intValue)
                    }
                } else {
                    print("Something went wrong when gathering pedometry data...")
                }
            }
        }
    }


}

