package io.github.mertguner.sound_generator.generators

class TriangleGenerator : BaseGenerator() {
    override fun getValue(phase: Double, period: Double): Short {
        return if (phase <= period / 4) (Short.MAX_VALUE * (4 * phase / Math.PI - 1.0)).toInt().toShort()
        else if (phase <= period / 2) (Short.MAX_VALUE * (3.0 - 4 * phase / Math.PI)).toInt().toShort()
        else if (phase <= 3 * period / 4) (Short.MAX_VALUE * (4 * phase / Math.PI - 5.0)).toInt().toShort()
        else (Short.MAX_VALUE * (7.0 - 4 * phase / Math.PI)).toInt().toShort()
    }
}