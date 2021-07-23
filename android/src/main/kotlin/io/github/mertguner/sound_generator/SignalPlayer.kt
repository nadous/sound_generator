package io.github.mertguner.sound_generator

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import io.github.mertguner.sound_generator.generators.BaseGenerator
import io.github.mertguner.sound_generator.generators.SineGenerator
import io.github.mertguner.sound_generator.handlers.GetOneCycleDataHandler
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import java.util.*
import kotlin.math.roundToInt

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class SignalPlayer(private val generator: BaseGenerator = SineGenerator(), private var sampleSize: Int, sampleRate: Int, frequency: Float) {
    private val _2Pi = 2f * Math.PI.toFloat()
    private var phCoefficient = _2Pi / sampleRate.toFloat()
    private var smoothStep = 1f / sampleRate.toFloat() * 20f
    private val backgroundBuffer: ShortArray = ShortArray(sampleSize)
    private val buffer: ShortArray = ShortArray(sampleSize)
    private val oneCycleBuffer: MutableList<Int> = ArrayList()

    private var ph = 0f
    private var oldFrequency = 50f
    private var creatingNewData = false
    private var autoUpdateOneCycleSample = false

    private var audioTrack: AudioTrack
    private lateinit var job: Job


    var sampleRate = sampleRate
        set(value) {
            field = value
            phCoefficient = _2Pi / sampleRate.toFloat()
            smoothStep = 1f / sampleRate.toFloat() * 20f
        }

    var frequency = frequency
        set(value) {
            field = value
            createOneCycleData()
        }

    var playing = false
        set(value) {
            field = value
            if (value) start()
        }

    private val data: ShortArray
        get() {
            if (!creatingNewData) {
                System.arraycopy(backgroundBuffer, 0, buffer, 0, sampleSize)
                Thread { updateData() }.start()
            }
            return buffer
        }

    fun setAutoUpdateOneCycleSample(autoUpdateOneCycleSample: Boolean) {
        this.autoUpdateOneCycleSample = autoUpdateOneCycleSample
    }

    private fun start() {
        audioTrack.flush()
        audioTrack.playbackHeadPosition = 0
        audioTrack.play()

        job = GlobalScope.launch {
            while (playing) {
                audioTrack.write(data, 0, sampleSize)
            }

            audioTrack.release()
            job.cancelAndJoin()
        }

        job.start()
    }

    private fun updateData() {
        creatingNewData = true

        for (i in 0 until sampleSize) {
            oldFrequency += (frequency - oldFrequency) * smoothStep
            backgroundBuffer[i] = generator.getValue(ph.toDouble(), _2Pi.toDouble())
            ph += oldFrequency * phCoefficient

            if (ph > _2Pi) ph -= _2Pi
        }

        creatingNewData = false
    }

    fun createOneCycleData(force: Boolean = false) {
        if (!autoUpdateOneCycleSample && !force) return

        val size = (_2Pi / (frequency * phCoefficient)).roundToInt()
        oneCycleBuffer.clear()
        for (i: Int in 0 until size) {
            oneCycleBuffer.add(generator.getValue((frequency * phCoefficient * i.toFloat()).toDouble(), _2Pi.toDouble()).toInt())
        }
        oneCycleBuffer.add(generator.getValue(0.0, _2Pi.toDouble()).toInt())

        GetOneCycleDataHandler.setData(oneCycleBuffer)
    }

    init {
        val attributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .build()

        val format = AudioFormat.Builder()
                .setSampleRate(sampleRate)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .build()

        audioTrack = AudioTrack(attributes, format, sampleSize, AudioTrack.MODE_STREAM, AudioManager.AUDIO_SESSION_ID_GENERATE)

        updateData()
        createOneCycleData()
    }
}