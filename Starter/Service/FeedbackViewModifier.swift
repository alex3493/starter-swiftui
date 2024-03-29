//
//  FeedbackAlertModifier.swift
//  Starter
//
//  Created by Alex on 29/3/24.
//

import Foundation
import SwiftUI

struct FeedbackViewModifier: ViewModifier {
    @ObservedObject var feedbackStore = FeedbackAlertService.shared
    
    @ObservedObject var errorStore = ErrorService.shared
    
    func body(content: Content) -> some View {
        // Here we cannot chain alerts, i.e. attach more than one alert to the same view.
        // So we are using a simple condition below.
        if errorStore.isPresentingAlert.wrappedValue {
            content
                .alert(isPresented: errorStore.isPresentingAlert) {
                    Alert(
                        title: Text((errorStore.activeError?.errorDescription)!),
                        message: Text((errorStore.activeError?.failureReason)!)
                    )
                }
        } else if feedbackStore.isPresentingAlert.wrappedValue {
            content
                .alert(isPresented: feedbackStore.isPresentingAlert) {
                    Alert(
                        title: Text((feedbackStore.activeAlert?.title)!),
                        message: Text((feedbackStore.activeAlert?.message)!),
                        dismissButton: .default(Text(feedbackStore.activeAlert?.dismissButtonText ?? "OK"))
                    )
                }
        } else if feedbackStore.isPresentingConfirmation.wrappedValue {
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
        } else {
            content
        }
    }
    
}
