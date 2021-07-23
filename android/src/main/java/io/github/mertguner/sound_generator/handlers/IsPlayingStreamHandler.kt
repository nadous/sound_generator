package io.github.mertguner.sound_generator.handlers

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import java.util.*

class IsPlayingStreamHandler : EventChannel.StreamHandler {
    var eventSink: EventSink? = null
    override fun onListen(o: Any, eventSink: EventSink) {
        this.eventSink = eventSink
    }

    override fun onCancel(o: Any) {
        if (eventSink != null) {
            eventSink!!.endOfStream()
            eventSink = null
        }
    }

    companion object {
        const val NATIVE_CHANNEL_EVENT = "io.github.mertguner.sound_generator/onChangeIsPlaying"

        private var mEventManager: IsPlayingStreamHandler? = null
        fun change(value: HashMap<String?, Any?>?) {
            if (mEventManager != null && mEventManager!!.eventSink != null) {
                mEventManager!!.eventSink!!.success(value)
            }
        }
    }

    init {
        if (mEventManager == null) {
            mEventManager = this
        }
    }
}