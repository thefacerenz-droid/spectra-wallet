import SwiftUI

// Reference-inspired presentation. All prices/charts/events remain offline examples.
private let upColor = Color(red: 0.34, green: 0.90, blue: 0.30)

private struct MarketRow: View {
    let coin: Coin
    let select: () -> Void
    var body: some View {
        Button(action: select) {
            HStack(spacing: 12) {
                CoinMark(coin: coin, size: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(coin.id).font(.system(size: 18, weight: .semibold))
                    Text(coin.name).font(.system(size: 14)).foregroundColor(muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(money(coin.price)).font(.system(size: 16))
                    Text("0.00%").font(.system(size: 13)).foregroundColor(muted)
                }
            }.foregroundColor(.white).padding(.vertical, 11)
        }.buttonStyle(.plain)
    }
}

struct SearchResultsView: View {
    let query: String
    let select: (Coin) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(query.isEmpty ? "Trending" : "Search results").font(.system(size: 21, weight: .semibold))
            let matches = Coin.all.filter { query.isEmpty || $0.id.localizedCaseInsensitiveContains(query) || $0.name.localizedCaseInsensitiveContains(query) }
            if matches.isEmpty { Text("No results").foregroundColor(muted).padding(.vertical, 30) }
            ForEach(matches) { coin in MarketRow(coin: coin) { select(coin) } }
        }
    }
}

struct HomeWatchlistView: View {
    let select: (Coin) -> Void
    @AppStorage("spectra.watchlist.v1") private var watchlist = "SOL,BTC"
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watchlist ›").font(.system(size: 25, weight: .semibold))
            let coins = Coin.all.filter { watchlist.split(separator: ",").contains(Substring($0.id)) }
            if coins.isEmpty { Text("Add tokens from Watchlist in your profile menu.").font(.footnote).foregroundColor(muted) }
            ForEach(coins) { coin in MarketRow(coin: coin) { select(coin) } }
        }
    }
}

struct MarketsView: View {
    let select: (Coin) -> Void
    let buy: () -> Void
    @State private var filter = "Trending"
    @AppStorage("spectra.watchlist.v1") private var watchlist = "SOL,BTC"
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Hot Markets").font(.system(size: 25, weight: .semibold))
                    Spacer()
                    Button { filter = "Favorites" } label: { Image(systemName: "heart").frame(width: 40, height: 40).background(panel, in: Circle()) }
                }
                Text("Reference markets").font(.footnote).foregroundColor(muted)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Coin.all.prefix(3)) { coin in
                        Button { select(coin) } label: {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack(spacing: 10) {
                                    CoinMark(coin: coin, size: 32)
                                    VStack(alignment: .leading) { Text(coin.name).font(.headline); Text(money(coin.price)).font(.caption).foregroundColor(muted) }
                                    Spacer()
                                    Sparkline(values: [0.4,0.45,0.42,0.56,0.55,0.7,0.66,0.82], color: upColor).frame(width: 75, height: 35)
                                }
                                Divider()
                                Text("Offline price preview").font(.footnote).foregroundColor(muted)
                            }.padding(18).frame(width: 285).background(panel, in: RoundedRectangle(cornerRadius: 23))
                        }.buttonStyle(.plain)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 14) {
                Text("Explore Markets ›").font(.system(size: 25, weight: .semibold))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["Favorites", "Trending", "Perps"], id: \.self) { item in
                            Button { filter = item } label: {
                                Group {
                                    if item == "Favorites" { Image(systemName: "heart.fill") }
                                    else { Text(item) }
                                }.font(.system(size: 16, weight: .semibold)).padding(.horizontal, 15).frame(height: 40)
                                    .foregroundColor(filter == item ? .black : muted)
                                    .background(filter == item ? Color.white : panel, in: Capsule())
                            }.accessibilityLabel(item)
                        }
                    }
                }
                let rows = Coin.all.filter { coin in
                    filter == "Favorites" ? watchlist.split(separator: ",").contains(Substring(coin.id)) : filter == "Perps" ? coin.id != "USDC" : true
                }
                if rows.isEmpty { Text("No favorites yet").foregroundColor(muted).padding(.vertical, 20) }
                ForEach(rows) { coin in MarketRow(coin: coin) { select(coin) } }
                Button(action: buy) {
                    Text("Buy crypto").font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(17).background(lavender, in: Capsule())
                }
            }
        }
    }
}

