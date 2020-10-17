//
//  Step.swift
//  TabbedSwiftApp
//
//  Created by Christopher Erattuparambil on 10/13/20.
//  Copyright © 2020 Christopher Erattuparambil. All rights reserved.
//

import Foundation

struct Step: Identifiable {
    let id = UUID()
    let count: Int
    let date: Date
}
