import Flutter
import AudioKit

public class SwiftSoundGeneratorPlugin: NSObject, FlutterPlugin {
    var onChangeIsPlaying: BetterEventChannel?
    
    var waveForm = AKTable(.sine)
    var sampleRate = 44100.0
    var volume = 1.0
    
    var oscillators:[String:AKOscillator] = [:]
    var mixer: AKMixer?;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        _ = SwiftSoundGeneratorPlugin(registrar: registrar)
    }
    
    private func _stringToWaveForm(waveForm:String) -> AKTable {
        switch waveForm {
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
        AKManager.disconnectAllInputs()
    }
    
    private func _startEngine() -> Bool {
        if !AKManager.engine.isRunning {
            do {
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
        registrar.addMethodCallDelegate(self, channel: methodChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "release":
            _stop()
            result(nil);
            break;
        case "start":
            let args = call.arguments as! [String: Any]
            
            let uid = args["uid"] as! String
            let frequency = args["frequency"] as! Double
            let waveForm = _stringToWaveForm(waveForm: args["wave_form"] as! String )
            
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
        case "set_volume":
            let args = call.arguments as! [String: Any]
            self.volume = args["volume"] as! Double
            self.mixer!.volume = self.volume
            
            result(nil);
            break;
        case "set_frequency":
            let args = call.arguments as! [String: Any]
            let uid = args["uid"] as! String
            let frequency = args["frequency"] as! Double
            
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
        default:
            result(FlutterMethodNotImplemented);
        }
    }
}
