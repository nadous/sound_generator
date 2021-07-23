package io.github.mertguner.sound_generator

import android.annotation.TargetApi
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import io.github.mertguner.sound_generator.generators.*
import io.github.mertguner.sound_generator.handlers.IsPlayingStreamHandler
import java.util.*
import kotlin.math.sin

internal enum class WaveForms {
    square, triangle, sawtooth, sine;

    companion object {
        fun fromString(waveForm: String?): WaveForms {
            return when (waveForm) {
                "square" -> square
                "triangle" -> triangle
                "sawtooth" -> sawtooth
                else -> sine
            }
        }

        fun toGenerator(waveForms: WaveForms?): BaseGenerator {
            return when (waveForms) {
                square -> SquareGenerator()
                triangle -> TriangleGenerator()
                sawtooth -> SawtoothGenerator()
                else -> SineGenerator()
            }
        }
    }
}

@TargetApi(Build.VERSION_CODES.LOLLIPOP)
class SoundGenerator {
    //    private var bufferThread: Thread? = null
    private val signals = HashMap<String, SignalGenerator>()
    private var sampleSize = 0

    var sampleRate: Int = 44100
        set(value) {
            field = value
            for (uid in signals.keys) {
                signals[uid]!!.sampleRate = value
            }
        }

    var volume: Float = 1f
        set(value) {
            field = value
            for (uid in signals.keys) {
                signals[uid]!!.createOneCycleData(true)
            }
        }


    fun release() {
        for (uid in signals.keys) {
            signals.remove(uid)
            val res = HashMap<String?, Any?>()
            res["uid"] = uid
            res["is_playing"] = false
            IsPlayingStreamHandler.change(res)
        }
    }

    fun play(uid: String, frequency: Float, waveForm: String?) {

        val signal = SignalGenerator(WaveForms.toGenerator(WaveForms.fromString(waveForm)), sampleSize, sampleRate, frequency)
        signal.playing = true
        signals[uid] = signal

        val res = HashMap<String?, Any?>()
        res["uid"] = uid
        res["is_playing"] = true
        IsPlayingStreamHandler.change(res)
    }

    fun stop(uid: String) {
        if (!signals.containsKey(uid)) {
            return
        }

        signals[uid]!!.playing = false
        signals.remove(uid)
        val res = HashMap<String?, Any?>()
        res["uid"] = uid
        res["is_playing"] = false
        IsPlayingStreamHandler.change(res)
    }

    fun setAutoUpdateOneCycleSample(autoUpdateOneCycleSample: Boolean) {
        for (uid in signals.keys) {
            signals[uid]!!.setAutoUpdateOneCycleSample(autoUpdateOneCycleSample)
        }
    }

    fun refreshOneCycleData() {
        for (uid in signals.keys) {
            signals[uid]!!.createOneCycleData(true)
        }
    }


    fun init(): Boolean {
        return try {
            sampleSize = AudioTrack.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT)

            true
        } catch (ex: Exception) {
            false
        }
    }

    val playing: Boolean
        get() {
            for (uid in signals.keys) {
                if (signals[uid]!!.playing) return true
            }
            return false
        }
}