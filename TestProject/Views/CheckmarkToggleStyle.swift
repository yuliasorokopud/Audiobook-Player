import SwiftUI

struct CheckmarkToggleStyle: ToggleStyle {
    enum Constant {
        static let headphonesIcon = "headphones"
        static let textIcon = "text.alignleft"
        static let capsuleSize: CGSize = .init(width: 110, height: 55)
    }
    func makeBody(configuration: Configuration) -> some View {
        Capsule(style: .continuous)
            .fill(.white)
            .stroke(.gray.opacity(UIConstant.Alpha.almostClear), lineWidth: UIConstant.Border.Width.one)
            .animation(.default, value: configuration.isOn)
            .frame(width: Constant.capsuleSize.width, height: Constant.capsuleSize.height)
            .overlay(alignment: configuration.isOn ? .trailing:.leading) {
                Circle().fill(.blue).padding(UIConstant.Spacing.smallB)
            }
            .overlay(alignment: .center,
                     content: {
                HStack(spacing: UIConstant.Spacing.largeA) {
                    Image(systemName: Constant.headphonesIcon)
                        .bold()
                        .font(.body)
                        .foregroundColor(configuration.isOn ? .black : .white)
                    Image(systemName: Constant.textIcon)
                        .bold()
                        .font(.body)
                        .foregroundColor(configuration.isOn ? .white : .black)
                }
                .padding(.horizontal, UIConstant.Spacing.mediumA)
            })
            .animation(.spring(response: 0.6, dampingFraction: 0.52), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
    }
}
