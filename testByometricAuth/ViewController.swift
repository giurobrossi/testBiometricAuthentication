
import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func authButton(_ sender: Any) {

        let context = LAContext()
        
        if #available(iOS 10, *) {
            // NB: Passing empty string or nil, it shows default label "Cancel"
            context.localizedCancelTitle = "Abort"
        }
        
        // NB 1: If .deviceOwnerAuthentication it fallbacks to PASSCODE.
        // NB 2: if commented, non fa apparire il tasto di fallback che porta allo userFallback in alternativa allo userCancel. Apparirà al 2 tentativo non riuscito, il tasto di sistema "Enter Password" che porta sempre alla gestione dello userFallback
        // NB 3: Se stringa vuota, il tasto viene nescosto del tutto.
        context.localizedFallbackTitle = "Fallback"
        
        var canEvaluateError: NSError?
        // da iOS 11 in poi, tutti i device hanno un dispositivo biometrico.
        // In questo caso quindi, context.canEvaluatePolicy() sarà FALSE  se:
        // a. NON sia attivato il permesso per l'aut. biometrica. In tal caso nel blocco ELSE (canEvaluatePolicyErrorMessage) viene gestito il caso LAError.biometryNotAvailable ove context.biometryType = 1 o 2 (es. ha touch id, ma non ha dato il permesso)
        // b. Componente biometrico non enrollato --> LAError.biometryNotEnrolled
        // Se invece siamo prima di iOS 11, i device potevano avere TouchID o niente. Quindi l'errore sarà di tipo 0, 1
        var message = ""
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &canEvaluateError) {
            if #available(iOS 11.0, *) {
                switch context.biometryType.rawValue {
                    case 0:
                        message = "Device doesn't have any biometry sensor" // Non capita mai (iOS >= 11)
                    case 1:
                        message = "Device has got TouchID"
                    case 2:
                        message = "Device has got FaceID"
                    default:
                        message = "Biometry sensor not recognized"
                }
            } else {
                message = "Device is eligible to evaluate authentication. (iOS < 11)"
            }
            //self.presentAlertMainThread(message: message)
            print(message)
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Let's login please.." ) { success, evaluateError in
                if success {
                    self.presentAlertMainThread(message: "Login succesful !")
                }
                else {
                    message = self.evaluatePolicyErrorMessage(errorCode: (evaluateError! as NSError).code)
                    self.presentAlertMainThread(message: message )
                    print("EvaluatePolicy Error: \(evaluateError!._code)")
                }
            }
        }
        else {
            message = canEvaluatePolicyErrorMessage(errorCode: (canEvaluateError?.code)!, context: context)
            self.presentAlertMainThread(message:  message)
            print("CanEvaluatePolicy Error: \(String(describing: canEvaluateError?.code ))")
        }
    }
}


extension ViewController {
    
