import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  public init() {}

  public var body: some View {
    ZStack {
      GeometryReader { proxy in
        Text(verbatim: "Drawing view goes here")
          .counterRotating(longestSideLength: max(proxy.size.width, proxy.size.height))
      }
      .ignoresSafeArea()

      ToolbarView(
        store: Store(
          initialState: .init()
        ) {
          ToolbarFeature()
        }
      )
      .frame(maxHeight: .infinity, alignment: .bottom)
    }
    .statusBarHidden()
  }
}

#Preview {
  RootView()
}
