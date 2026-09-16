import Foundation

struct Coin: Identifiable {
    let id: String
    let name: String
    let glyph: String
    let price: Double
    static let all: [Coin] = [
        Coin(id: "SOL", name: "Solana", glyph: "≋", price: 150),
        Coin(id: "ETH", name: "Ethereum", glyph: "◆", price: 3000),
        Coin(id: "BTC", name: "Bitcoin", glyph: "₿", price: 60000),
        Coin(id: "USDC", name: "USD Coin", glyph: "$", price: 1)
    ]
}

struct Entry: Identifiable, Codable {
    var id = UUID()
    let coin: String
    let units: Double
    let date: Date
}

struct WalletData: Codable {
    var name = "Account 1"
    var balances: [String: Double] = [:]
    var entries: [Entry] = []
    var total: Double { Coin.all.reduce(0) { $0 + ($1.price * (balances[$1.id] ?? 0)) } }

    mutating func add(coin: String, units: Double) -> Bool {
        guard Coin.all.contains(where: { $0.id == coin }), units.isFinite, units > 0,
              let price = Coin.all.first(where: { $0.id == coin })?.price,
              total + units * price <= 1_000_000_000 else { return false }
        balances[coin, default: 0] += units
        entries.insert(Entry(coin: coin, units: units, date: Date()), at: 0)
        entries = Array(entries.prefix(100))
        return true
    }

    static func restored(_ data: Data?) -> WalletData {
        guard let data = data, let value = try? JSONDecoder().decode(WalletData.self, from: data),
              value.balances.allSatisfy({ key, amount in
                  Coin.all.contains(where: { $0.id == key }) && amount.isFinite && amount >= 0
              }), value.total <= 1_000_000_000 else { return WalletData() }
        return value
    }
}

func money(_ value: Double) -> String {
    value.formatted(.currency(code: "USD"))
}
