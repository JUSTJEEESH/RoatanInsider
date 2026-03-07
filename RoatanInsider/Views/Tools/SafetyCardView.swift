import SwiftUI
import MapKit

struct SafetyCardView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.riMint)

                Text("Emergency & Safety")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.riDark)

                Text("Keep this handy — just in case.")
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riMediumGray)
            }
            .padding(.top, 28)
            .padding(.bottom, 24)

            VStack(spacing: 16) {
                // Emergency numbers
                sectionLabel("Emergency Numbers")

                emergencyRow(
                    icon: "phone.fill",
                    title: "Emergency (Police/Fire/Ambulance)",
                    number: "911",
                    color: .riPink
                )

                emergencyRow(
                    icon: "staroflife.fill",
                    title: "Tourist Police",
                    number: "+504 2445-3438",
                    color: .riMint
                )

                emergencyRow(
                    icon: "cross.fill",
                    title: "Red Cross Honduras",
                    number: "195",
                    color: .riPink
                )

                emergencyRow(
                    icon: "flame.fill",
                    title: "Fire Department",
                    number: "198",
                    color: .orange
                )

                Divider()
                    .padding(.vertical, 4)

                // Medical
                sectionLabel("Medical")

                infoRow(
                    icon: "building.2.fill",
                    title: "Woods Medical Center",
                    subtitle: "Coxen Hole — Full hospital",
                    phone: "+504 2445-1080"
                )

                infoRow(
                    icon: "building.2.fill",
                    title: "Clinica Esperanza",
                    subtitle: "Sandy Bay — Free/low-cost clinic for travelers",
                    phone: "+504 2445-3234"
                )

                infoRow(
                    icon: "waveform.path.ecg",
                    title: "Hyperbaric Chamber",
                    subtitle: "Anthony's Key Resort, Sandy Bay — For dive emergencies",
                    phone: "+504 2445-3049"
                )

                Divider()
                    .padding(.vertical, 4)

                // Consulates
                sectionLabel("Consulates & Embassies")

                infoRow(
                    icon: "flag.fill",
                    title: "US Embassy (Tegucigalpa)",
                    subtitle: "Nearest US consular services",
                    phone: "+504 2236-9320"
                )

                infoRow(
                    icon: "flag.fill",
                    title: "Canadian Embassy (Tegucigalpa)",
                    subtitle: "Nearest Canadian consular services",
                    phone: "+504 2232-4551"
                )

                Divider()
                    .padding(.vertical, 4)

                // Safety tips
                sectionLabel("Quick Safety Tips")

                VStack(alignment: .leading, spacing: 10) {
                    tipRow("Use official taxis or arrange transport through your hotel — avoid unmarked vehicles")
                    tipRow("Keep valuables in your hotel safe and leave flashy jewelry at home")
                    tipRow("Stick to well-traveled areas after dark, especially if you're alone")
                    tipRow("Drink bottled or filtered water outside of resorts")
                    tipRow("Reef-safe sunscreen is required by law — shops near the beach sell it")
                    tipRow("Verify your dive operator is PADI or SSI certified before booking")
                    tipRow("Carry small bills — many local vendors can't break large USD notes")
                    tipRow("Screenshot your hotel address and GPS pin before heading out — cell service is spotty")
                    tipRow("Don't leave belongings unattended on the beach, even briefly")
                    tipRow("Negotiate taxi fares before getting in — agree on a price upfront")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Components

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.riLightGray)
                .tracking(1.5)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func emergencyRow(icon: String, title: String, number: String, color: Color) -> some View {
        Button {
            Haptics.impact()
            let cleaned = number.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            if let url = URL(string: "tel:\(cleaned)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.riDark)

                    Text(number)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(color)
                }

                Spacer()

                Image(systemName: "phone.arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.riLightGray)
            }
            .padding(14)
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Call \(title) at \(number)")
        .accessibilityHint("Double tap to call")
    }

    private func infoRow(icon: String, title: String, subtitle: String, phone: String) -> some View {
        Button {
            Haptics.impact()
            let cleaned = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            if let url = URL(string: "tel:\(cleaned)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.riMint)
                    .frame(width: 36, height: 36)
                    .background(Color.riMint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.riDark)

                    Text(subtitle)
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riMediumGray)

                    Text(phone)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.riMint)
                }

                Spacer()

                Image(systemName: "phone.arrow.up.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.riLightGray)
            }
            .padding(14)
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle). Phone: \(phone)")
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.riMint)
                .frame(width: 6, height: 6)
                .padding(.top, 7)

            Text(text)
                .font(.riCaption(14))
                .foregroundStyle(Color.riMediumGray)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}
