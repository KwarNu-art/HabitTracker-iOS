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
// Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MY ROUTINE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.purple.opacity(0.8))
                            .tracking(2)
                        Text("Habit Tracker")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: { showAddModal = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            )
                            .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                // Habits List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach($habits) { $habit in
                            HabitCard(habit: $habit)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showAddModal) {
            AddHabitView(
                title: $newHabitTitle,
                time: $newHabitTime,
                selectedIcon: $selectedIcon,
                icons: icons,
                onSave: {
                    let habit = Habit(title: newHabitTitle, reminderTime: newHabitTime, icon: selectedIcon)
                    habits.append(habit)
                    scheduleAlarm(for: habit)
                    newHabitTitle = ""
                    showAddModal = false
                }
            )
        }
    }
    // Schedule Phone Alarm / Notification
    func scheduleAlarm(for habit: Habit) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Habit Reminder!"
        content.body = "အချိန်ရောက်ပါပြီ: \(habit.title)"
        content.sound = UNNotificationSound.defaultCritical
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: habit.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
// MARK: - Premium Glassmorphic Habit Card
struct HabitCard: View {
    @Binding var habit: Habit
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(habit.isCompleted ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: habit.icon)
                    .foregroundColor(habit.isCompleted ? .green : .purple)
                    .font(.system(size: 20))
            }
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .strikethrough(habit.isCompleted, color: .gray)
                HStack(spacing: 8) {
                    Text(habit.reminderTime, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
Text("🔥 \(habit.streak) ရက်ဆက်တိုက်")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            Spacer()
            // Completion Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    habit.isCompleted.toggle()
                    if habit.isCompleted { habit.streak += 1 } else { habit.streak = max(0, habit.streak - 1) }
                }
            }) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundColor(habit.isCompleted ? .green : .gray.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
// MARK: - Add Habit Modal View
struct AddHabitView: View {
    @Binding var title: String
    @Binding var time: Date
    @Binding var selectedIcon: String
    let icons: [String]
    var onSave: () -> Void
    var body: some View {
        ZStack {
            Color(hex: "0F0C20").ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Habit အသစ်ထည့်ရန်")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .padding(.top)
                TextField("အလေ့အထ အမည် (ဥပမာ- ရေသောက်ရန်)...", text: $title)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                DatePicker("Alarm အချိန်", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .colorScheme(.dark)
                    .padding(.horizontal)
                // Icon Picker
                HStack(spacing: 12) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedIcon == icon ? .white : .gray)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color.purple : Color.white.opacity(0.08))
                                .cornerRadius(10)
                        }
                    }
                }
                Spacer()
                Button(action: onSave) {
                    Text("Alarm နှင့်တကွ မှတ်သားမည်")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                }
                .disabled(title.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}
// Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
