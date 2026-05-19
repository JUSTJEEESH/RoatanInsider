import SwiftUI
import StoreKit

/// Insider+ paywall. Premium, photo-driven, single-screen design — no scrolling
/// gimmicks, no fake countdowns, no manipulative copy. The conversion bet is
/// "the app is good enough that genuine fans want to support it and unlock the
/// smart bits."
///
/// Three states it must handle:
///   1. Loading products (skeleton).
///   2. Two products available — yearly preselected with "Best value" tag.
///   3. Grandfathered user — show a thank-you, no buy button.
struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: String = PurchaseManager.yearlyProductID
    @State private var isPurchasing: Bool = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        benefits
                        if !purchases.isGrandfathered {
                            productCards
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }

                Spacer(minLength: 0)

                if purchases.isGrandfathered {
                    grandfatherFooter
                } else {
                    ctaSection
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await purchases.refresh()
            Analytics.track(.paywallShown(source: "tools_chip"))
        }
        .onDisappear {
            Analytics.track(.paywallDismissed(source: "tools_chip"))
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color.riNearBlack.ignoresSafeArea()

            VStack {
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .foregroundStyle(Color.riPink.opacity(0.06))
                    .blur(radius: 8)
                    .padding(.top, 80)
                Spacer()
            }
            .allowsHitTesting(false)
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "palm.tree.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.riPink)
                Text("ROATÁN INSIDER+")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.riPink)
            }

            Text("Smarter than every other meal.")
                .riDisplayStyle(30)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Text("Insider+ unlocks the live, intelligent, offline-first parts of Roatán Insider.")
                .font(.riBody)
                .foregroundStyle(Color.riLightGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Benefits

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefit(icon: "sparkles", title: "AI itinerary builder", detail: "A day-by-day plan tailored to you, in seconds.")
            benefit(icon: "timer", title: "Cruise Day Live Activity", detail: "Lock-screen countdown so you never miss the ship.")
            benefit(icon: "wifi.slash", title: "Offline map tiles", detail: "Full island map without signal, anywhere on Roatán.")
            benefit(icon: "bell.badge", title: "Smart alerts", detail: "Sunset, happy hours, and live music at the spots you save.")
            benefit(icon: "icloud.fill", title: "Cloud-synced favorites", detail: "Saved places follow you across iPhone and iPad.")
            benefit(icon: "tag.fill", title: "Insider Pass discounts", detail: "Real money off at participating businesses across the island.")
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func benefit(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.riMint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
            }

            Spacer()
        }
    }

    // MARK: - Product cards

    private var productCards: some View {
        VStack(spacing: 12) {
            if purchases.products.isEmpty {
                skeletonCards
            } else {
                ForEach(purchases.products, id: \.id) { product in
                    productCard(product)
                }
            }
        }
    }

    private var skeletonCards: some View {
        VStack(spacing: 12) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 72)
                    .overlay(ProgressView().tint(Color.riMint))
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isYearly = product.id == PurchaseManager.yearlyProductID

        return Button {
            Haptics.select()
            selectedProductID = product.id
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? Color.riPink : Color.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(productTitle(product))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)

                        if isYearly, purchases.yearlySavingsLabel != nil {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.riNearBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.riMint)
                                .clipShape(Capsule())
                        }
                    }

                    Text(productSubtitle(product))
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(isSelected ? Color.riPink.opacity(0.15) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.riPink : Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func productTitle(_ product: Product) -> String {
        product.id == PurchaseManager.yearlyProductID ? "Yearly" : "Monthly"
    }

    private func productSubtitle(_ product: Product) -> String {
        if product.id == PurchaseManager.yearlyProductID {
            return purchases.yearlySavingsLabel.map { "\($0) — billed yearly" } ?? "Billed yearly"
        }
        return "Billed monthly. Cancel anytime."
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.impact()
                purchase()
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Start Insider+")
                            .font(.riButton)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.buttonHeight)
                .background(Color.riPink)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
            }
            .disabled(isPurchasing || purchases.products.isEmpty)
            .opacity((isPurchasing || purchases.products.isEmpty) ? 0.6 : 1)

            HStack(spacing: 24) {
                Button("Restore Purchases") {
                    Task {
                        Haptics.tap()
                        await purchases.restore()
                        if purchases.hasPremium { dismiss() }
                    }
                }
                .font(.riCaption(13))
                .foregroundStyle(Color.riLightGray)

                Link("Terms", destination: URL(string: "\(AppConstants.webOrigin)/terms")!)
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)

                Link("Privacy", destination: URL(string: "\(AppConstants.webOrigin)/privacy")!)
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
            }

            Text("Auto-renews until cancelled. Manage in Settings.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.riLightGray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var grandfatherFooter: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.riMint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You're an Insider+ founding member.")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Thanks for being an early supporter — all features unlocked, forever.")
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)
                        .lineSpacing(2)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.riMint.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.riMint.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                Haptics.tap()
                dismiss()
            } label: {
                Text("Continue")
                    .font(.riButton)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.buttonHeight)
                    .background(Color.riPink)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func purchase() {
        guard let product = purchases.products.first(where: { $0.id == selectedProductID }) else { return }
        Analytics.track(.paywallProductSelected(productId: product.id))
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            let ok = await purchases.purchase(product)
            if ok {
                Analytics.track(.paywallPurchaseSucceeded(productId: product.id))
                dismiss()
            } else {
                Analytics.track(.paywallPurchaseFailed(reason: purchases.lastError ?? "cancelled"))
            }
        }
    }
}
