package io.github.mertguner.sound_generator.generators

class SineGenerator : BaseGenerator() {
    override fun getValue(phase: Double, period: Double): Short {
        return (Short.MAX_VALUE * Math.sin(phase)).toInt().toShort()
    }
}