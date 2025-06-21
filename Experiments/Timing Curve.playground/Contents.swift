#if os(OSX)
"AppKit"
import AppKit
#else
"UIKit"
import UIKit
#endif

func rotationFraction(forFraction x: Double) -> Double {
  let a = 6.0
  let numerator = atan(a * (x - 0.5))
  let denominator = 2 * atan(a / 2)
  return numerator / denominator + 0.5
}

// Algorithm suggested by Sam Critchlow here: https://www.facebook.com/ZevEisenberg/posts/10209176689033901?comment_id=10209197282908735&comment_tracking=%7B%22tn%22%3A%22R0%22%7D

let duration: Double = 2
let framesPerSecond = 60.0
let frameCount = duration * framesPerSecond

let frameFractions = stride(from: 0, through: 1.0, by: 1.0 / frameCount)

let fractions = frameFractions.map {
  rotationFraction(forFraction: Double($0))
}

fractions.map(\.self)
