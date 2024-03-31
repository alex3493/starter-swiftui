//
//  FeedbackAlertViewModifier.swift
//  Starter
//
//  Created by Alex on 30/3/24.
//

import Foundation
import SwiftUI

struct FeedbackAlertViewModifier: ViewModifier {
    
    @ObservedObject var feedbackStore = FeedbackAlertService.shared
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: feedbackStore.isPresentingAlert) {
                Alert(
                    title: Text((feedbackStore.activeAlert?.title)!),
                    message: Text((feedbackStore.activeAlert?.message)!),
                    dismissButton: .default(Text(feedbackStore.activeAlert?.dismissButtonText ?? "OK"))
                )
            }
    }
}
