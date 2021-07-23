package io.github.mertguner.sound_generator.generators

class SquareGenerator : BaseGenerator() {
    override fun getValue(phase: Double, period: Double): Short {
        return if (phase <= period / 2) {
            Short.MAX_VALUE
        } else {
            (-Short.MAX_VALUE).toShort()
        }
    }
}