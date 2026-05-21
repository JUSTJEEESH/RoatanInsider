import SwiftUI

/// Minimal V1 event detail page. Phase 2 will add: venue lookup,
/// map mini-view, directions button, saved-event favorites,
/// "Add to Calendar," share, and notification reminders.
struct EventDetailView: View {
    let event: Event

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

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
