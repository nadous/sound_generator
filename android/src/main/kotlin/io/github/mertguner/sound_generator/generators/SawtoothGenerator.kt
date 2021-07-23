package io.github.mertguner.sound_generator.generators

class SawtoothGenerator : BaseGenerator() {
    override fun getValue(phase: Double, period: Double): Short {
        return if (phase < period / 2) (Short.MAX_VALUE * (2.0 * phase / Math.PI - 1)).toInt().toShort()
        else (Short.MAX_VALUE * (2.0 * phase / Math.PI - 3)).toInt().toShort()
    }
}