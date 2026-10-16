import SwiftUI
import UserNotifications
@main
struct HabitTrackerApp: App {
    init() {
        // App စဖွင့်ချိန်တွင် Alarm/Notification ခွင့်ပြုချက်တောင်းခြင်း
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification Permission Granted")
            }
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
