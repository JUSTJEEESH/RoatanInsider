import SwiftUI
import EventKit

/// Event detail page. Phase 3 actions: heart (save to favorites),
/// add to calendar (native EventKit sheet), directions (Apple Maps),
/// share (system share sheet).
struct EventDetailView: View {
    let event: Event
    @Environment(EventFavoritesStore.self) private var favorites
    @State private var calendarEvent: EKEvent?
    @State private var calendarStore = EKEventStore()
    @State private var showCalendarSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                actionRow

                if let genre = event.genre {
                    detailRow(icon: "music.quarternote.3", label: "Genre", value: genre)
                }

                if let notes = event.notes {
                    detailRow(icon: "info.circle", label: "Notes", value: notes)
                }

                if let recurringRule = event.recurringRule {
                    detailRow(icon: "arrow.clockwise", label: "Schedule", value: recurringRule)
                }

                detailRow(icon: "mappin.and.ellipse", label: "Where", value: "\(event.venue) · \(event.area)")

                if let contact = event.contact {
                    detailRow(icon: "phone", label: "Contact", value: contact)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .navigationTitle(event.performer)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
        .sheet(isPresented: $showCalendarSheet) {
            if let calendarEvent {
                CalendarEventEditor(event: calendarEvent, eventStore: calendarStore)
                    .ignoresSafeArea()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: event.category.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.riMint)
                Text(event.category.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.riMint)
                if event.isLiveNow() {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("LIVE NOW")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Color.green)
                    }
                }
                Spacer()
                heartButton
            }

            Text(event.performer)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.riDark)

            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .medium))
                Text(event.displayTime)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.riMediumGray)
        }
    }

    private var heartButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                favorites.toggle(event)
            }
            Haptics.tap()
        } label: {
            Image(systemName: favorites.isFavorited(event) ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(favorites.isFavorited(event) ? Color.riPink : Color.riLightGray)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(favorites.isFavorited(event) ? "Remove from favorites" : "Save to favorites")
    }

    private var actionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    openCalendarSheet()
                } label: {
                    actionLabel(icon: "calendar.badge.plus", title: "Add to Calendar")
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap()
                    openDirections()
                } label: {
                    actionLabel(icon: "location.fill", title: "Directions")
                }
                .buttonStyle(.plain)

                ShareLink(item: shareText) {
                    actionLabel(icon: "square.and.arrow.up", title: "Share")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func actionLabel(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.riPink)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.riPink.opacity(0.1))
        .clipShape(Capsule())
    }

    private var shareText: String {
        var lines = ["\(event.performer) at \(event.venue), \(event.area)"]
        lines.append("\(event.displayTime)")
        if let rule = event.recurringRule {
            lines.append(rule)
        }
        lines.append("— via Roatán Insider")
        return lines.joined(separator: "\n")
    }

    private func openCalendarSheet() {
        guard let ek = EventCalendarHelper.makeEKEvent(from: event, store: calendarStore) else {
            return
        }
        calendarEvent = ek
        showCalendarSheet = true
    }

    private func openDirections() {
        let query = "\(event.venue) \(event.area) Roatán Honduras"
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://maps.apple.com/?q=\(encoded)") else { return }
        UIApplication.shared.open(url)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.riLightGray)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.riLightGray)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.riDark)
            }
            Spacer(minLength: 0)
        }
    }
}
