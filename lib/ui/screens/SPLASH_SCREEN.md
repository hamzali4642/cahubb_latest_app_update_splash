# Splash screen module

The splash screen is implemented in `splash_screen.dart` and plays
`assets/videos/splash.MOV` once with `video_player`.

## Display

`_SplashVideo` fills the available screen and uses `BoxFit.cover` with centered
alignment. This center-crops the video when its aspect ratio differs from the
device screen.

## Startup flow

The video and system settings load concurrently. Navigation is allowed only
after the video reaches its end and the settings request has either succeeded or
failed. The destination priority is maintenance mode, onboarding for a first-time
user, the main screen for authenticated/skipped users, and login otherwise.

If the video cannot initialize, it is treated as completed so the app is not
permanently blocked on the splash screen.
