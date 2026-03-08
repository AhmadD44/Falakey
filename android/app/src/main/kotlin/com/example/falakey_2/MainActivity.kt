package com.example.falakey_2

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Carry out the default Flutter initialization
        super.onCreate(savedInstanceState)

        // Android 12+ Splash Screen API Fix
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                // This removes the splash screen view immediately without 
                // the default fade-out that causes the white flicker.
                splashScreenView.remove()
            }
        }
    }
}