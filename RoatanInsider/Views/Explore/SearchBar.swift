import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.riLightGray)

            TextField("Search places, areas, what you fancy…", text: $text)
                .riType(.body)
                .foregroundStyle(Color.riDark)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.riLightGray)
                }
            }
        }
        .padding(.horizontal, AppConstants.Space.snug + 2)
        .padding(.vertical, AppConstants.Space.snug)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small, style: .continuous))
    }
}
