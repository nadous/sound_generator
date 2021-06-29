import Flutter
import UIKit
import AudioKit
import SoundpipeAudioKit
//import Sound

public class SwiftSoundGeneratorPlugin: NSObject, FlutterPlugin {
  var onChangeIsPlaying: BetterEventChannel?;
  var onOneCycleDataHandler: BetterEventChannel?;
  // This is not used yet.
    let engine = AudioEngine()

    var sampleRate: Int = 48000;
    var isPlaying: Bool = false;
    var oscillator: Oscillator = Oscillator(waveform: Table(.sine));
    var oscillator2: Oscillator = Oscillator(waveform: Table(.triangle));
    var oscillator3: Oscillator = Oscillator(waveform: Table(.square));
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
    self.mixer.addInput(oscillator)
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
        self.oscillator.frequency = 400
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
        self.oscillator.start()
        onChangeIsPlaying!.sendEvent(event: true)
        result(nil);
        break;
      case "stop":
        self.oscillator.stop();
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
        self.oscillator.frequency = args["frequency"] as! Float
        result(nil);
        break;
      case "setWaveform":
        let args = call.arguments as! [String: Any]
        let waveType = args["waveType"] as! String
        print(waveType)
        switch waveType{
          case "0":
            //self.oscillator = Oscillator(waveform: Table(.sine));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.oscillator2)
            //engine.output = self.mixer!
            break;
          case "1":
            //self.oscillator = Oscillator(waveform: Table(.sawtooth));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.oscillator2)
            //engine.output = self.mixer!
            break;
          case "2":
            //self.oscillator = Oscillator(waveform: Table(.triangle));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.oscillator2)
            //engine.output = self.mixer!
            break;
          
          default:
            //self.oscillator = Oscillator(waveform: Table(.square));
            self.mixer.removeAllInputs()
            self.mixer.addInput(self.oscillator2)
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
