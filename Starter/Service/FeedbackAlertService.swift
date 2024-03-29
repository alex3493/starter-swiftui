//
//  FeedbackAlertService.swift
//  Starter
//
//  Created by Alex on 29/3/24.
//

import Foundation
import SwiftUI

struct FeedbackAlert {
    let title: String
    
    let message: String
    
    let dismissButtonText: String?
    
    init(title: String, message: String, dismissButtonText: String? = nil) {
        self.title = title
        self.message = message
        self.dismissButtonText = dismissButtonText
    }
}

struct ConfirmationAlert {
    let title: String?
    
    let dismissButtonText: String?
    let confirmButtonText: String?
    
    let actionCallback: () -> Void
    
    init(title: String?, dismissButtonText: String?, confirmButtonText: String?, actionCallback: @escaping () -> Void) {
        self.title = title
        self.dismissButtonText = dismissButtonText
        self.confirmButtonText = confirmButtonText
        self.actionCallback = actionCallback
    }
}

final class FeedbackAlertService: ObservableObject {
    static let shared = FeedbackAlertService()
    
    private init() { }
    
    @Published private(set) var activeAlert: FeedbackAlert?
    
    @Published private(set) var activeConfirmation: ConfirmationAlert?
    
    var isPresentingAlert: Binding<Bool> {
        return Binding<Bool>(get: {
            return self.activeAlert != nil
        }, set: { newValue in
            guard !newValue else { return }
            self.activeAlert = nil
        })
    }
    
    var isPresentingConfirmation: Binding<Bool> {
        return Binding<Bool>(get: {
            return self.activeConfirmation != nil
        }, set: { newValue in
            guard !newValue else { return }
            self.activeConfirmation = nil
        })
    }
    
    func showAlertView(withTitle title: String, withMessage message: String, withButtonText dismissButtonText: String? = nil) {
        activeAlert = FeedbackAlert(title: title, message: message, dismissButtonText: dismissButtonText)
    }
    
    func showConfirmationView(
        withTitle title: String?,
        confirmButtonText: String?,
        dismissButtonText: String?,
        callback: @escaping () -> Void
    ) {
        activeConfirmation = ConfirmationAlert(title: title, dismissButtonText: dismissButtonText, confirmButtonText: confirmButtonText, actionCallback: callback)
    }
    
}