private struct Sparkline: View {
    let values: [CGFloat]
    let color: Color
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard values.count > 1 else { return }
                for (index, value) in values.enumerated() {
                    let point = CGPoint(x: geometry.size.width * CGFloat(index) / CGFloat(values.count - 1), y: geometry.size.height * (1 - value))
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
            }.stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }.accessibilityLabel("Example chart, not live market data")
    }
}

struct PredictView: View {
    @State private var detail: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Predictions").font(.system(size: 25, weight: .semibold))
            Button { detail = "Sports preview" } label: {
                VStack(spacing: 18) {
                    HStack {
                        Image(systemName: "soccerball").font(.largeTitle).padding(12).background(.pink, in: RoundedRectangle(cornerRadius: 14))
                        Spacer(); Text("VS").font(.largeTitle.bold()); Spacer()
                        Image(systemName: "soccerball").font(.largeTitle).padding(12).background(.red, in: RoundedRectangle(cornerRadius: 14))
                    }
                    HStack { Text("HOME"); Spacer(); Text("Preview").foregroundColor(lavender); Spacer(); Text("AWAY") }.font(.subheadline.weight(.medium))
                    HStack(spacing: 4) { Capsule().fill(.pink); Capsule().fill(muted); Capsule().fill(.red) }.frame(height: 8)
                    HStack { Text("30%").frame(maxWidth: .infinity); Text("40%").frame(maxWidth: .infinity) }.font(.subheadline).padding(12).background(.white.opacity(0.03), in: Capsule())
                }.padding(20).background(panel, in: RoundedRectangle(cornerRadius: 27))
            }.buttonStyle(.plain)
            Text("Upcoming ›").font(.system(size: 25, weight: .semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    event("Miami vs Arizona", icon: "baseball.fill", color: .cyan)
                    event("Indianapolis vs Kansas City", icon: "football.fill", color: .pink)
                }
            }
            Text("Up or Down ›").font(.system(size: 25, weight: .semibold))
            Button { detail = "Up or Down" } label: {
                VStack(spacing: 20) {
                    HStack {
                        CoinMark(coin: Coin.all[2], size: 36)
                        VStack(alignment: .leading) { Text(money(Coin.all[2].price)).font(.headline); Text("Reference price").font(.caption).foregroundColor(muted) }
                        Spacer(); Text("05:00").font(.subheadline).foregroundColor(muted)
                    }
                    Sparkline(values: [0.85,0.80,0.82,0.74,0.66,0.64,0.53,0.47,0.46,0.32,0.25,0.1], color: .pink).frame(height: 160)
                    HStack { Text("↑ Up · 37%").foregroundColor(upColor); Spacer(); Text("↓ Down · 63%").foregroundColor(.pink) }.font(.caption)
                }.padding(20).background(panel, in: RoundedRectangle(cornerRadius: 25))
            }.buttonStyle(.plain)
            Text("5 Minute Markets").font(.system(size: 25, weight: .semibold))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Coin.all) { coin in
                    Button { detail = coin.name + " market" } label: {
                        VStack(alignment: .leading, spacing: 8) { CoinMark(coin: coin, size: 30); Text(coin.id).font(.headline); Text("5m").font(.caption).foregroundColor(muted) }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(18).background(panel, in: RoundedRectangle(cornerRadius: 22))
                    }.buttonStyle(.plain)
                }
            }
        }.sheet(isPresented: Binding(get: { detail != nil }, set: { if !$0 { detail = nil } })) {
            NavigationStack {
                ExplanationView(title: detail ?? "Market", icon: "chart.xyaxis.line", message: "This event view uses fixed example data. No live odds, wagers or payouts are available.")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { detail = nil } } }
            }.preferredColorScheme(.dark).tint(lavender)
        }
    }
    private func event(_ title: String, icon: String, color: Color) -> some View {
        Button { detail = title } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.title2).padding(12).background(color, in: RoundedRectangle(cornerRadius: 14))
                Text(title).font(.headline).lineLimit(1)
                Text("Preview").font(.footnote).foregroundColor(muted)
            }.frame(width: 165, alignment: .leading).padding(20).background(panel, in: RoundedRectangle(cornerRadius: 25))
        }.buttonStyle(.plain)
    }
}

