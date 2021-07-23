package io.github.mertguner.sound_generator.generators

abstract class BaseGenerator {
    abstract fun getValue(phase: Double, period: Double): Short
}