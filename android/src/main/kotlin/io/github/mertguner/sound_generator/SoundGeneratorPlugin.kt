package io.github.mertguner.sound_generator

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

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
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        when (call.method) {
            "release" -> soundGenerator.release()
            "start" -> {
                val uid = call.argument<String>("uid")!!
                val frequency = call.argument<Double>("frequency")!!
                val waveForm = call.argument<String>("wave_form")
                soundGenerator.start(uid, frequency.toFloat(), waveForm)
            }
            "stop" -> {
                val uid = call.argument<String>("uid")!!
                soundGenerator.stop(uid)
            }
            "is_playing" -> result.success(soundGenerator.playing)
            "set_volume" -> {
                val volume = call.argument<Double>("volume")!!
                soundGenerator.volume = volume.toFloat()
            }
            "set_frequency" -> {
                val uid = call.argument<String>("uid")!!
                val frequency = call.argument<Double>("frequency")!!

                soundGenerator.setFrequency(uid, frequency.toFloat())
            }
            "set_sample_rate" -> {
                val sampleRate = call.argument<Int>("sample_rate")!!
                soundGenerator.sampleRate = sampleRate
            }
            "get_sample_rate" -> result.success(soundGenerator.sampleRate)
            else -> result.notImplemented()
        }
    }

}