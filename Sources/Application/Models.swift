//
//  Models.swift
//  Application
//
//  Created by Andrew Lees on 30/04/2018.
//

import Foundation

struct Donation: Codable {
    let user: String
    let team: String
    var amount: Double
}

struct Donator {
    let user: String
    var donations = [String: Double]()
}

let teams: [String] = ["team1","team2", "team3", "team4", "team5",  "team6"]

let userCap: Double = 1000
let unlimitedUser: String = "thinkit"
