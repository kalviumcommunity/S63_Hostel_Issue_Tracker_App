@echo off
title Hostel Project Booter
echo 🚀 Starting Milestone: Notifications & Flutter...

:: Start Notifications in a separate minimized window
start /min cmd /c "node NOTIFICATION_TRIGGER.js"
echo ✅ Background Notification Trigger Started!

:: Start the Flutter App
echo 📱 Launching Flutter App...
flutter run

pause
