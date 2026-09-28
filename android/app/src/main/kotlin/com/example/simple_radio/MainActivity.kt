package com.example.simple_radio

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity keeps the Flutter engine shared with the background
// audio service, so playback survives the UI being closed.
class MainActivity : AudioServiceActivity()
