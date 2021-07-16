import Flutter
import UIKit
import AudioKit

public class SwiftSoundGeneratorPlugin: NSObject, FlutterPlugin {
    var onChangeIsPlaying: BetterEventChannel?
    var onOneCycleDataHandler: BetterEventChannel?
    // This is not used yet.
    var sampleRate: Double = 44100
    var isPlaying: Bool = false
    var wave:AKTable = AKTable(.sine)
    
    var oscillators:[AKOscillator] = []
//    var oscillator: AKOscillator = AKOscillator()
//    var triangleOsc: AKOscillator = AKOscillator(waveform:AKTable(.triangle))
//    var squareOsc: AKOscillator = AKOscillator(waveform:AKTable(.square))
    var mixer: AKMixer?;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        /*let instance =*/ _ = SwiftSoundGeneratorPlugin(registrar: registrar)
    }
    
    public init(registrar: FlutterPluginRegistrar) {
        super.init()
//        self.mixer = AKMixer(self.oscillator,self.squareOsc,self.triangleOsc)
//        self.mixer!.volume = 1.0
        AKSettings.disableAVAudioSessionCategoryManagement = true
        AKSettings.disableAudioSessionDeactivationOnStop = true
        AKSettings.sampleRate = self.sampleRate
        
//        AKManager.output = self.mixer!
        
        let methodChannel = FlutterMethodChannel(name: "sound_generator", binaryMessenger: registrar.messenger())
        self.onChangeIsPlaying = BetterEventChannel(name: "io.github.mertguner.sound_generator/onChangeIsPlaying", messenger: registrar.messenger())
        self.onOneCycleDataHandler = BetterEventChannel(name: "io.github.mertguner.sound_generator/onOneCycleDataHandler", messenger: registrar.messenger())
        registrar.addMethodCallDelegate(self, channel: methodChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            //let args = call.arguments as! [String: Any]
            //let sampleRate = args["sampleRate"] as Int
//            self.oscillator.frequency = 400
//            self.triangleOsc.frequency = 400
//            self.squareOsc.frequency = 400
            
            do {
                try AKManager.start()
                result(true);
            } catch {
                result(FlutterError(
                        code: "init_error",
                        message: "Unable to start AKManager",
                        details: ""))
            }
            break
        case "release":
            result(nil);
            break;
        case "play":
            let args = call.arguments as! [String: Any]
            let frequency =args["frequency"] as! Double
            self.oscillator.start()
            //self.oscillator2.start()
            onChangeIsPlaying!.sendEvent(event: true)
            result(nil);
            break;
        case "stop":
            self.oscillator.stop();
            self.squareOsc.stop();
            self.triangleOsc.stop();
            onChangeIsPlaying!.sendEvent(event: false)
            result(nil);
            break;
        case "isPlaying":
            result(self.isPlaying);
            break;
        case "setAutoUpdateOneCycleSample":
            result(nil);
            break;
        case "setFrequency":
            let args = call.arguments as! [String: Any]
            self.oscillator.frequency = args["frequency"] as! Double
            self.squareOsc.frequency = args["frequency"] as! Double
            self.triangleOsc.frequency = args["frequency"] as! Double
            result(nil);
            break;
        case "setWaveform":
            let args = call.arguments as! [String: Any]
            let waveType = args["waveType"] as! String
            switch waveType {
            case "SQUAREWAVE":
                self.squareOsc.start();
                self.oscillator.stop();
                self.triangleOsc.stop();
                
            case "TRIANGLE":
                
                self.squareOsc.stop();
                self.oscillator.stop();
                self.triangleOsc.start();
                
                
            default:
                self.squareOsc.stop();
                self.oscillator.start();
                self.triangleOsc.stop();
            }
            
            result(nil);
            break;
        case "setBalance":
            result(nil);
            break;
        case "setVolume":
            let args = call.arguments as! [String: Any]
            self.mixer!.volume = args["volume"] as! Double
            result(nil);
            break;
        case "getSampleRate":
            result(self.sampleRate);
            break;
        case "refreshOneCycleData":
            result(nil);
            break;
        default:
            result(FlutterMethodNotImplemented);
        }
    }
}
