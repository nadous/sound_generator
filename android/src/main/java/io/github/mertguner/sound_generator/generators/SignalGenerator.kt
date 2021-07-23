package io.github.mertguner.sound_generator.generators

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import androidx.annotation.RequiresApi
import io.github.mertguner.sound_generator.handlers.GetOneCycleDataHandler
import kotlinx.coroutines.*
import java.util.*
import kotlin.coroutines.CoroutineContext
import kotlin.math.roundToInt

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class SignalGenerator(private val generator: BaseGenerator = SineGenerator(), var sampleSize: Int, sampleRate: Int, frequency: Float) : CoroutineScope {
    private val _2Pi = 2.0f * Math.PI.toFloat()
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

    init {
        val attributes = AudioAttributes.Builder().setLegacyStreamType(AudioManager.STREAM_MUSIC)
        val format = AudioFormat.Builder().setSampleRate(sampleRate).setEncoding(AudioFormat.ENCODING_PCM_16BIT)

        audioTrack = AudioTrack(
                attributes.build(),
                format.build(),
                sampleSize,
                AudioTrack.MODE_STREAM, (Math.random() * 1000).toInt())

        updateData()
        createOneCycleData()
    }

    fun setAutoUpdateOneCycleSample(autoUpdateOneCycleSample: Boolean) {
        this.autoUpdateOneCycleSample = autoUpdateOneCycleSample
    }

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


    private fun start() {
        job = GlobalScope.launch {
            audioTrack.flush()
            audioTrack.playbackHeadPosition = 0
            audioTrack.play()

            while (playing) {
                audioTrack.write(data, 0, sampleSize)
            }

            job.cancelAndJoin()
        }

        job.start()
    }


    var playing = false
        get() = audioTrack.state == AudioTrack.PLAYSTATE_PLAYING
        set(value) {
            field = value
            if (value) start() else audioTrack.stop()
        }


    private fun updateData() {
        creatingNewData = true

        for (i in 0..sampleSize - 1) {
            oldFrequency += (frequency - oldFrequency) * smoothStep
            backgroundBuffer[i] = generator.getValue(ph.toDouble(), _2Pi.toDouble())
            ph += oldFrequency * phCoefficient

            if (ph > _2Pi) ph -= _2Pi
        }

        creatingNewData = false
    }

    val data: ShortArray
        get() {
            if (!creatingNewData) {
                System.arraycopy(backgroundBuffer, 0, buffer, 0, sampleSize)
                Thread { updateData() }.start()
            }
            return buffer
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


    override val coroutineContext: CoroutineContext
        get() = Dispatchers.Default + job
}