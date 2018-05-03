import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import SwiftKueryORM
import SwiftKueryPostgreSQL
import KituraStencil

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()
extension Donation: Model {
    static var idColumnName = "user"
}
class Persistence {
    static func setUp() {
        // If running locally use your own database url here
        if let databaseURL = ProcessInfo.processInfo.environment["databaseURL"], let url = URL(string: databaseURL) {
            let pool = PostgreSQLConnection.createPool(url: url, poolOptions: ConnectionPoolOptions(initialCapacity: 1, maxCapacity: 4, timeout: 10000))
            Database.default = Database(pool)
        } else {
            print("failed to get databaseURL")
        }
    }
}
public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Middleware
        router.get("/teams", middleware: StaticFileServer())
        router.add(templateEngine: StencilTemplateEngine())
        // Endpoints
        initializeHealthRoutes(app: self)
        Persistence.setUp()
        do {
            try Donation.createTableSync()
        } catch let error {
            print(error)
        }
        router.post("/input", handler: donationHandler)        
        router.get("/scores") { request, response, next in
            var context: [String: Any] = ["donations": []]
            var teamScores = [String: Double]()
            Donation.findAll { donations, error in
                guard let donations = donations else {
                    return next()
                }
                for donation in donations {
                    teamScores[donation.team] = donation.amount + (teamScores[donation.team] ?? 0)
                }
                context["donations"] = teamScores
                print("scores context: \(context)")
                do {
                    try response.render("scores.stencil", context: context)
                } catch {
                    print("failed to render stencil")
                }
                next()
            }
        }
        
        router.get("/") { request, response, next in
            let context: [String: Any] = ["teams": teams]
            print("teams context: \(context)")
            try response.render("teams.stencil", context: context)
            next()
        }
        
        router.get("/donators") { request, response, next in
            guard let requestDonator = request.queryParameters["donator"] else {
                try response.render("seeDonations.stencil", context: [:]).end()
                return
            }
            var context: [String: Any] = ["Donator": []]
            var donator = Donator(user: requestDonator, donations: [:])
            Donation.findAll { donations, error in
                guard let donations = donations else {
                    return next()
                }
                for donation in donations {
                    if donation.user == requestDonator {
                        donator.donations[donation.team] = donation.amount + (donator.donations[donation.team] ?? 0)
                    }
                }
                context["Donator"] = donator
                print("donator context: \(context)")
                do {
                    try response.render("donator.stencil", context: context)
                } catch {
                    print("failed to render stencil")
                }
                next()
            }
        }
        
    }
    
    func donationHandler(donation: Donation, completion: @escaping (Donation?, RequestError?) -> Void) {
        Donation.findAll() { allDonations, error in
            let existingUser = allDonations?.filter({$0.user == donation.user})
            let totalDonations = existingUser?.map({ $0.amount }).reduce(0, +) ?? 0
            if donation.user == unlimitedUser || totalDonations + donation.amount <= userCap {
                donation.save(completion)
            } else if totalDonations <= userCap {
                let adjustedDonation = Donation(user: donation.user, team: donation.team, amount: userCap - totalDonations)
                adjustedDonation.save(completion)
            } else {
                completion(nil, .notAcceptable)
            }
        }
    }
    
    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
    
}
