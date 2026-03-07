import SwiftUI

struct BusinessCTASection: View {
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("Own a business\non Roatán?")
                    .riDisplayStyle(30)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Get listed in the app, get featured to thousands of visitors, or add your menu so customers know what you serve before they walk in.")
                    .font(.riBody)
                    .foregroundStyle(Color.riLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }

            // Value props
            VStack(spacing: 20) {
                valueProp(
                    icon: "storefront",
                    title: "Get Listed",
                    description: "Put your business on the map — literally."
                )
                valueProp(
                    icon: "star",
                    title: "Get Featured",
                    description: "Be the first thing visitors see when they arrive."
                )
                valueProp(
                    icon: "menucard",
                    title: "Add Your Menu",
                    description: "No more outdated Facebook photos. Real menus, always current."
                )
            }
            .padding(.horizontal, 20)

            // Contact button
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://facebook.com/roataninsiderapp")!) {
                    HStack(spacing: 10) {
                        Image(systemName: "hand.wave")
                            .font(.system(size: 18, weight: .medium))
                        Text("Message Us on Facebook")
                            .font(.riButton)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.buttonHeight)
                    .background(Color.riPink)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
                }
                .padding(.horizontal, 40)

                Text("We'll get back to you within 24 hours")
                    .font(.riCaption())
                    .foregroundStyle(Color.riLightGray)
            }
        }
        .padding(.horizontal, 20)
    }

    private func valueProp(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.riMint)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riLightGray)
            }

            Spacer()
        }
    }
}
