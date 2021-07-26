package io.github.mertguner.sound_generator

import android.media.*
import android.os.Build
import androidx.annotation.RequiresApi
import io.github.mertguner.sound_generator.generators.BaseGenerator
import io.github.mertguner.sound_generator.generators.SineGenerator
import kotlinx.coroutines.*
import java.util.*
import java.util.concurrent.TimeUnit

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class SignalPlayer(private val generator: BaseGenerator = SineGenerator(), private var sampleSize: Int, sampleRate: Int, var frequency: Float) {
    private val _2Pi = 2f * Math.PI.toFloat()
    private var phCoefficient = _2Pi / sampleRate.toFloat()
    private var smoothStep = 1f / sampleRate.toFloat() * 20f
    private val backgroundBuffer: ShortArray = ShortArray(sampleSize)
    private val buffer: ShortArray = ShortArray(sampleSize)

    private var ph = 0f
    private var oldFrequency = 50f
    private var creatingNewData = false

    private var audioTrack: AudioTrack = AudioTrack(
            AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .build(),
            AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
            sampleSize, AudioTrack.MODE_STREAM, AudioManager.AUDIO_SESSION_ID_GENERATE)
    private var bufferThread: Thread? = null

    private val volumeShaperConf: VolumeShaper.Configuration? = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
        VolumeShaper.Configuration.Builder()
                .setDuration(300)
                .setCurve(floatArrayOf(0f, 1f), floatArrayOf(0f, 1f))
                .setInterpolatorType(VolumeShaper.Configuration.INTERPOLATOR_TYPE_LINEAR)
                .build()
    } else {
        null
    }

    var sampleRate = sampleRate
        set(value) {
            field = value
            phCoefficient = _2Pi / sampleRate.toFloat()
            smoothStep = 1f / sampleRate.toFloat() * 20f
        }

    var playing = false
        set(value) {
            field = value

            if (value) {
                bufferThread = Thread {
                    audioTrack.flush()
                    audioTrack.playbackHeadPosition = 0
                    audioTrack.play()
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        val volumeShaper = audioTrack.createVolumeShaper(volumeShaperConf!!)
                        volumeShaper.apply(VolumeShaper.Operation.PLAY)
                    }

                    while (playing) {
                        audioTrack.write(data, 0, sampleSize)
                    }
                }

                bufferThread!!.start()
            } else {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    val volumeShaper = audioTrack.createVolumeShaper(volumeShaperConf!!)
                    volumeShaper.apply(VolumeShaper.Operation.REVERSE)
                }

                try {
                    bufferThread?.join() //Waiting thread
                } catch (e: InterruptedException) {
                    e.printStackTrace()
                }

                bufferThread = null
            }
        }

    var volume: Float = 1f
        set(value) {
            field = value
            audioTrack.setVolume(value)
        }


    private val data: ShortArray
        get() {
            if (!creatingNewData) {
                System.arraycopy(backgroundBuffer, 0, buffer, 0, sampleSize)
                CoroutineScope(Dispatchers.IO).async {
                    updateData()
                }.start()
            }
            return buffer
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

    init {
        updateData()
    }
}