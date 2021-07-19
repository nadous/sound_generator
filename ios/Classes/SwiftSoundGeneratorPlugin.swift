import Flutter
import AudioKit

public class SwiftSoundGeneratorPlugin: NSObject, FlutterPlugin {
    var onChangeIsPlaying: BetterEventChannel?
    var onOneCycleDataHandler: BetterEventChannel?
    
    var waveType = AKTable(.sine)
    var sampleRate = 44100.0
    var volume = 1.0
    
    var oscillators:[String:AKOscillator] = [:]
    var mixer: AKMixer?;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        _ = SwiftSoundGeneratorPlugin(registrar: registrar)
    }
    
    private func _stringToWaveForm(waveType:String) -> AKTable {
        switch waveType {
        case "square":
            return AKTable(.square)
            
        case "triangle":
            return AKTable(.triangle)
            
        case "sawtooth":
            return AKTable(.sawtooth)
            
        default:
            return AKTable(.sine)
        }
    }
    
    private func _stop() {
        _ = self.oscillators.map{$1.stop()}
        //        for  oscillator in self.oscillators
        //        {
        //            oscillator.stop()
        //        }
        
        AKManager.disconnectAllInputs()
    }
    
    private func _startEngine() -> Bool {
        if !AKManager.engine.isRunning {
            do {
                print("starting the engine")
                try AKManager.start()
                return true
            } catch  {
                return false
            }
        }
        
        return true
    }
    
    public init(registrar: FlutterPluginRegistrar) {
        super.init()
        
        AKSettings.disableAVAudioSessionCategoryManagement = true
        AKSettings.disableAudioSessionDeactivationOnStop = true
        AKSettings.sampleRate = self.sampleRate
        
        self.mixer = AKMixer()
        self.mixer!.volume = self.volume
        AKManager.output = self.mixer!
        
        let methodChannel = FlutterMethodChannel(name: "sound_generator", binaryMessenger: registrar.messenger())
        self.onChangeIsPlaying = BetterEventChannel(name: "io.github.mertguner.sound_generator/onChangeIsPlaying", messenger: registrar.messenger())
        self.onOneCycleDataHandler = BetterEventChannel(name: "io.github.mertguner.sound_generator/onOneCycleDataHandler", messenger: registrar.messenger())
        registrar.addMethodCallDelegate(self, channel: methodChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "release":
            _stop()
            
            result(nil);
            break;
        case "play":
            let args = call.arguments as! [String: Any]
            
            let uid = args["uid"] as! String
            let frequency = args["frequency"] as! Double
            let waveForm = _stringToWaveForm(waveType: args["wave_form"] as! String )
            
            let oscillator = AKOscillator(waveform: waveForm)
            oscillator.frequency = frequency
            
            self.mixer?.connect(input: oscillator)
            self.oscillators[uid] = oscillator
            
            let started = _startEngine()
            
            if started {
                oscillator.start()
                result(uid);
            } else {
                result(FlutterError(
                        code: "init_error",
                        message: "Unable to start AKManager",
                        details: ""))
            }
            
            onChangeIsPlaying!.sendEvent(event: ["uid": uid, "is_playing": true])
            
            break;
        case "stop":
            let args = call.arguments as! [String: Any]
            let uid = args["uid"] as! String
            
            self.oscillators[uid]?.stop()
            self.oscillators.removeValue(forKey: uid)
            
            onChangeIsPlaying!.sendEvent(event: ["uid": uid, "is_playing": false])
            result(nil)
            break;
        case "is_playing":
            let args = call.arguments as! [String: Any]
            let uid = args["uid"] as! String
            
            result(self.oscillators[uid]?.isPlaying ?? false)
            break;
        case "set_auto_update_one_cycle_sample":
            result(nil);
            break;
        case "set_balance":
            let args = call.arguments as! [String: Any]
            let balance = args["sample_rate"] as! Double
            self.mixer?.pan = balance
            
            result(nil);
            break;
        case "set_volume":
            let args = call.arguments as! [String: Any]
            self.volume = args["volume"] as! Double
            self.mixer!.volume = self.volume
            
            result(nil);
            break;
        case "set_sample_rate":
            let args = call.arguments as! [String:Any]
            self.sampleRate = args["sample_rate"] as! Double
            AKSettings.sampleRate = self.sampleRate
            
            result(nil);
            break;
        case "get_sample_rate":
            result(self.sampleRate);
            break;
        case "refresh_one_cycle_data":
            result(nil);
            break;
        default:
            result(FlutterMethodNotImplemented);
        }
    }
}
