import SwiftUI
import UserNotifications
// MARK: - App Language & Localization
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case myanmar = "my"
    
    var id: String { rawValue }
    var title: String {
        switch self {
        case .english: return "English"
        case .myanmar: return "မြန်မာစာ"
        }
    }
}
struct L10n {
    static func get(_ key: String, lang: AppLanguage) -> String {
        let dict: [String: [AppLanguage: String]] = [
            "app_title": [.english: "Habit Tracker", .myanmar: "အလေ့အကျင့် မှတ်တမ်း"],
            "today_progress": [.english: "Today's Progress", .myanmar: "ဒီနေ့ လုပ်ဆောင်မှု"],
            "habits_done": [.english: "completed", .myanmar: "ပြီးစီးပြီး"],
            "keep_going": [.english: "Keep up the momentum!", .myanmar: "ဆက်လက်ကြိုးစားပါ!"],
            "all_done": [.english: "Fantastic! All done for today 🎉", .myanmar: "အားလုံးပြီးစီးသွားပါပြီ 🎉"],
            "my_habits": [.english: "My Habits", .myanmar: "ကိုယ်ပိုင် အလေ့အကျင့်များ"],
            "no_habits": [.english: "No habits yet. Tap + to add one!", .myanmar: "အလေ့အကျင့် မရှိသေးပါ။ + ကိုနှိပ်၍ စတင်ပါ!"],
            "add_habit": [.english: "New Habit", .myanmar: "အလေ့အကျင့်သစ်"],
            "habit_name": [.english: "Habit Name", .myanmar: "အလေ့အကျင့် အမည်"],
            "habit_placeholder": [.english: "e.g., Read Books, Drink Water", .myanmar: "ဥပမာ- စာဖတ်ရန်၊ ရေသောက်ရန်"],
            "icon_color": [.english: "Icon & Color", .myanmar: "အိုင်ကွန်နှင့် အရောင်"],
            "reminder": [.english: "Reminder Alarm", .myanmar: "သတိပေး အချက်ပေးသံ"],
            "enable_reminder": [.english: "Enable Notification", .myanmar: "သတိပေးချက် ဖွင့်မည်"],
            "time": [.english: "Time", .myanmar: "အချိန်"],
            "save": [.english: "Save Habit", .myanmar: "သိမ်းဆည်းမည်"],
            "cancel": [.english: "Cancel", .myanmar: "မလုပ်တော့ပါ"],
            "settings": [.english: "Settings", .myanmar: "ဆက်တင်များ"],
            "language": [.english: "Language", .myanmar: "ဘာသာစကား"],
            "theme": [.english: "Appearance", .myanmar: "အသွင်အပြင်"],
            "theme_system": [.english: "System", .myanmar: "ဖုန်းစနစ်အတိုင်း"],
            "theme_light": [.english: "Light Mode", .myanmar: "အလင်း (Light)"],
            "theme_dark": [.english: "Dark Mode", .myanmar: "အမှောင် (Dark)"],
            "streak": [.english: "Streak", .myanmar: "ရက်ဆက်"],
            "days": [.english: "days", .myanmar: "ရက်"],
            "delete": [.english: "Delete", .myanmar: "ဖျက်မည်"],
            "about": [.english: "About", .myanmar: "အချက်အလက်"],
            "version": [.english: "Version 1.0 (Pro Edition)", .myanmar: "ဗားရှင်း ၁.၀ (Pro)"]
        ]
        return dict[key]?[lang] ?? key
    }
}
// MARK: - Habit Model
struct Habit: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var icon: String
    var colorHex: String
    var isReminderEnabled: Bool
    var reminderTime: Date
    var completedDates: [String] // Format: "yyyy-MM-dd"
    var streak: Int = 0
    
    var isCompletedToday: Bool {
        let today = HabitStore.dateFormatter.string(from: Date())
        return completedDates.contains(today)
    }
}
// MARK: - Data Store & Notifications
class HabitStore: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet {
            saveHabits()
        }
    }
    
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    private let saveKey = "SavedHabits_v1"
    
    init() {
        loadHabits()
        requestNotificationPermission()
    }
    
    func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            self.habits = decoded
        } else {
            // Default sample habits for new users
            self.habits = [
                Habit(title: "Drink Water (2L)", icon: "drop.fill", colorHex: "007AFF", isReminderEnabled: true, reminderTime: Date(), completedDates: []),
                Habit(title: "Morning Workout", icon: "figure.walk", colorHex: "FF9500", isReminderEnabled: false, reminderTime: Date(), completedDates: []),
                Habit(title: "Read 15 Mins", icon: "book.fill", colorHex: "5856D6", isReminderEnabled: false, reminderTime: Date(), completedDates: [])
            ]
        }
    }
    
    func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func toggleHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let today = HabitStore.dateFormatter.string(from: Date())
        
        if habits[index].completedDates.contains(today) {
            habits[index].completedDates.removeAll(where: { $0 == today })
            habits[index].streak = max(0, habits[index].streak - 1)
        } else {
            habits[index].completedDates.append(today)
            habits[index].streak += 1
        }
    }
    
    func addHabit(_ habit: Habit) {
        habits.insert(habit, at: 0)
        if habit.isReminderEnabled {
            scheduleNotification(for: habit)
        }
    }
    
    func deleteHabit(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func scheduleNotification(for habit: Habit) {
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder ⏰"
        content.body = "Time to complete: \(habit.title)"
        content.sound = .default
        
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: habit.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
// MARK: - Main ContentView
struct ContentView: View {
    @StateObject private var store = HabitStore()
    @AppStorage("app_language") private var selectedLanguage: AppLanguage = .english
    @AppStorage("app_theme") private var selectedTheme: Int = 0 // 0: System, 1: Light, 2: Dark
    
    @State private var showingAddSheet = false
    @State private var showingSettingsSheet = false
    
    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    private var completedCount: Int {
        store.habits.filter { $0.isCompletedToday }.count
    }
    
    private var progressRatio: Double {
        guard !store.habits.isEmpty else { return 0 }
        return Double(completedCount) / Double(store.habits.count)
    }
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // MARK: - Progress Hero Card
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(L10n.get("today_progress", lang: selectedLanguage))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(completedCount) / \(store.habits.count) \(L10n.get("habits_done", lang: selectedLanguage))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                
                                // Circular Progress Ring
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 9)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(progressRatio))
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(), value: progressRatio)
                                    
                                    Text("\(Int(progressRatio  100))%")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .frame(width: 60, height: 60)
                            }
                            
                            // Motivational text
                            HStack {
                                Image(systemName: progressRatio == 1.0 ? "sparkles" : "flame.fill")
                                    .foregroundColor(progressRatio == 1.0 ? .yellow : .orange)
                                Text(progressRatio == 1.0 ? L10n.get("all_done", lang: selectedLanguage) : L10n.get("keep_going", lang: selectedLanguage))
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        
                        // MARK: - Habits List Section
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(L10n.get("my_habits", lang: selectedLanguage))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            if store.habits.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text(L10n.get("no_habits", lang: selectedLanguage))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(store.habits) { habit in
                                    HabitCardView(
                                        habit: habit,
                                        lang: selectedLanguage,
                                        onToggle: {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                store.toggleHabit(habit)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(L10n.get("app_title", lang: selectedLanguage))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddHabitView(store: store, lang: selectedLanguage)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(
                    selectedLanguage: $selectedLanguage,
                    selectedTheme: $selectedTheme,
                    lang: selectedLanguage
                )
            }
        }
        .preferredColorScheme(colorScheme)
        .navigationViewStyle(.stack)
    }
}
// MARK: - Habit Card Component
struct HabitCardView: View {
    let habit: Habit
    let lang: AppLanguage
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: habit.colorHex).opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: habit.colorHex))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(habit.isCompletedToday ? .secondary : .primary)
                    .strikethrough(habit.isCompletedToday, color: .secondary)
                
                HStack(spacing: 8) {
                    // Streak badge
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(habit.streak) \(L10n.get("days", lang: lang))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    if habit.isReminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Checkmark button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(habit.isCompletedToday ? Color.green : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    if habit.isCompletedToday {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
    }
}
// MARK: - Add Habit Sheet View
struct AddHabitView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var store: HabitStore
    let lang: AppLanguage
    
    @State private var title = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "007AFF"
    @State private var isReminderEnabled = false
    @State private var reminderTime = Date()
    
    let icons = ["star.fill", "flame.fill", "drop.fill", "figure.walk", "book.fill", "bed.double.fill", "heart.fill", "leaf.fill", "bolt.fill", "music.note"]
    let colors = ["007AFF", "34C759", "FF9500", "AF52DE", "FF2D55", "5856D6", "00C7BE", "FFCC00"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L10n.get("habit_name", lang: lang))) {
                    TextField(L10n.get("habit_placeholder", lang: lang), text: $title)
                }
                
                Section(header: Text(L10n.get("icon_color", lang: lang))) {
                    // Icon Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 42, height: 42)
                                        .background(selectedIcon == icon ? Color(hex: selectedColor) : Color(uiColor: .tertiarySystemGroupedBackground))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Color Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { hex in
                                Button(action: { selectedColor = hex }) {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == hex ? 3 : 0)
                                        )
                                        .shadow(color: Color.black.opacity(selectedColor == hex ? 0.2 : 0), radius: 4)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text(L10n.get("reminder", lang: lang))) {
                    Toggle(L10n.get("enable_reminder", lang: lang), isOn: $isReminderEnabled)
                    if isReminderEnabled {
                        DatePicker(L10n.get("time", lang: lang), selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(L10n.get("add_habit", lang: lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.get("cancel", lang: lang)) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.get("save", lang: lang)) {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let newHabit = Habit(
                            title: title,
                            icon: selectedIcon,
                            colorHex: selectedColor,
                            isReminderEnabled: isReminderEnabled,
                            reminderTime: reminderTime,
                            completedDates: []
                        )
                        store.addHabit(newHabit)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
// MARK: - Settings Sheet View
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLanguage: AppLanguage
    @Binding var selectedTheme: Int
    let lang: AppLanguage
    
    var body: some View {
        NavigationView {
            Form {
                // Language
                Section(header: Text(L10n.get("language", lang: lang))) {
                    Picker(L10n.get("language", lang: lang), selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Theme
                Section(header: Text(L10n.get("theme", lang: lang))) {
                    Picker(L10n.get("theme", lang: lang), selection: $selectedTheme) {
                        Text(L10n.get("theme_system", lang: lang)).tag(0)
                        Text(L10n.get("theme_light", lang: lang)).tag(1)
                        Text(L10n.get("theme_dark", lang: lang)).tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // About
                Section(header: Text(L10n.get("about", lang: lang))) {
                    HStack {
                        Text(L10n.get("version", lang: lang))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle(L10n.get("settings", lang: lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8)  17, (int >> 4 & 0xF)  17, (int & 0xF)  17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}