struct DiscoverView: View {
    @State private var article: String?
    private let lessons = ["Solana 101", "Memecoins 101", "Prediction Markets"]
    private let summaries = ["A beginner's guide to Solana", "Memecoin starter guide", "How prediction markets work"]
    private let explanations = [
        "Solana is a blockchain with SOL as its native token. This app uses only a local SOL balance and fixed example prices; it does not connect to Solana.",
        "Memecoins are tokens associated with internet memes or communities. Popularity can change quickly. The assets displayed in Spectra are offline examples.",
        "Prediction markets use contracts linked to event outcomes. Spectra illustrates their layout with sample percentages and has no betting or settlement service."
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Explore").font(.system(size: 25, weight: .semibold))
            Text("Apps").font(.system(size: 25, weight: .semibold))
            VStack(spacing: 0) {
                discoverRow("Watchlist", subtitle: "Your saved tokens", icon: "heart", color: .purple) { article = "Watchlist" }
                discoverRow("Portfolio", subtitle: "Your local account", icon: "wallet.pass", color: .mint) { article = "Portfolio" }
                discoverRow("Networks", subtitle: "Offline token groups", icon: "network", color: .blue) { article = "Networks" }
            }.background(panel, in: RoundedRectangle(cornerRadius: 24))
            Text("Learn ›").font(.system(size: 25, weight: .semibold))
            VStack(spacing: 0) {
                ForEach(0..<lessons.count, id: \.self) { index in
                    discoverRow(lessons[index], subtitle: summaries[index], icon: index == 0 ? "graduationcap" : index == 1 ? "sparkles" : "chart.bar", color: lavender) { article = lessons[index] }
                }
            }.background(panel, in: RoundedRectangle(cornerRadius: 24))
            Text("Spectra is an independent roleplay app. Market lists, charts and prices are local examples, not live trading data.").font(.footnote).foregroundColor(muted)
        }.sheet(isPresented: Binding(get: { article != nil }, set: { if !$0 { article = nil } })) {
            NavigationStack {
                ExplanationView(title: article ?? "Learn", icon: "book", message: article.flatMap { title in lessons.firstIndex(of: title).map { explanations[$0] } } ?? "Open the profile menu for your saved tokens and local portfolio settings. This app does not connect to external dApps.")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { article = nil } } }
            }.preferredColorScheme(.dark).tint(lavender)
        }
    }
    private func discoverRow(_ title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title2).foregroundColor(color).frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 18, weight: .medium)); Text(subtitle).font(.system(size: 14)).foregroundColor(muted) }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(muted)
            }.foregroundColor(.white).padding(18)
        }
    }
}

struct ProfileView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @AppStorage("spectra.bio.v1") private var bio = ""
    @State private var closed = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                HStack { Spacer(); NavigationLink { ManageProfileView(wallet: $wallet, save: save) } label: { Text("Manage").font(.headline).padding(.horizontal, 17).padding(.vertical, 12).background(panel, in: Capsule()) } }
                Avatar(size: 76)
                Text("@" + wallet.name.replacingOccurrences(of: " ", with: "")).font(.system(size: 30, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.5)
                HStack(spacing: 18) { Text("0 Followers"); Text("$0.00 Vol") }.foregroundColor(muted).font(.subheadline)
                NavigationLink { ManageProfileView(wallet: $wallet, save: save) } label: { Text(bio.isEmpty ? "Add a bio" : bio).font(.subheadline) }
                Text(money(wallet.total)).font(.system(size: 36, weight: .semibold)).padding(.top, 15)
                Text("$0.00  24h").font(.subheadline).foregroundColor(muted)
                HStack(spacing: 8) {
                    positionTab("Open", active: !closed) { closed = false }
                    positionTab("Closed", active: closed) { closed = true }
                }.padding(.top, 10)
                Text(closed ? "No closed positions" : "No open positions").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 65)
            }.padding(22)
        }.background(canvas).navigationBarTitleDisplayMode(.inline)
    }
    private func positionTab(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).font(.headline).padding(.horizontal, 16).padding(.vertical, 11).foregroundColor(active ? .black : muted).background(active ? Color.white : panel, in: Capsule()) }
    }
}

