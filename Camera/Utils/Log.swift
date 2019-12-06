//
//  Log.swift
//  Camera
//
//  Created by WON on 27/09/2018.
//  Copyright © 2018 trilliwon. All rights reserved.
//

import Foundation

struct Log {

    static func print(function: String = #function,
                      file: String = #file,
                      line: Int = #line,
                      error: Error? = nil,
                      _ items: Any...) {
        Swift.print("\n⚠️")

        let thread = Thread.isMainThread ? "MainThread" : Thread.current.name ?? "Not MainThread"

        Swift.print("⌖ At #\(line) in \(function) in \((file as NSString).lastPathComponent) - ⚙ \(thread) ⏱ \(Date())")

        if !items.isEmpty {
            Swift.print("🔍")
            items.forEach {
                debugPrint($0)
            }
        }
        Swift.print("🖕\n")
    }
}
