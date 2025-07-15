//
//  PermissionState.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation

enum PermissionState {
    case notDetermined
    case granted
    case denied
    
    var hasAccess: Bool {
        self == .granted
    }
}