private struct ManageProfileView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @AppStorage("spectra.bio.v1") private var bio = ""
    var body: some View {
        Form {
            Section { HStack { Spacer(); Avatar(size: 110); Spacer() }.padding(.vertical, 20).listRowBackground(canvas) }
            Section("About") {
                HStack { Text("Username"); Spacer(); TextField("Account name", text: $wallet.name).multilineTextAlignment(.trailing).onChange(of: wallet.name) { value in wallet.name = String(value.prefix(30)); save() } }
                TextField("Bio", text: $bio, axis: .vertical).lineLimit(1...4).onChange(of: bio) { value in bio = String(value.prefix(180)) }
                NavigationLink("Connect your X account") { ExplanationView(title: "X account", icon: "link", message: "Social linking is unavailable in this offline app.") }
                NavigationLink("Connect your TikTok account") { ExplanationView(title: "TikTok account", icon: "link", message: "Social linking is unavailable in this offline app.") }
            }.listRowBackground(groupPanel)
            Section("Manage") {
                LabeledContent("Followers", value: "0")
                LabeledContent("Privacy", value: "On this device")
                NavigationLink("Verify my profile") { ExplanationView(title: "Verification", icon: "person.crop.circle.badge.checkmark", message: "Spectra has no public profiles or verified accounts. Your profile exists only on this phone.") }
            }.listRowBackground(groupPanel)
        }.scrollContentBackground(.hidden).background(canvas).navigationTitle("Manage Profile").navigationBarTitleDisplayMode(.inline)
    }
}

struct PreferencesView: View {
    @AppStorage("spectra.motion.v1") private var fullMotion = true
    var body: some View {
        Form {
            Section {
                LabeledContent("Display Language", value: "English")
                LabeledContent("Currency", value: "United States Dollar")
            }.listRowBackground(groupPanel)
            Section {
                NavigationLink("Notifications") { ExplanationView(title: "Notifications", icon: "bell", message: "Spectra sends no notifications.") }
                LabeledContent("Preferred Explorer", value: "None")
                LabeledContent("App Icon", value: "Spectra")
                Toggle("Full motion", isOn: $fullMotion)
            }.listRowBackground(groupPanel)
        }.scrollContentBackground(.hidden).background(canvas).navigationTitle("Preferences").navigationBarTitleDisplayMode(.inline)
    }
}

struct NetworksView: View {
    @AppStorage("spectra.networks.v1") private var selected = "Solana,Ethereum,Bitcoin,Base"
    private let networks = ["Solana", "Ethereum", "Bitcoin", "Base", "Sui", "Polygon", "HyperEVM"]
    var body: some View {
        List {
            ForEach(networks, id: \.self) { network in
                Toggle(network, isOn: Binding(get: { selected.split(separator: ",").contains(Substring(network)) }, set: { enabled in
                    var values = Set(selected.split(separator: ",").map(String.init))
                    if enabled { values.insert(network) } else { values.remove(network) }
                    selected = values.sorted().joined(separator: ",")
                })).listRowBackground(groupPanel)
            }
            Text("These preferences are saved locally. They do not enable blockchain connections or change the portfolio's reference prices.").font(.footnote).foregroundColor(muted).listRowBackground(canvas)
        }.scrollContentBackground(.hidden).background(canvas).navigationTitle("Active Networks").navigationBarTitleDisplayMode(.inline)
    }
}

struct ConnectedAppsView: View {
    var body: some View {
        VStack { Spacer(); Text("No trusted apps").foregroundColor(muted); Spacer() }
            .frame(maxWidth: .infinity).background(canvas).navigationTitle("Connected Apps").navigationBarTitleDisplayMode(.inline)
    }
}

private struct SavedAccount: Identifiable, Codable {
    var id: String
    var wallet: WalletData
}

