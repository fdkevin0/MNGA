//
//  TopicListView.swift
//  NGA
//
//  Created by Bugen Zhao on 6/28/21.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

#if os(iOS)
  import SwiftUIRefresh
#endif

struct TopicListView: View {
  let forum: Forum

  @EnvironmentObject var activity: ActivityModel

  @StateObject var dataSource: PagingDataSource<TopicListResponse, Topic>

  @State var currentShowingSubforum: Forum? = nil
  @State var showingSubforumsModal = false
  @State var showingHotTopics = false
  @State var userActivityIsActive = true

  static func build(forum: Forum) -> Self {
    let dataSource = PagingDataSource<TopicListResponse, Topic>(
      buildRequest: { page in
        return .topicList(TopicListRequest.with {
          $0.id = forum.id
          $0.page = UInt32(page)
        })
      },
      onResponse: { response in
        let items = response.topics
        let pages = response.pages
        return (items, Int(pages))
      },
      id: \.id
    )
    return Self.init(forum: forum, dataSource: dataSource)
  }

  @ViewBuilder
  var moreMenu: some View {
    Menu {
      Section {
        Button(action: { showingHotTopics = true }) {
          Label("Hot Topics", systemImage: "flame")
        }
        if let subforums = dataSource.latestResponse?.subforums,
          !subforums.isEmpty {
          Button(action: { showingSubforumsModal = true }) {
            Label("Subforums", systemImage: "line.horizontal.3.decrease.circle")
          }
        }
        Button(action: { self.activity.put(URL(string: webpageURL)) }) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }

      Section {
        #if os(macOS)
          Button(action: { dataSource.refresh() }) {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
        #endif
        Label(forum.idDescription + " " + (dataSource.latestResponse?.forum.name ?? ""), systemImage: "number")
      }
    } label: {
      Label("More", systemImage: "ellipsis.circle")
        .imageScale(.large)
    }
  }

  @ViewBuilder
  var subforumsModal: some View {
    if let subforums = dataSource.latestResponse?.subforums, !subforums.isEmpty {
      NavigationView {
        SubforumListView(
          forum: forum,
          subforums: subforums,
          refresh: { dataSource.refresh() },
          onNavigateToForum: {
            self.showingSubforumsModal = false
            self.currentShowingSubforum = $0
          }
        )
      }
    }
  }

  @ViewBuilder
  var subforum: some View {
    if let forum = self.currentShowingSubforum {
      let destination = TopicListView.build(forum: forum)
      NavigationLink(destination: destination, isActive: $currentShowingSubforum.isNotNil()) { }
    }
    NavigationLink(destination: EmptyView()) { } // hack: unexpected pop
  }

  @ViewBuilder
  var hotTopics: some View {
    let destination = HotTopicListView.build(forum: forum)
    NavigationLink(destination: destination, isActive: $showingHotTopics) { }
  }

  var body: some View {
    Group {
      if dataSource.items.isEmpty {
        ProgressView()
      } else {
        List {
          Section(header: Text("Latest Topics")) {
            ForEach(dataSource.items, id: \.id) { topic in
              NavigationLink(destination: TopicDetailsView.build(topic: topic)) {
                TopicRowView(topic: topic)
              } .onAppear { dataSource.loadMoreIfNeeded(currentItem: topic) }
            }
          }
        }
        #if os(iOS)
          .listStyle(GroupedListStyle())
            .pullToRefresh(isShowing: .constant(dataSource.isRefreshing)) { dataSource.refresh() }
        #endif
      }
    }
      .sheet(isPresented: $showingSubforumsModal) { subforumsModal }
      .background { subforum; hotTopics }
      .navigationTitle(forum.name)
      .modifier(SingleItemToolbarModifier { moreMenu })
      .onAppear { dataSource.initialLoad(); userActivityIsActive = true }
      .onDisappear {
        // in iOS 15.0b5, this will make TopicDetailsView's onAppear called unexpectedly on navigation popping
        // userActivityIsActive = false
      }
      .userActivity(Constants.Activity.openForum, isActive: userActivityIsActive) { activity in
      activity.title = forum.name
      if let url = URL(string: webpageURL) {
        activity.webpageURL = url
      }
    }
  }

  var webpageURL: String {
    switch forum.id.id! {
    case .fid(let fid):
      return "\(Constants.URL.base)/thread.php?fid=\(fid)"
    case .stid(let stid):
      return "\(Constants.URL.base)/thread.php?stid=\(stid)"
    }
  }
}

struct TopicListView_Previews: PreviewProvider {
  static var previews: some View {
    let _ = Forum.with {
      $0.id = .with { i in i.fid = "-7" }
      $0.name = "大漩涡"
      $0.iconURL = "http://img4.nga.178.com/ngabbs/nga_classic/f/app/-7.png"
    }

    let genshinForum = Forum.with {
      $0.id = .with { i in i.fid = "650" }
      $0.name = "原神"
      $0.iconURL = "http://img4.nga.178.com/ngabbs/nga_classic/f/app/650.png"
    }

    AuthedPreview {
      NavigationView {
        TopicListView.build(forum: genshinForum)
      }
    }
  }
}
