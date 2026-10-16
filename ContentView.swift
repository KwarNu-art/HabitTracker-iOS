import SwiftUI
import UserNotifications
// MARK: - Habit Model
struct Habit: Identifiable, Codable {
    var id = UUID()
    var title: String
    var reminderTime: Date
    var isCompleted: Bool = false
    var streak: Int = 0
    var icon: String = "flame.fill"
}
// MARK: - Main View
struct ContentView: View {
    @State private var habits: [Habit] = [
        Habit(title: "မနက်ခင်း ရေသောက်ရန်", reminderTime: Date(), isCompleted: false, streak: 3, icon: "drop.fill"),
        Habit(title: "စာဖတ်ရန် (၃၀ မိနစ်)", reminderTime: Date(), isCompleted: true, streak: 7, icon: "book.fill")
    ]
    @State private var showAddModal = false
    @State private var newHabitTitle = ""
    @State private var newHabitTime = Date()
    @State private var selectedIcon = "star.fill"
    let icons = ["star.fill", "flame.fill", "drop.fill", "book.fill", "heart.fill", "figure.walk", "moon.fill"]
    var body: some View {
        ZStack {
            // Dark Velvet Gradient Background (OLED/Battery Saver)
            LinearGradient(
                colors: [Color(hex: "0F0C20"), Color(hex: "06050C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
