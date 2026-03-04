import SwiftUI

struct InsightsStatGrid: View {
    struct Item: Identifiable {
        let id = UUID()
        let systemImage: String
        let iconColor: Color
        let value: String
        let label: String
    }

    let items: [Item]

    private let columns = [
        GridItem(.flexible(), spacing: NSpacing.md),
        GridItem(.flexible(), spacing: NSpacing.md)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: NSpacing.md) {
            ForEach(items) { item in
                NStatCard(
                    systemImage: item.systemImage,
                    iconColor: item.iconColor,
                    value: item.value,
                    label: item.label
                )
            }
        }
    }
}
