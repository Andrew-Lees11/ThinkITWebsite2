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

}
class Persistence {
    static func setUp() {
        // If running locally use your own database url here
        if let databaseURL = ProcessInfo.processInfo.environment["databaseURL"], let url = URL(string: databaseURL) {
            let pool = PostgreSQLConnection.createPool(url: url, poolOptions: ConnectionPoolOptions(initialCapacity: 1, maxCapacity: 4, timeout: 10000))
            Database.default = Database(pool)
        } else {
            print("Couldn't get databaseURL envar. creating local database")
            let pool = PostgreSQLConnection.createPool(host: "localhost", port: 5432, options: [.databaseName("school")], poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))
            Database.default = Database(pool)
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
        let sfsOptions = StaticFileServer.Options(possibleExtensions: ["html"])
        router.get("/teams", middleware: StaticFileServer(options: sfsOptions))
        router.all("/", middleware: StaticFileServer(path: "./public", options: sfsOptions))
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
            var teamScores = [String: Double]()
            Donation.findAll { donations, error in
                guard let donations = donations else {
                    return next()
                }
                for donation in donations {
                    teamScores[donation.team] = donation.amount + (teamScores[donation.team] ?? 0)
                }
                var context: [String: [[String:Any]]] = ["donations" :[]]
                for team in teams {
                    context["donations"]?.append(["team": team, "amount": String(teamScores[team] ?? 0)])
                }
                print("scores context: \(context)")
                do {
                    try response.render("scores.stencil", context: context)
                } catch {
                    print("failed to render stencil")
                }
                next()
            }
        }
        router.get("/alldonations") { request, response, next in
            Donation.findAll { donations, error in
                guard let donations = donations else {
                    return next()
                }
                var context: [String: [[String:Any]]] = ["donations": []]
                for donation in donations {
                    context["donations"]?.append(["team": donation.team, "user": donation.username, "amount": donation.amount])
                }
                do {
                    try response.render("alldonations.stencil", context: context)
                } catch {
                    print("failed to render alldonations stencil")
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
            print("request query parameters: \(request.queryParameters)")
            guard let donatorName = request.queryParameters["donator"]?.lowercased() else {
                try response.render("seeDonations.stencil", context: [:]).end()
                return
            }
            let requestDonator = "tweets/\(donatorName)"
            var donator = Donator(username: requestDonator, donations: [:])
            Donation.findAll { donations, error in
                guard let donations = donations else {
                    return next()
                }
                print("donations: \(donations)")
                for donation in donations {
                    if donation.username.lowercased() == requestDonator {
                        donator.donations[donation.team] = donation.amount + (donator.donations[donation.team] ?? 0)
                    }
                }
                print("donator.donations[donation.team]: \(donator.donations)")
                print("requestDonator: \(requestDonator)")
                var context: [String:Any] = ["donator": requestDonator]
                print("context: \(context)")
                var tempTeams: [[String:Any]] = []
                for (index, team) in teams.enumerated() {
                    tempTeams.append(["team": team, "amount": donator.donations[team] ?? 0, "index": index])
                }
                context["teams"] = tempTeams
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
        print("recieved donation: \(donation)")
        Donation.findAll() { allDonations, error in
            let existingUser = allDonations?.filter({$0.username == donation.username})
            let totalDonations = existingUser?.map({ $0.amount }).reduce(0, +) ?? 0
            if donation.username == unlimitedUser || totalDonations + donation.amount <= userCap {
                print("saved full donation: \(donation)")
                donation.save(completion)
            } else if totalDonations < userCap {
                let adjustedDonation = Donation(username: donation.username, team: donation.team, amount: userCap - totalDonations)
                print("saved partial donation: \(adjustedDonation)")
                adjustedDonation.save(completion)
            } else {
                print("Donator out of money: \(donation)")
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
