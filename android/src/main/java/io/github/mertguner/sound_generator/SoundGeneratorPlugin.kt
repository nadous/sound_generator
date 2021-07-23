package io.github.mertguner.sound_generator

import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.github.mertguner.sound_generator.handlers.GetOneCycleDataHandler
import io.github.mertguner.sound_generator.handlers.IsPlayingStreamHandler

/**
 * SoundGeneratorPlugin
 */
class SoundGeneratorPlugin : FlutterPlugin, MethodCallHandler {
    private val soundGenerator = SoundGenerator()
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "sound_generator")
        channel!!.setMethodCallHandler(this)

        val onChangeIsPlaying = EventChannel(flutterPluginBinding.binaryMessenger, IsPlayingStreamHandler.NATIVE_CHANNEL_EVENT)
        onChangeIsPlaying.setStreamHandler(IsPlayingStreamHandler())
        val onOneCycleDataHandler = EventChannel(flutterPluginBinding.binaryMessenger, GetOneCycleDataHandler.NATIVE_CHANNEL_EVENT)
        onOneCycleDataHandler.setStreamHandler(GetOneCycleDataHandler())

        soundGenerator.init()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//        if
        when (call.method) {
            "release" -> soundGenerator.release()
            "play" -> {
                val uid = call.argument<String>("uid")
                val frequency = call.argument<Double>("frequency")!!
                val waveForm = call.argument<String>("wave_form")
                soundGenerator.play(uid!!, frequency.toFloat(), waveForm)
            }
            "stop" -> {
                val uid = call.argument<String>("uid")
                soundGenerator.stop(uid!!)
            }
            "is_playing" -> result.success(soundGenerator.playing)
            "set_auto_update_one_cycle_sample" -> {
                val autoUpdateOneCycleSample = call.argument<Boolean>("auto_update_one_cycle_sample")!!
                soundGenerator.setAutoUpdateOneCycleSample(autoUpdateOneCycleSample)
            }
            "set_balance" -> {
                val balance = call.argument<Double>("balance")!!
//                soundGenerator.setBalance(balance.toFloat())
            }
            "set_volume" -> {
                val volume = call.argument<Double>("volume")!!
                soundGenerator.volume = volume.toFloat()
            }
            "set_sample_rate" -> {
                val sampleRate = call.argument<Int>("sample_rate")!!
                soundGenerator.sampleRate = sampleRate
            }
            "get_sample_rate" -> result.success(soundGenerator.sampleRate)
            "refresh_one_cycle_data" -> soundGenerator.refreshOneCycleData()
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }
}