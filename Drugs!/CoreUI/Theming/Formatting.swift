//
//  Formatting.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/21/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

// Statically used
let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

let dateFormatterSmall: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    return dateFormatter
}()
