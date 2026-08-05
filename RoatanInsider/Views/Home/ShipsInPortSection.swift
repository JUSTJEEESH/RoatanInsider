import SwiftUI

/// "Ships in Port Today" — daily-utility card that serves every user
/// type: locals dodge crowds, expats plan their week, vacationers
/// anticipate, cruise visitors see their own ship. Rendered whenever the
/// schedule data is current; the empty state ('quiet day') is itself
/// useful information. When the data has gone stale (scraper down, no
/// rows covering today) the card disappears entirely rather than
/// asserting a "quiet day" that may be wrong.
struct ShipsInPortSection: View {
    @Environment(CruiseArrivalsService.self) private var cruise

    var body: some View {
        if cruise.hasCurrentData {
            content
        }
    }

    private var content: some View {
        let ships = cruise.arrivalsToday()
        let tomorrow = cruise.arrivalsTomorrow()

        return VStack(alignment: .leading, spacing: 14) {
            header(passengers: cruise.totalPassengersToday(), count: ships.count)

            if ships.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(ships) { ship in
                        shipRow(ship)
                    }
                }
            }

            if !tomorrow.isEmpty {
                tomorrowPreview(count: tomorrow.count, passengers: cruise.totalPassengersTomorrow())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func tomorrowPreview(count: Int, passengers: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.riLightGray)
            Text(tomorrowLabel(count: count, passengers: passengers))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.riMediumGray)
        }
        .padding(.top, 4)
    }

    private func tomorrowLabel(count: Int, passengers: Int) -> String {
        let rounded = CruiseArrival.roundedToNearest500(passengers).commaFormatted
        switch count {
        case 1: return "Tomorrow: 1 ship · \(rounded) visitors"
        default: return "Tomorrow: \(count) ships · \(rounded) visitors"
        }
    }


    private func header(passengers: Int, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "ferry.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("SHIPS IN PORT TODAY")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
            }
            .foregroundStyle(Color.riMint)

            Text(headline(passengers: passengers, count: count))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.riDark)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            if count > 0 {
                Text("West Bay and West End run busier when ships are in.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.riLightGray)
                    .lineSpacing(2)
            }
        }
    }

    private func headline(passengers: Int, count: Int) -> String {
        let rounded = CruiseArrival.roundedToNearest500(passengers).commaFormatted
        switch count {
        case 0: return "Quiet day on the island"
        case 1: return "\(rounded) cruise visitors today"
        default: return "\(count) ships · \(rounded) visitors today"
        }
    }

    private var emptyState: some View {
        Text("No cruise ships in port. The beaches and dive sites are local-flow today.")
            .font(.system(size: 14))
            .foregroundStyle(Color.riMediumGray)
            .lineSpacing(3)
    }

    private func shipRow(_ ship: CruiseArrival) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ship.shipName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                Text("\(ship.port) · \(ship.hoursLabel)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.riLightGray)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(ship.displayPassengerCount.commaFormatted)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.riDark)
                    .monospacedDigit()
                Text("passengers")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.riLightGray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.riWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private extension Int {
    var commaFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
