//
//  MessageView.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import SwiftUI

struct MessageView: View {
    let index: Int
    let item: ChatMessage
    let isOutgoing: Bool
    let isSenderConnected: Bool
    
    var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading) {
            HStack {
                Text("\(item.createdAt?.formatted() ?? "")")
                if !isOutgoing {
                    Text("\(item.user.name)")
                }
                if isSenderConnected && !isOutgoing {
                    Image(systemName: "phone.connection.fill")
                }
            }
            Text(item.message)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(isOutgoing ? Color.blue : Color.gray)
                .foregroundColor(isOutgoing ? Color.white : Color.black)
                .cornerRadius(16)
        }
        .padding(5)
    }
}

//#Preview {
//    MessageView()
//}
