import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

// App Group compartido con la app (mismo id que HomeWidgetService en Flutter)
private let appGroupId = "group.com.andreistaicu.habitai"
private let payloadKey = "widget_payload"
private let pendingKey = "pending_checkins"
private let widgetKind = "HabitWidget"

// MARK: - Modelo del payload publicado por Flutter

struct WidgetHabit: Codable, Identifiable {
    let id: String
    let title: String
    var done: Bool
}

struct WidgetPayload: Codable {
    var date: String
    var completed: Int
    var total: Int
    var habits: [WidgetHabit]

    static let empty = WidgetPayload(date: "", completed: 0, total: 0, habits: [])
}

private func todayString() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    fmt.locale = Locale(identifier: "en_US_POSIX")
    return fmt.string(from: Date())
}

private func loadPayload() -> WidgetPayload {
    guard
        let defaults = UserDefaults(suiteName: appGroupId),
        let raw = defaults.string(forKey: payloadKey),
        let data = raw.data(using: .utf8),
        let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
    else { return .empty }
    // datos de otro día: no mostrar checks viejos como si fueran de hoy
    if payload.date != todayString() {
        return .empty
    }
    return payload
}

// MARK: - Timeline

struct HabitEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload
}

struct HabitTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(
            date: Date(),
            payload: WidgetPayload(
                date: todayString(),
                completed: 2,
                total: 5,
                habits: [
                    WidgetHabit(id: "1", title: "Meditar 10 min", done: true),
                    WidgetHabit(id: "2", title: "Leer 20 min", done: false),
                    WidgetHabit(id: "3", title: "Salir a caminar", done: false),
                ]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        completion(HabitEntry(date: Date(), payload: loadPayload()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let entry = HabitEntry(date: Date(), payload: loadPayload())
        // re-render cada 30 min (y al cruzar medianoche el payload se invalida solo)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Intent de check-in (iOS 17+): marca optimista + cola para la app

#if canImport(AppIntents)
@available(iOS 17.0, *)
struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Completar hábito"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Habit ID")
    var habitId: String

    init() {}

    init(habitId: String) {
        self.habitId = habitId
    }

    func perform() async throws -> some IntentResult {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return .result() }

        // 1. marca optimista en el payload para feedback inmediato en el widget
        if let raw = defaults.string(forKey: payloadKey),
           let data = raw.data(using: .utf8),
           var payload = try? JSONDecoder().decode(WidgetPayload.self, from: data),
           payload.date == todayString(),
           let idx = payload.habits.firstIndex(where: { $0.id == habitId }),
           !payload.habits[idx].done {
            payload.habits[idx].done = true
            payload.completed += 1
            if let encoded = try? JSONEncoder().encode(payload),
               let str = String(data: encoded, encoding: .utf8) {
                defaults.set(str, forKey: payloadKey)
            }
        }

        // 2. encolar el check-in: la app lo escribe en Firestore al abrirse
        var pending = defaults.stringArray(forKey: pendingKey) ?? []
        if !pending.contains(habitId) {
            pending.append(habitId)
            defaults.set(pending, forKey: pendingKey)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        return .result()
    }
}
#endif

// MARK: - Vista

struct HabitWidgetEntryView: View {
    var entry: HabitEntry

    private var percent: Int {
        entry.payload.total > 0
            ? entry.payload.completed * 100 / entry.payload.total
            : 0
    }

    var body: some View {
        HStack(spacing: 16) {
            // anillo de progreso
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: CGFloat(percent) / 100)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.payload.completed)/\(entry.payload.total)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 64, height: 64)

                Text("\(percent)%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            // lista de hábitos
            VStack(alignment: .leading, spacing: 6) {
                if entry.payload.habits.isEmpty {
                    Text(entry.payload.date.isEmpty
                        ? "Abre HabitAI para actualizar"
                        : "Sin hábitos hoy")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    ForEach(entry.payload.habits) { habit in
                        habitRow(habit)
                    }
                    if entry.payload.total > entry.payload.habits.count {
                        Text("+\(entry.payload.total - entry.payload.habits.count) más…")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .widgetBackground(
            LinearGradient(
                colors: [
                    Color(red: 0 / 255, green: 102 / 255, blue: 138 / 255),
                    Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    @ViewBuilder
    private func habitRow(_ habit: WidgetHabit) -> some View {
        HStack(spacing: 8) {
            Text(habit.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 4)
            if #available(iOS 17.0, *), !habit.done {
                // check-in sin abrir la app (App Intent)
                Button(intent: CheckInIntent(habitId: habit.id)) {
                    checkCircle(done: false)
                }
                .buttonStyle(.plain)
            } else {
                // iOS 15/16 o ya completado: el tap abre la app
                checkCircle(done: habit.done)
            }
        }
    }

    @ViewBuilder
    private func checkCircle(done: Bool) -> some View {
        ZStack {
            Circle()
                .fill(done
                    ? Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
                    : Color.white.opacity(0.1))
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Circle().stroke(Color.white.opacity(0.7), lineWidth: 1.5)
            }
        }
        .frame(width: 24, height: 24)
    }
}

// containerBackground es obligatorio en iOS 17; en 15/16 se usa background normal
extension View {
    @ViewBuilder
    func widgetBackground(_ background: some View) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            self.background(background)
        }
    }
}

// MARK: - Widget

struct HabitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: HabitTimelineProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("HabitAI — Hoy")
        .description("Tu progreso del día y check-ins rápidos.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct HabitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitWidget()
    }
}
