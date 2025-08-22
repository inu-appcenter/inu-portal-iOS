//
//  TokenInfo.swift
//  INTIP
//
//  Created by 이대현 on 1/30/25.
//

import Foundation

struct TokenInfo: Codable {
    let accessToken: String
    let accessTokenExpiredTime: String
    let refreshToken: String
    let refreshTokenExpiredTime: String
}
