//
//  TopicJumpSelectorView.swift
//  MNGA
//
//  Created by Bugen Zhao on 2021/10/22.
//

import Foundation
import SwiftUI
import SwiftUIX

struct TopicJumpSelectorView: View {
  enum Mode: String, CaseIterable {
    case floor = "Floor"
    case page = "Page"
  }

  let maxFloor: Int
  let floorToJump: Binding<Int?>?
  let pageToJump: Binding<Int?>?
  
  init(maxFloor: Int, initialFloor: Int = 1, floorToJump: Binding<Int?>? = nil, pageToJump: Binding<Int?>? = nil) {
    self.maxFloor = maxFloor
    self.floorToJump = floorToJump
    self.pageToJump = pageToJump
    self._selectedFloor = .init(initialValue: initialFloor)
  }

  var maxPage: Int { (maxFloor + Constants.postPerPage - 1) / Constants.postPerPage }

  @Environment(\.presentationMode) var presentation

  @State var mode = Mode.floor
  @State var selectedFloor: Int

  var selectedPage: Binding<Int> {
      .init(get: { (selectedFloor + Constants.postPerPage - 1) / Constants.postPerPage }, set: { selectedFloor = ($0 - 1) * Constants.postPerPage + 1 })
  }


  @ViewBuilder
  var picker: some View {
    Picker("Mode", selection: $mode.animation()) {
      ForEach(Mode.allCases, id: \.rawValue) {
        Text(LocalizedStringKey($0.rawValue)).tag($0)
      }
    } .pickerStyle(SegmentedPickerStyle())
      .frame(width: 150)
  }

  @ViewBuilder
  var jumpButton: some View {
    Button(action: { commit() }) { Text("Jump").bold() }
  }

  @ViewBuilder
  var main: some View {
    Group {
      switch mode {
      case .floor:
        Picker("Floor", selection: $selectedFloor) {
          ForEach(1..<maxFloor + 1) { i in
            Text("Floor \(i)").tag(i)
          }
        }
      case .page:
        Picker("Page", selection: selectedPage) {
          ForEach(1..<maxPage + 1) { i in
            Text("Page \(i)").tag(i)
          }
        }
      }
    }
      .padding()
  }

  func commit() {
    floorToJump?.wrappedValue = selectedFloor
    pageToJump?.wrappedValue = selectedPage.wrappedValue
    presentation.dismiss()
  }

  var body: some View {
    NavigationView {
      main
        .pickerStyle(.wheel)
        .navigationBarTitleView(picker)
        .toolbarWithFix { ToolbarItem(placement: .primaryAction) { jumpButton } }
    }
  }
}

struct TopicJumpSelectorView_Previews: PreviewProvider {
  static var previews: some View {
    TopicJumpSelectorView(maxFloor: 210, floorToJump: .constant(nil))
  }
}
