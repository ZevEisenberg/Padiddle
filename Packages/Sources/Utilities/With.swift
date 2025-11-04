public func with<Value, Failure: Error>(
  _ value: Value,
  modify: (inout Value) throws(Failure) -> Void
) throws(Failure) -> Value {
  var mutable = value
  try modify(&mutable)
  return mutable
}
