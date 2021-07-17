//
//  NotificationListView.swift
//  NotificationListView
//
//  Created by Bugen Zhao on 7/17/21.
//

import Foundation
import SwiftUI
import SwiftUIX

struct NotificationListView: View {
  typealias DataSource = PagingDataSource<FetchNotificationResponse, Notification>

  @StateObject var dataSource: DataSource

  static func build() -> Self {
    let dataSource = DataSource.init(
      buildRequest: { _ in
        return .fetchNotification(.with { _ in })
      },
      onResponse: { response in
        let items = response.notis
        return (items, 1)
      },
      id: \.hashIdentifiable.description
    )

    return Self(dataSource: dataSource)
  }

  var body: some View {
    List {
      ForEach(dataSource.items, id: \.hashIdentifiable) { notification in
        let topic = Topic.with {
          $0.id = notification.otherPostID.tid
          $0.subjectContent = notification.topicSubject
        }
        NavigationLink(destination: TopicDetailsView.build(topic: topic)) {
          NotificationRowView(noti: notification)
        }
      }
    } .navigationTitle("Notifications")
      .onAppear { dataSource.initialLoad() }
    #if os(iOS)
      .listStyle(GroupedListStyle())
      .pullToRefresh(isShowing: .constant(dataSource.isRefreshing)) { dataSource.refresh() }
    #endif
  }
}

