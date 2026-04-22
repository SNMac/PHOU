//
//  PhotoAuthStatus.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

enum PhotoAuthStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
}
