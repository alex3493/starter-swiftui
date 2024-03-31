//
//  ErrorAlertViewModifier.swift
//  Starter
//
//  Created by Alex on 30/3/24.
//

import Foundation
import SwiftUI

struct ErrorAlertViewModifier: ViewModifier {
    
    @ObservedObject var errorStore = ErrorService.shared
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: errorStore.isPresentingAlert) {
                Alert(
                    title: Text((errorStore.activeError?.errorDescription)!),
                    message: Text((errorStore.activeError?.failureReason)!)
                )
            }
    }
}
