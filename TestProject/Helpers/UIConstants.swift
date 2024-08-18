import SwiftUI

enum UIConstant {
    enum Spacing {
        public static let zero: CGFloat = 0.0
        public static let smallA: CGFloat = 2.0
        public static let smallB: CGFloat = 4.0
        public static let smallC: CGFloat = 8.0
        public static let mediumA: CGFloat = 12.0
        public static let mediumB: CGFloat = 16.0
        public static let mediumC: CGFloat = 24.0
        public static let largeA: CGFloat = 32.0
        public static let largeB: CGFloat = 40.0
    }
    
    enum Radius {
        public static let small = 4.0
        public static let medium = 8.0
    }
    
    enum Alpha {
        public static let clear = 0.0
        public static let almostClear = 0.2
        public static let translucent = 0.5
        public static let opaque = 1.0
    }
    
    enum Border {
        public enum Width {
            public static let half = 0.5
            public static let one = 1.0
        }
    }
}
