//
//  FeedbackConfirmationViewModifier.swift
//  Starter
//
//  Created by Alex on 30/3/24.
//

import Foundation
import SwiftUI

struct FeedbackConfirmationViewModifier: ViewModifier {
    
    @ObservedObject var feedbackStore = FeedbackAlertService.shared
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(feedbackStore.activeConfirmation?.title ?? "Are you sure?", isPresented: feedbackStore.isPresentingConfirmation, titleVisibility: .visible, actions: {
                Button(role: .destructive) {
                    if let confirmation = feedbackStore.activeConfirmation {
                        confirmation.actionCallback()
                    }
                } label: {
                    Text(feedbackStore.activeConfirmation?.confirmButtonText ?? "Confirm")
                }
                Button(feedbackStore.activeConfirmation?.dismissButtonText ?? "Cancel", role: .cancel) {}
            })
    }
}
