//
//  Models.swift
//  Application
//
//  Created by Andrew Lees on 30/04/2018.
//

import Foundation

struct Donation: Codable {
    let username: String
    let team: String
    var amount: Double
}

struct Donator {
    let username: String
    var donations = [String: Double]()
}

let teams: [String] = ["Ada Lovelace","Grace Hopper", "Marie Curie", "Rosalind Franklin", "Katherine Johnson",  "Mae Jemison"]

let userCap: Double = 1000
let unlimitedUser: String = "thinkit"
