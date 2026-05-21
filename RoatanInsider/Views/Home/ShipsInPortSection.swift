import SwiftUI

/// "Ships in Port Today" — daily-utility card that serves every user
/// type: locals dodge crowds, expats plan their week, vacationers
/// anticipate, cruise visitors see their own ship. Always rendered;
/// empty state ('quiet day') is itself useful information.
struct ShipsInPortSection: View {
    @Environment(CruiseArrivalsService.self) private var cruise

    var body: some View {
        let ships = cruise.arrivalsToday()

        VStack(alignment: .leading, spacing: 14) {
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
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
        switch count {
        case 0: return "Quiet day on the island"
        case 1: return "\(passengers.commaFormatted) cruise visitors today"
        default: return "\(count) ships · \(passengers.commaFormatted) visitors today"
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
                Text(ship.passengerCount.commaFormatted)
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
