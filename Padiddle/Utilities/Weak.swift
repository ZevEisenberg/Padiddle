class Weak<T: AnyObject>: CustomStringConvertible {
  weak var value: T?
  init(value: T) {
    self.value = value
  }

  var description: String {
    if let value {
      "Weak(\(value))"
    } else {
      "Weak(nil)"
    }
  }
}
