// UILabel+ZeroModel.swift
// Convenience extension so ZeroModelValue binds directly to UILabel without `.string`.

#if canImport(UIKit)
import UIKit

public extension UILabel {

    /// Sets the label's text directly from a `ZeroModelValue`.
    ///
    ///     myLabel.zm_text = ZeroModel.loginModel.userName
    ///
    /// No crash even if the value is nil, NSNull, Int, Double, or Bool.
    var zm_text: ZeroModelValue? {
        get { return nil }
        set { self.text = newValue?.string }
    }
}

public extension UITextField {

    /// Sets the text field's text directly from a `ZeroModelValue`.
    var zm_text: ZeroModelValue? {
        get { return nil }
        set { self.text = newValue?.string }
    }
}

public extension UITextView {

    /// Sets the text view's text directly from a `ZeroModelValue`.
    var zm_text: ZeroModelValue? {
        get { return nil }
        set { self.text = newValue?.string }
    }
}
#endif
