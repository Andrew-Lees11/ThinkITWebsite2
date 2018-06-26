//
//  Models.swift
//  Application
//
//  Created by Andrew Lees on 30/04/2018.
//

import Foundation
import KituraContracts

struct Donation: Codable {
    let username: String
    let team: String
    var amount: Double
}

struct DonationMessage: Codable {
    let message: String
    init(donation: Donation) {
        self.message = "Success!! Saved donation of \(donation.amount) from \(donation.username) for team \(donation.team)"
    }
    init(message: String) {
        self.message = message
    }
}

struct Donator {
    let username: String
    var donations = [String: Double]()
}

struct ToggleQuery: QueryParams, Codable {
    let token: String
    let hide: Bool
}

let teams: [String] = ["Ada Lovelace", "Elizabeth Blackwell", "Grace Hopper", "Jane Goodall", "Katherine Johnson", "Mae Jemison", "Marie Curie", "Rosalind Franklin"]

let userCap: Double = 1000
let unlimitedUser: String? = ProcessInfo.processInfo.environment["unlimitedUser"]
var hideScores: Bool = false

