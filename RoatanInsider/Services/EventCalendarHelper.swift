import EventKit
import EventKitUI
import SwiftUI

/// Builds an `EKEvent` from our `Event` model, ready to be handed to
/// `EKEventEditViewController`. The standard 'Add Event' sheet then
/// handles user permission + calendar selection + save.
///
/// REQUIRED Info.plist key (set via build settings since GENERATE_INFOPLIST_FILE = YES):
///   INFOPLIST_KEY_NSCalendarsWriteOnlyAccessUsageDescription = "Add events from
///     Roatán Insider to your calendar."
///
/// Without this key the EKEventEditViewController will crash on present.
enum EventCalendarHelper {
    /// Builds a calendar event for the next occurrence of `event`. For
    /// recurring weekly events, attaches a weekly recurrence rule so the
    /// user's calendar shows it every week going forward.
    static func makeEKEvent(from event: Event, store: EKEventStore, calendar: Calendar = .current) -> EKEvent? {
        guard let startDate = event.nextOccurrence(after: .now, calendar: calendar) else {
            return nil
        }
        // Assume 3-hour default duration unless an endTime is present.
        let endDate = calendar.date(byAdding: .hour, value: 3, to: startDate) ?? startDate.addingTimeInterval(3 * 3600)

        let ek = EKEvent(eventStore: store)
        ek.title = "\(event.performer) at \(event.venue)"
        ek.location = "\(event.venue), \(event.area), Roatán"
        ek.startDate = startDate
        ek.endDate = parseEndDate(from: event, baseDate: startDate, calendar: calendar) ?? endDate

        var notesLines: [String] = []
        if let genre = event.genre { notesLines.append("Genre: \(genre)") }
        if let raw = event.notes { notesLines.append(raw) }
        notesLines.append("Added from Roatán Insider")
        ek.notes = notesLines.joined(separator: "\n")

        // Weekly recurrence for the recurring events that make up most of
        // the schedule. One-offs (event.date != nil) get a single occurrence.
        if event.isRecurring, event.date == nil {
            let rule = EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                end: nil
            )
            ek.addRecurrenceRule(rule)
        }

        return ek
    }

    private static func parseEndDate(from event: Event, baseDate: Date, calendar: Calendar) -> Date? {
        guard let endRaw = event.endTime else { return nil }
        let parts = endRaw.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }
}

/// SwiftUI wrapper for `EKEventEditViewController`. Drives the iOS-native
/// 'Add Event' sheet pre-filled with our event's details.
struct CalendarEventEditor: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        private let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true)
            dismiss()
        }
    }
}