    func presentAlertMainThread(message: String) {
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: "Pay attention", message: message, preferredStyle: UIAlertControllerStyle.alert)
            self.present(alertController, animated: true, completion: nil)
            let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alertController.addAction(defaultAction)
        })
    }
    
    func canEvaluatePolicyErrorMessage(errorCode: Int, context: LAContext) -> String {
        var message = ""
        if #available(iOS 11.0, *) {
            switch errorCode {
                // -6
                case LAError.biometryNotAvailable.rawValue:
                    switch context.biometryType.rawValue {
                        case 0: // non capita mail (iOS >= 11)
                            message = "Device doesn't have any biometry sensor"
                        case 1:
                            message = "Device has got TouchID, but usage permission is false"
                        case 2:
                            message = "Device has got FaceID, but usage permission is false"
                        default:
                            message = "Biometry sensor not recognized"
                    }
                // TBD
                case LAError.biometryLockout.rawValue:
                        switch context.biometryType.rawValue {
                            case 0: // non capita mail (iOS >= 11)
                                message = "Device doesn't have any biometry sensor"
                            case 1:
                                message = "Device has got TouchID, but is locked"
                            case 2:
                                message = "Device has got FaceID, but is locked"
                            default:
                                message = "Biometry sensor not recognized"
                        }
                // -7
                case LAError.biometryNotEnrolled.rawValue:
                    switch context.biometryType.rawValue {
                        case 0: // non capita mail (iOS >= 11)
                            message = "Device doesn't have any biometry sensor"
                        case 1:
                            message = "Device has got TouchID, but is not enrolled"
                        case 2:
                            message = "Device has got FaceID, but is not enrolled"
                        default:
                            message = "Biometry sensor not recognized"
                    }
                default:
                    message = "Policy Error not managed."
                }
        }
        else if #available(iOS 9.0, *) {
            switch errorCode {
                // TBD
                case LAError.touchIDLockout.rawValue:
                    if #available(iOS 11.0, *) {
                        switch context.biometryType.rawValue {
                            case 0:
                                message = "Device doesn't have any biometry sensor"
                            case 1:
                                message = "Device has got TouchID, but it's locked"
                            case 2:
                                message = "Device has got FaceID, but it's locked"
                            default:
                                message = "Biometry sensor not recognized"
                        }
                    } else {
                        message = "Too much authentication errors with TouchID (9.0 <= iOS < 11.0) - Aut. locked"
                    }
                // -6
                case LAError.touchIDNotAvailable.rawValue:
                    if #available(iOS 11.0, *) {
                        switch context.biometryType.rawValue {
                            case 0:
                                message = "Device doesn't have any biometry sensor"
                            case 1:
                                message = "Device has got TouchID, but usage permission is false"
                            case 2:
                                message = "Device has got FaceID, but usage permission is false"
                            default:
                                message = "Biometry sensor not recognized"
                        }
                    } else {
                        message = "Il device non ha TouchID ed (9.0 <= iOS < 11.0)"
                    }
                // -7
                case LAError.touchIDNotEnrolled.rawValue:
                    if #available(iOS 11.0, *) {
                        switch context.biometryType.rawValue {
                            case 0:
                                message = "Device doesn't have any biometry sensor"
                            case 1:
                                message = "Device has got TouchID, but is not enrolled"
                            case 2:
                                message = "Device has got FaceID, but is not enrolled"
                            default:
                                message = "Biometry sensor not recognized"
                        }
                    } else {
                        message = "TouchID not 'enrolled' (9.0 <= iOS < 11.0)"
                    }
                default:
                    message = "Not managed cases"
            }
        }
        else {
            // 8.0 <= iOS < 9.0
            print("canEvaluatePolicy Error: \(errorCode.description)")
        }
        return message;
    }
    
    
    func evaluatePolicyErrorMessage(errorCode: Int) -> String {
        var message = ""
        if #available(iOS 9.0, *) {
            switch errorCode {
                // -1
                case LAError.authenticationFailed.rawValue:
                    message = "Authentication failed"
                // -9
                case LAError.appCancel.rawValue:
                    message = "Authentication cancelled by APP"
                // TBD
                case LAError.invalidContext.rawValue:
                    message = "LAContext passed to this call has been previously invalidated"
                // TBD
                case LAError.notInteractive.rawValue:
                    message = "Authentication failed, because it would require showing UI which has been forbidden by using interactionNotAllowed property"
                // TBD
                case LAError.passcodeNotSet.rawValue:
                    message = "Passcode not set"
                // -4
                case LAError.systemCancel.rawValue:
                    message = "Authentication cancelled by iOS"
                // -2
                case LAError.userCancel.rawValue:
                    message = "Authentication cancelled by the user"
                // -3 (appare tasto di sistema ENTER PASSWORD, o l'etichetta Fallback personalizzata.)
                case LAError.userFallback.rawValue:
                    message = "Fallback selected by the user."
                default:
                    message = "Error code not managed"
            }
        } else {
            message = "Authentication failed (8.0 <= iOS < 9.0) - Code: \(errorCode.description)"
        }
        return message
    }
}

