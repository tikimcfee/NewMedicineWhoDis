//
//  EditMode.swift
//  Drugs!
//
//  Created by Ivan Lugo on 4/4/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

enum EditMode: Int, CustomStringConvertible, CaseIterable {
    case add, delete, edit
    var description: String {
        switch self {
        case .add: return "New drug"
        case .delete: return "Delete"
        case .edit: return "Edit"
        }
    }
    var color: Color {
        switch self {
        case .add: return Color.green
        case .delete: return Color.red
        case .edit: return Color.primary
        }
    }
    var image: some View {
        switch self {
        case .add:
            return Image(systemName: "plus.circle.fill")
        case .edit:
            return Image(systemName: "pencil")
        case .delete:
            return Image(systemName: "minus.circle.fill")
        }
    }
}
