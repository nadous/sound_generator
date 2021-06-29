import Flutter
import UIKit
import AudioKit
//import SoundpipeAudioKit


public class SwiftSoundGeneratorPlugin: NSObject, FlutterPlugin {
  var onChangeIsPlaying: BetterEventChannel?;
  var onOneCycleDataHandler: BetterEventChannel?;
  // This is not used yet.
    let engine = AudioEngine()

    var sampleRate: Int = 48000;
    var isPlaying: Bool = false;
    var osc: Oscillator = Oscillator();
    var osc2: Oscillator = Oscillator();
    var osc3: Oscillator = Oscillator();
    /*var oscillator = OperationGenerator { parameters in
           returnAKOperation.sawtoothWave(frequency: GeneratorSource.frequency)
    )*/
    var mixer: Mixer=Mixer();

  public static func register(with registrar: FlutterPluginRegistrar) {
    /*let instance =*/ _ = SwiftSoundGeneratorPlugin(registrar: registrar)
  }

  public init(registrar: FlutterPluginRegistrar) {
    super.init()
    //self.mixer = Mixer()
    //self.mixer.init()
    //self.oscillator.init(waveform:Table(.triangle))
    self.mixer.addInput(osc)
    self.mixer.volume = 1.0
    Settings.disableAVAudioSessionCategoryManagement = true
    //Settings.disableAudioSessionDeactivationOnStop = true
    engine.output = self.mixer
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
        self.osc.frequency = 400
        do {
            try engine.start()
            result(true);
        } catch {
            result(FlutterError(
                code: "init_error",
                message: "Unable to start engine",
                details: ""))
        }
        break
      case "release":
        result(nil);
        break;
      case "play":
        self.osc.start()
        onChangeIsPlaying!.sendEvent(event: true)
        result(nil);
        break;
      case "stop":
        self.osc.stop();
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
        self.osc.frequency = args["frequency"] as! Float
        result(nil);
        break;
      case "setWaveform":
        let args = call.arguments as! [String: Any]
        let waveType = args["waveType"] as! String
        print(waveType)
        switch waveType{
          case "0":
            //self.osc = osc(waveform: Table(.sine));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.osc2)
            //engine.output = self.mixer!
            break;
          case "1":
            //self.osc = Oscillator(waveform: Table(.sawtooth));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.osc2)
            //engine.output = self.mixer!
            break;
          case "2":
            //self.osc = Oscillator(waveform: Table(.triangle));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.osc2)
            //engine.output = self.mixer!
            break;
          
          default:
            //self.osc = Oscillator(waveform: Table(.square));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.osc2)
            //engine.output = self.mixer!
            break;
            
        }
        result(nil);
        break;
      case "setBalance":
        result(nil);
        break;
      case "setVolume":
        let args = call.arguments as! [String: Any]
        self.mixer.volume = args["volume"] as! Float
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