struct AccountsView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @AppStorage("spectra.activeAccount.v1") private var active = "primary"
    @State private var accounts: [SavedAccount] = []
    @State private var add = false
    @State private var newName = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(accounts) { account in
                    Button {
                        persistCurrent()
                        guard let latest = accounts.first(where: { $0.id == account.id }) else { return }
                        wallet = latest.wallet; active = account.id; save(); dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack(alignment: .bottomTrailing) {
                                Text("A" + String((accounts.firstIndex(where: { $0.id == account.id }) ?? 0) + 1)).foregroundColor(muted).font(.headline).frame(width: 42, height: 42).background(groupPanel, in: Circle())
                                if active == account.id { Image(systemName: "checkmark.circle.fill").foregroundColor(lavender).font(.caption) }
                            }
                            VStack(alignment: .leading, spacing: 5) { Text(account.wallet.name).font(.headline); Text(money(account.wallet.total)).font(.subheadline) }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(muted)
                        }.foregroundColor(.white).padding(18).background(panel, in: RoundedRectangle(cornerRadius: 23))
                    }.buttonStyle(.plain)
                }
                NavigationLink("Edit current account") { AccountEditorView(wallet: $wallet, save: save) }
            }.padding(20)
        }.background(canvas).navigationTitle("Your Accounts").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .primaryAction) { Button { add = true } label: { Image(systemName: "plus") } } }
            .onAppear {
                if let data = UserDefaults.standard.data(forKey: "spectra.accounts.v1"), let loaded = try? JSONDecoder().decode([SavedAccount].self, from: data) { accounts = loaded }
                persistCurrent()
            }
            .alert("Create local account", isPresented: $add) {
                TextField("Account name", text: $newName)
                Button("Create") {
                    persistCurrent()
                    var next = WalletData()
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    next.name = trimmed.isEmpty ? "Account \(accounts.count + 1)" : String(trimmed.prefix(30))
                    let id = UUID().uuidString
                    accounts.append(SavedAccount(id: id, wallet: next))
                    wallet = next; active = id; save(); persistCurrent(); newName = ""
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Each local account has separate balances and history. No recovery phrase is created.") }
    }
    private func persistCurrent() {
        if let index = accounts.firstIndex(where: { $0.id == active }) { accounts[index].wallet = wallet }
        else { accounts.append(SavedAccount(id: active, wallet: wallet)) }
        if let data = try? JSONEncoder().encode(accounts) { UserDefaults.standard.set(data, forKey: "spectra.accounts.v1") }
    }
}

struct SecurityView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @AppStorage("spectra.shortcuts.v1") private var shortcuts = true
    @State private var reset = false
    var body: some View {
        Form {
            Section {
                Toggle("Use Face ID Authentication", isOn: .constant(false)).disabled(true)
            } footer: { Text("Biometric locking is not implemented in this version.") }
                .listRowBackground(groupPanel)
            Section {
                NavigationLink("Blocked Accounts") { ExplanationView(title: "Blocked Accounts", icon: "person.slash", message: "No blocked accounts. Spectra has no messaging network.") }
            }.listRowBackground(groupPanel)
            Section {
                ShareLink(item: "Spectra 1.4 diagnostics: offline mode; network services disabled; saved activity count: \(wallet.entries.count).") {
                    Text("Download App Logs")
                }
            }.listRowBackground(groupPanel)
            Section { Toggle("Show Wallet Shortcuts", isOn: $shortcuts) }.listRowBackground(groupPanel)
            Section {
                Toggle("Share Anonymous Analytics", isOn: .constant(false)).disabled(true)
            } footer: { Text("Spectra collects no analytics.") }.listRowBackground(groupPanel)
            Section {
                NavigationLink("Show Recovery Phrase") { ExplanationView(title: "Recovery Phrase", icon: "key", message: "There is no recovery phrase. Spectra does not create keys or blockchain wallets.") }
            }.listRowBackground(groupPanel)
            Section {
                Button("Reset Current Account", role: .destructive) { reset = true }
            }.listRowBackground(groupPanel)
        }.scrollContentBackground(.hidden).background(canvas).navigationTitle("Security & Privacy").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Clear this account's balances and history?", isPresented: $reset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { wallet.balances = [:]; wallet.cash = nil; wallet.entries = []; save() }
                Button("Cancel", role: .cancel) {}
            }
    }
}
