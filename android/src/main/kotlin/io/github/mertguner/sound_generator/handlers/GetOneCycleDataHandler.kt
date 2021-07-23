package io.github.mertguner.sound_generator.handlers

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class GetOneCycleDataHandler : EventChannel.StreamHandler {
    var eventSink: EventSink? = null
    override fun onListen(o: Any?, eventSink: EventSink) {
        this.eventSink = eventSink
    }

    override fun onCancel(o: Any?) {
        if (eventSink != null) {
            eventSink!!.endOfStream()
            eventSink = null
        }
    }

    companion object {
        const val NATIVE_CHANNEL_EVENT = "io.github.mertguner.sound_generator/onOneCycleDataHandler"

        private var mEventManager: GetOneCycleDataHandler? = null
        fun setData(value: List<Int?>?) {
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