//
//  ThermalState+Extensions.swift
//  Camera
//
//  Created by WON on 14/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import Foundation

extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal:
            return "NOMINAL"
        case .fair:
            return "FAIR"
        case .serious:
            return "SERIOUS"
        case .critical:
            return "CRITICAL"
        @unknown default:
            fatalError()
        }
    }
}
