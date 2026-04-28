import SwiftUI

struct ModuleSwatch: View {
    let colorHex: String?
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(hex: colorHex ?? Module.defaultColorHex))
            .frame(width: size, height: size)
    }
}
