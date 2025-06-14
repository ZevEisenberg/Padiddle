//
//  Log.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 3/5/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import Foundation

struct Log {

    static let isDebugging: Bool = {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }()

    private static func log(_ object: Any?, title: String, _ fileName: String, _ functionName: String, _ line: Int) {
        let objectName = URL(fileURLWithPath: fileName).lastPathComponent

        var objectDebugDescription: String = ""
        if object != nil {
            debugPrint(object!, to: &objectDebugDescription)
        }

        let preambleString = title + objectName + ": " + functionName + "(\(line))"
        if isDebugging {
            print(preambleString)
            if object != nil {
                print(objectDebugDescription)
            }
        }
        else {
            print(preambleString)
            if object != nil {
                print(objectDebugDescription)
            }
        }
    }

    static func error(_ object: Any? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object, title: "ERROR-> ", fileName, functionName, line)
    }

    static func warning(_ object: Any? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object, title: "WARNING-> ", fileName, functionName, line)
    }

    static func info(_ object: Any? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        log(object, title: "Info-> ", fileName, functionName, line)
    }

    static func debug(_ object: Any? = nil, _ fileName: String = #file, _ functionName: String = #function, _ line: Int = #line) {
        if isDebugging {
            log(object, title: "Debug-> ", fileName, functionName, line)
        }
    }

}
