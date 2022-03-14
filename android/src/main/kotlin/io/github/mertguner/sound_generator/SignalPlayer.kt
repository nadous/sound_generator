package io.github.mertguner.sound_generator

import android.media.*
import android.os.Build
import androidx.annotation.RequiresApi
import io.github.mertguner.sound_generator.generators.BaseGenerator
import io.github.mertguner.sound_generator.generators.SineGenerator
import kotlinx.coroutines.*

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class SignalPlayer(private val generator: BaseGenerator = SineGenerator(), private var sampleSize: Int, sampleRate: Int, var frequency: Float) {
    private val twoPi = 2f * Math.PI.toFloat()
    private val backgroundBuffer: ShortArray = ShortArray(sampleSize)
    private val buffer: ShortArray = ShortArray(sampleSize)

    private var phCoefficient: Float = twoPi / sampleRate.toFloat()
    private var ph:Float = .0F
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

    private val volumeShaperConf: VolumeShaper.Configuration? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        VolumeShaper.Configuration.Builder()
                .setDuration(50)
                .setCurve(floatArrayOf(0f, 1f), floatArrayOf(0f, 1f))
                .setInterpolatorType(VolumeShaper.Configuration.INTERPOLATOR_TYPE_LINEAR)
                .build()
    } else {
        null
    }

    var sampleRate = sampleRate
        set(value) {
            field = value
            phCoefficient = twoPi / value.toFloat()
        }

    var playing = false
        set(value) {
            field = value

            if (value) {
                bufferThread = Thread {
                    audioTrack.flush()
                    audioTrack.playbackHeadPosition = 0
                    audioTrack.play()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val volumeShaper = audioTrack.createVolumeShaper(volumeShaperConf!!)
                        volumeShaper.apply(VolumeShaper.Operation.PLAY)
                    }

                    while (playing) {
                        audioTrack.write(data, 0, sampleSize)
                    }
                }

                bufferThread!!.start()
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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
            backgroundBuffer[i] = generator.getValue(ph.toDouble(), twoPi.toDouble())
            ph += frequency * phCoefficient

            if (ph > twoPi) {
                ph -= twoPi
            }
        }

        creatingNewData = false
    }

    init {
        updateData()
    }
}