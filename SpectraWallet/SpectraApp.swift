import SwiftUI
import UIKit

let canvas = Color.black
let panel = Color(white: 0.075)
let groupPanel = Color(white: 0.115)
let lavender = Color(red: 0.70, green: 0.62, blue: 0.98)
let muted = Color(white: 0.61)

@main
struct SpectraApp: App {
    var body: some Scene {
        WindowGroup { WalletView().preferredColorScheme(.dark).tint(lavender) }
    }
}

private enum Screen: String, CaseIterable {
    case home = "Home", trade = "Trade", predict = "Predict", explore = "Explore"
}
private enum Modal: String, Identifiable {
    case settings, profile, accounts, history, watchlist, chats, help, addFunds, send, receive, addCash, buy
    var id: String { rawValue }
}

struct WalletView: View {
    @State private var wallet = WalletData.restored(UserDefaults.standard.data(forKey: "spectra.wallet.v1"))
    @State private var drawer = false
    @State private var quickActions = false
    @State private var copiedHandle = false
    @State private var showSearch = false
    @AppStorage("spectra.motion.v1") private var fullMotion = true
    @AppStorage("spectra.shortcuts.v1") private var showShortcuts = true
    @Namespace private var tabAnimation
    @FocusState private var searchFocused: Bool
    @State private var screen: Screen = .home
    @State private var modal: Modal?
    @State private var selectedCoin: Coin?
    @State private var query = ""
    @State private var info: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func save() {
        if let data = try? JSONEncoder().encode(wallet) {
            UserDefaults.standard.set(data, forKey: "spectra.wallet.v1")
        }
    }
    private func toggleDrawer(_ show: Bool) {
        withAnimation((reduceMotion || !fullMotion) ? nil : .spring(response: 0.35, dampingFraction: 0.88)) { drawer = show }
    }
    private func toggleActions(_ show: Bool) {
        searchFocused = false
        withAnimation((reduceMotion || !fullMotion) ? nil : .spring(response: 0.32, dampingFraction: 0.88)) { quickActions = show }
    }
    private func open(_ destination: Modal) {
        toggleDrawer(false)
        toggleActions(false)
        modal = destination
    }

    var body: some View {
        GeometryReader { geometry in
            let drawerWidth = min(geometry.size.width * 0.78, 360)
            ZStack(alignment: .leading) {
                canvas.ignoresSafeArea()
                drawerView.frame(width: drawerWidth)
                    .accessibilityHidden(!drawer)
                mainView
                    .background(canvas)
                    .blur(radius: quickActions ? 15 : 0)
                    .allowsHitTesting(!quickActions)
                    .clipShape(RoundedRectangle(cornerRadius: drawer ? 40 : 0))
                    .overlay {
                        if drawer {
                            Color.black.opacity(0.63)
                                .contentShape(Rectangle())
                                .onTapGesture { toggleDrawer(false) }
                                .accessibilityLabel("Close profile menu")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                    .offset(x: drawer ? drawerWidth : 0)
                    .accessibilityHidden(drawer || quickActions)
                if quickActions { actionsOverlay.transition(.opacity).zIndex(2) }
            }
            .clipped()
            .gesture(DragGesture(minimumDistance: 35).onEnded { value in
                guard !quickActions else { return }
                if drawer && value.translation.width < -55 { toggleDrawer(false) }
                else if !drawer && value.startLocation.x < 24 && value.translation.width > 65 { toggleDrawer(true) }
            })
        }
        .background(canvas.ignoresSafeArea())
        .sheet(item: $modal, onDismiss: save) { destination in
            NavigationStack {
                modalContent(destination)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { save(); modal = nil }
                        }
                    }
            }.preferredColorScheme(.dark).tint(lavender).presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedCoin) { coin in
            NavigationStack {
                CoinDetail(coin: coin, units: wallet.balances[coin.id] ?? 0)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { selectedCoin = nil } } }
            }.preferredColorScheme(.dark).tint(lavender).presentationDragIndicator(.visible)
        }
        .alert("Spectra", isPresented: Binding(get: { info != nil }, set: { if !$0 { info = nil } })) {
            Button("OK", role: .cancel) { info = nil }
        } message: { Text(info ?? "") }
    }

    private var actionsOverlay: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black.opacity(0.36).ignoresSafeArea()
                .contentShape(Rectangle()).onTapGesture { toggleActions(false) }
                .accessibilityLabel("Close actions").accessibilityAddTraits(.isButton)
            VStack(alignment: .trailing, spacing: 23) {
                quickAction("Send", icon: "paperplane", destination: .send)
                quickAction("Receive", icon: "qrcode", destination: .receive)
                quickAction("Add Cash", icon: "dollarsign.circle", destination: .addCash)
                quickAction("Trade", icon: "shuffle", destination: .buy)
                Button { toggleActions(false) } label: {
                    Image(systemName: "xmark").font(.system(size: 24, weight: .medium)).foregroundColor(.white)
                        .frame(width: 50, height: 50).background(panel.opacity(0.8), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.04)))
                }.accessibilityLabel("Close actions")
            }.padding(.trailing, 20).padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }.accessibilityAddTraits(.isModal)
    }

    private func quickAction(_ title: String, icon: String, destination: Modal) -> some View {
        Button { open(destination) } label: {
            HStack(spacing: 16) {
                Text(title).font(.system(size: 25, weight: .semibold)).foregroundColor(.white)
                Image(systemName: icon).font(.system(size: 26, weight: .medium)).foregroundColor(.black)
                    .frame(width: 50, height: 50).background(lavender, in: Circle())
            }
        }
    }

    private var tradeOverview: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { Text("Trade").font(.largeTitle.bold()); Spacer(); brandBadge }
            Button { open(.buy) } label: {
                Label("Buy crypto", systemImage: "plus.circle.fill").font(.headline)
                    .foregroundColor(.black).frame(maxWidth: .infinity).padding(18)
                    .background(lavender, in: RoundedRectangle(cornerRadius: 18))
            }
            Text("Cash available: " + money(wallet.cashBalance)).foregroundColor(muted)
            assetList(title: "Tokens", subtitle: "Browse tokens")
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                Button { toggleDrawer(true) } label: { Avatar(size: 42) }.accessibilityLabel("Open profile menu")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Screen.allCases, id: \.self) { item in
                            Button {
                                withAnimation((reduceMotion || !fullMotion) ? nil : .easeInOut(duration: 0.2)) { screen = item; query = ""; showSearch = false }
                            } label: {
                                Text(item.rawValue).font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(screen == item ? .black : muted)
                                    .padding(.horizontal, 19).frame(height: 42)
                                    .background {
                                        if screen == item { Capsule().fill(lavender).matchedGeometryEffect(id: "activeTab", in: tabAnimation) }
                                        else { Capsule().fill(panel) }
                                    }
                                    .overlay(Capsule().strokeBorder(.white.opacity(0.035)))
                            }.accessibilityAddTraits(screen == item ? .isSelected : [])
                        }
                    }
                }
            }.padding(.leading, 20).padding(.top, 14).padding(.bottom, 20)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    if showSearch {
                        SearchResultsView(query: query, select: { selectedCoin = $0 })
                    } else {
                        switch screen {
                        case .home: home
                        case .trade: MarketsView(select: { selectedCoin = $0 }, buy: { open(.buy) })
                        case .predict: PredictView()
                        case .explore: DiscoverView()
                        }
                    }
                }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)
            }
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").font(.system(size: 22)).foregroundColor(muted)
                    TextField("Search Spectra", text: $query)
                        .font(.system(size: 18)).submitLabel(.search).autocorrectionDisabled().focused($searchFocused)
                        .onChange(of: searchFocused) { focused in if focused { withAnimation(.easeOut(duration: 0.2)) { showSearch = true } } }
                    if showSearch {
                        Button { query = ""; searchFocused = false; showSearch = false } label: { Image(systemName: "xmark.circle.fill").foregroundColor(muted) }
                            .accessibilityLabel("Close search")
                    }
                }.padding(.horizontal, 16).frame(height: 50).background(panel, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.07)))
                if showShortcuts {
                    Button { toggleActions(true) } label: {
                        Image(systemName: "plus").font(.system(size: 29, weight: .regular)).foregroundColor(.black)
                            .frame(width: 50, height: 50).background(lavender, in: Circle())
                    }.accessibilityLabel("Open actions")
                }
            }.padding(.horizontal, 20).padding(.vertical, 10).background(.ultraThinMaterial)
        }
    }

    private var home: some View {
        Group {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Button { open(.accounts) } label: {
                        HStack(spacing: 5) { Text(wallet.name); Image(systemName: "chevron.down").font(.caption) }
                            .font(.system(size: 18, weight: .medium)).foregroundColor(muted)
                    }
                    Spacer()
                    brandBadge
                }
                Text(money(wallet.total)).font(.system(size: 60, weight: .semibold))
                    .tracking(-2).lineLimit(1).minimumScaleFactor(0.4)
                HStack(spacing: 10) {
                    Text("$0.00").foregroundColor(muted)
                    Text("0.00%").foregroundColor(.black).padding(.horizontal, 7).padding(.vertical, 3)
                        .background(muted, in: RoundedRectangle(cornerRadius: 7))
                }.font(.system(size: 19, weight: .semibold))
                Text("SPECTRA · USD")
                    .font(.system(size: 9, weight: .medium)).tracking(1.1).foregroundColor(muted)
            }.padding(.top, 4)
            Button { open(.addCash) } label: {
                HStack(spacing: 17) {
                    Image(systemName: "banknote.fill").font(.system(size: 25)).foregroundColor(muted)
                    Text("Cash").font(.system(size: 21, weight: .semibold))
                    Spacer()
                    Text(money(wallet.cashBalance)).font(.system(size: 20))
                }.foregroundColor(.white).padding(.horizontal, 24).frame(height: 76)
                    .background(panel, in: RoundedRectangle(cornerRadius: 25))
                    .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(.white.opacity(0.045)))
            }.buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 16) {
                heading("Tokens") { screen = .explore }
                let visible = Coin.all.filter { (wallet.balances[$0.id] ?? 0) > 0 }
                ForEach(visible.isEmpty ? [Coin.all[0]] : visible) { coin in
                    Button { selectedCoin = coin } label: { TokenRow(coin: coin, units: wallet.balances[coin.id] ?? 0) }
                        .buttonStyle(.plain)
                }
            }
            VStack(alignment: .leading, spacing: 16) {
                heading("Perps") { screen = .trade }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        marketCard(Coin.all[2], leverage: "40x", change: "−2.23%")
                        marketCard(Coin.all[1], leverage: "25x", change: "−3.54%")
                        marketCard(Coin.all[0], leverage: "20x", change: "+1.21%")
                    }
                }
            }
            predictions
            HomeWatchlistView(select: { selectedCoin = $0 })
            VStack(alignment: .leading, spacing: 15) {
                Text("Support").font(.system(size: 25, weight: .semibold))
                Button("View FAQ ›") { open(.help) }.foregroundColor(.white)
                Button("Chat with us ›") { open(.chats) }.foregroundColor(.white)
                Button("View Disclosures") { info = "Spectra is an independent offline roleplay wallet. Prices, charts and event cards use fixed example data. It cannot buy, receive or send real crypto." }.font(.caption).foregroundColor(muted)
            }
        }
    }

    private func heading(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) { Text(title).font(.system(size: 25, weight: .semibold)); Image(systemName: "chevron.right").font(.system(size: 16, weight: .medium)).foregroundColor(muted) }
                .foregroundColor(.white)
        }
    }

    private func marketCard(_ coin: Coin, leverage: String, change: String) -> some View {
        Button { selectedCoin = coin } label: {
            VStack(alignment: .leading, spacing: 10) {
                CoinMark(coin: coin, size: 49)
                HStack(spacing: 6) {
                    Text(coin.id).font(.system(size: 19, weight: .semibold))
                    Text(leverage).font(.system(size: 13, weight: .medium)).padding(.horizontal, 6).padding(.vertical, 3).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 4))
                }
                Text(change).font(.system(size: 19)).foregroundColor(change.hasPrefix("+") ? .mint : .pink)
                Text("Not live").font(.system(size: 10)).foregroundColor(muted)
            }.frame(width: 119, alignment: .leading).padding(20).background(panel, in: RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white.opacity(0.045)))
        }.buttonStyle(.plain)
    }

    private var predictions: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Predictions") { screen = .predict }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    predictionCard("Miami vs Arizona", icon: "baseball.fill", color: .cyan)
                    predictionCard("Madrid vs Barcelona", icon: "soccerball", color: .orange)
                }
            }
        }
    }

    private func predictionCard(_ title: String, icon: String, color: Color) -> some View {
        Button { info = "This is a sample event card for the interface. No live event, wagering, or payouts are available." } label: {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: icon).font(.system(size: 29)).foregroundColor(.white)
                        .frame(width: 48, height: 48).background(color, in: RoundedRectangle(cornerRadius: 13))
                    Spacer()
                    Text("Preview").font(.caption.weight(.medium)).foregroundColor(lavender)
                }
                Text(title).font(.system(size: 18, weight: .semibold)).lineLimit(1)
                Text("Event preview").font(.caption).foregroundColor(muted)
            }.frame(width: 190, alignment: .leading).padding(18).background(panel, in: RoundedRectangle(cornerRadius: 25))
                .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(.white.opacity(0.045)))
        }.buttonStyle(.plain)
    }

    private func assetList(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text(title).font(.largeTitle.bold()); Spacer(); brandBadge }
            Text(subtitle).font(.footnote).foregroundColor(muted)
            let matches = Coin.all.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.id.localizedCaseInsensitiveContains(query) }
            if matches.isEmpty { Text("No tokens found").foregroundColor(muted).padding(.vertical, 30) }
            ForEach(matches) { coin in
                Button { selectedCoin = coin } label: { TokenRow(coin: coin, units: wallet.balances[coin.id] ?? 0) }.buttonStyle(.plain)
            }
        }
    }

    private var drawerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Avatar(size: 52)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = "@" + wallet.name.replacingOccurrences(of: " ", with: "")
                            copiedHandle = true
                        } label: {
                            Image(systemName: copiedHandle ? "checkmark" : "square.on.square").foregroundColor(muted).frame(width: 40, height: 40).background(panel, in: Circle())
                        }.accessibilityLabel(copiedHandle ? "Username copied" : "Copy username")
                    }
                    Text("@" + wallet.name.replacingOccurrences(of: " ", with: ""))
                        .font(.system(size: 30, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.5)
                    Button { info = "Social account linking is not available in Spectra." } label: {
                        HStack(spacing: 10) { Text("𝕏").font(.title2); Text("Connect your X account").font(.system(size: 16, weight: .semibold)) }
                            .foregroundColor(lavender.opacity(0.7))
                    }.padding(.bottom, 12)
                    Button { open(.accounts) } label: {
                        HStack(spacing: 17) {
                            Text("A1").font(.system(size: 14, weight: .medium)).frame(width: 26, height: 26).background(panel, in: Circle())
                            Text(wallet.name).font(.system(size: 21, weight: .semibold)).lineLimit(1)
                            Image(systemName: "chevron.down").font(.system(size: 15))
                        }.foregroundColor(.white).frame(minHeight: 42)
                    }
                    menuRow("Profile", icon: "person") { open(.profile) }
                    menuRow("Chats", icon: "bubble.left") { open(.chats) }
                    menuRow("Watchlist", icon: "heart") { open(.watchlist) }
                    menuRow("History", icon: "clock") { open(.history) }
                }
            }
            VStack(spacing: 18) {
                menuRow("Settings", icon: "gearshape") { open(.settings) }
                menuRow("Help & Support", icon: "info.circle") { open(.help) }
            }.padding(.top, 20).padding(.bottom, 28)
        }.padding(.horizontal, 24).padding(.top, 24).background(canvas)
    }

    private func menuRow(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: icon).font(.system(size: 24)).frame(width: 25)
                Text(title).font(.system(size: 21, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }.foregroundColor(.white).frame(minHeight: 42)
        }
    }

    @ViewBuilder private func modalContent(_ destination: Modal) -> some View {
        switch destination {
        case .settings: SettingsView(wallet: $wallet, save: save)
        case .profile: ProfileView(wallet: $wallet, save: save)
        case .accounts: AccountsView(wallet: $wallet, save: save)
        case .addFunds: AddFundsView(wallet: $wallet, save: save)
        case .send: SendView(wallet: $wallet, save: save)
        case .receive: ReceiveView(wallet: $wallet, save: save)
        case .addCash: CashView(wallet: $wallet, save: save)
        case .buy: BuyView(wallet: $wallet, save: save)
        case .history: HistoryView(wallet: wallet)
        case .watchlist: WatchlistView()
        case .chats: ExplanationView(title: "Chats", icon: "bubble.left", message: "No conversations yet. Messaging is unavailable in this offline simulator.")
        case .help: ExplanationView(title: "Help & Support", icon: "info.circle", message: "Add simulated tokens using the + button or Profile → Settings → Add funds. Balances save on this phone. Spectra is independent and unaffiliated with Phantom; it does not hold or transfer real money.")
        }
    }
}

var brandBadge: some View {
    Text("Spectra").font(.system(size: 11, weight: .medium)).foregroundColor(lavender)
        .padding(.horizontal, 9).padding(.vertical, 5).background(lavender.opacity(0.1), in: Capsule())
}

struct Avatar: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.98, green: 0.98, blue: 0.73))
            Circle().fill(Color(red: 1, green: 0.43, blue: 0.24)).frame(width: size * 0.69, height: size * 0.69).offset(y: size * 0.17)
            Text("✦").font(.system(size: size * 0.34, weight: .bold)).foregroundColor(.black).offset(y: size * 0.14)
            Text("!!").font(.system(size: size * 0.23, weight: .heavy)).foregroundColor(.orange).rotationEffect(.degrees(-14)).offset(y: -size * 0.26)
        }.frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}

struct CoinMark: View {
    var coin: Coin
    var size: CGFloat = 42
    var body: some View {
        ZStack {
            Circle().fill(coin.id == "BTC" ? Color.orange : coin.id == "USDC" ? Color.blue : Color.black)
            if coin.id == "SOL" {
                VStack(spacing: size * 0.06) {
                    ForEach(0..<3) { index in
                        Parallelogram(reverse: index == 1)
                            .fill(LinearGradient(colors: [.mint, lavender, .purple], startPoint: .topTrailing, endPoint: .bottomLeading))
                            .frame(width: size * 0.53, height: size * 0.11)
                    }
                }
            } else {
                Text(coin.glyph).font(.system(size: size * 0.66, weight: .semibold))
                    .foregroundColor(coin.id == "ETH" ? Color(white: 0.75) : .white)
            }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}
private struct Parallelogram: Shape {
    var reverse: Bool
    func path(in rect: CGRect) -> Path {
        Path { path in
            let inset = rect.width * 0.16
            path.move(to: CGPoint(x: reverse ? 0 : inset, y: 0))
            path.addLine(to: CGPoint(x: reverse ? rect.width - inset : rect.width, y: 0))
            path.addLine(to: CGPoint(x: reverse ? rect.width : rect.width - inset, y: rect.height))
            path.addLine(to: CGPoint(x: reverse ? inset : 0, y: rect.height))
            path.closeSubpath()
        }
    }
}

private struct TokenRow: View {
    let coin: Coin
    let units: Double
    var body: some View {
        HStack(spacing: 12) {
            CoinMark(coin: coin)
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.name).font(.system(size: 19, weight: .semibold))
                Text("\(units.formatted(.number.precision(.fractionLength(0...5)))) \(coin.id)")
                    .font(.system(size: 15)).foregroundColor(muted).lineLimit(1).minimumScaleFactor(0.65)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 5) {
                Text(money(units * coin.price)).font(.system(size: 18)).lineLimit(1).minimumScaleFactor(0.55)
                Text("$0.00").font(.system(size: 14)).foregroundColor(muted)
            }
        }.padding(17).background(panel, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white.opacity(0.045)))
    }
}

private struct CoinDetail: View {
    let coin: Coin
    let units: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            brandBadge
            CoinMark(coin: coin, size: 65)
            Text(coin.name).font(.largeTitle.bold())
            Text(money(units * coin.price)).font(.system(size: 45, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.5)
            Text("\(units.formatted(.number.precision(.fractionLength(0...6)))) \(coin.id)").foregroundColor(muted)
            LabeledContent("Fixed example price", value: money(coin.price))
            Text("Add tokens using the + button or Profile → Settings → Add funds. Real trading and transfers are unavailable.")
                .font(.footnote).foregroundColor(muted)
            Spacer()
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(canvas)
    }
}

struct AccountEditorView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    var body: some View {
        Form {
            Section { HStack(spacing: 16) { Avatar(size: 48); Text("Spectra").font(.title2.bold()); Spacer(); brandBadge } }
            Section("Account") {
                TextField("Account name", text: $wallet.name)
                    .onChange(of: wallet.name) { value in wallet.name = String(value.prefix(30)); save() }
                NavigationLink("Settings") { SettingsView(wallet: $wallet, save: save) }
            }
            Section { Text("Your portfolio, on this device.").font(.footnote).foregroundColor(muted) }
        }.scrollContentBackground(.hidden).background(canvas).navigationTitle("Profile")
    }
}

struct SettingsView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @State private var search = ""
    @State private var reset = false

    private func matches(_ value: String) -> Bool { search.isEmpty || value.localizedCaseInsensitiveContains(search) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack { Text("Settings").font(.system(size: 25, weight: .semibold)); Spacer(); brandBadge }
                HStack(spacing: 10) { Image(systemName: "magnifyingglass"); TextField("Search", text: $search) }
                    .font(.system(size: 19)).foregroundColor(muted).padding(15).background(panel, in: Capsule())
                if matches("Profile Account") {
                    NavigationLink { ProfileView(wallet: $wallet, save: save) } label: {
                        HStack(spacing: 14) {
                            Avatar(size: 43)
                            Text("@" + wallet.name.replacingOccurrences(of: " ", with: "")).font(.system(size: 21, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.5)
                            Spacer(); Image(systemName: "chevron.right").foregroundColor(muted)
                        }.padding(20).background(panel, in: RoundedRectangle(cornerRadius: 25))
                    }.buttonStyle(.plain)
                }
                VStack(spacing: 0) {
                    if matches("Manage Accounts") { NavigationLink { AccountsView(wallet: $wallet, save: save) } label: { settingsRow("Manage Accounts", "wallet.pass", value: "1") } }
                    if matches("Preferences") { NavigationLink { PreferencesView() } label: { settingsRow("Preferences", "slider.horizontal.3") } }
                    if matches("Security & Privacy") { NavigationLink { SecurityView(wallet: $wallet, save: save) } label: { settingsRow("Security & Privacy", "shield") } }
                }.background(groupPanel, in: RoundedRectangle(cornerRadius: 24)).clipShape(RoundedRectangle(cornerRadius: 24))
                VStack(spacing: 0) {
                    if matches("Active Networks") { NavigationLink { NetworksView() } label: { settingsRow("Active Networks", "network", value: "None") } }
                    if matches("Contacts") { NavigationLink { ExplanationView(title: "Contacts", icon: "person.crop.rectangle", message: "No contacts. Real transfers are unavailable in this simulator.") } label: { settingsRow("Contacts", "person.crop.rectangle") } }
                    if matches("Connected Apps") { NavigationLink { ConnectedAppsView() } label: { settingsRow("Connected Apps", "square.3.layers.3d") } }
                }.background(groupPanel, in: RoundedRectangle(cornerRadius: 24)).clipShape(RoundedRectangle(cornerRadius: 24))
                if matches("Developer Settings Add funds") {
                    VStack(spacing: 0) {
                        NavigationLink { AddFundsView(wallet: $wallet, save: save) } label: { settingsRow("Add funds", "plus.circle") }
                        Button(role: .destructive) { reset = true } label: { settingsRow("Reset balances", "arrow.counterclockwise") }
                    }.background(groupPanel, in: RoundedRectangle(cornerRadius: 24)).clipShape(RoundedRectangle(cornerRadius: 24))
                }
                VStack(spacing: 0) {
                    if matches("Help & Support") { NavigationLink { ExplanationView(title: "Help & Support", icon: "info.circle", message: "Choose Add funds to adjust your simulated portfolio. Changes save on this phone automatically. Use Reset balances to clear balances and history.") } label: { settingsRow("Help & Support", "info.circle") } }
                    if matches("About Spectra") { NavigationLink { ExplanationView(title: "About Spectra", icon: "sparkles", message: "Spectra 1.4 · Independent wallet simulator. Unaffiliated with Phantom. All balances and market cards are simulated and have no monetary value.") } label: { settingsRow("About Spectra", "sparkles") } }
                }.background(groupPanel, in: RoundedRectangle(cornerRadius: 24)).clipShape(RoundedRectangle(cornerRadius: 24))
            }.padding(20)
        }.background(canvas).navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Reset balances and local history?", isPresented: $reset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { wallet.balances = [:]; wallet.cash = nil; wallet.entries = []; save() }
                Button("Cancel", role: .cancel) {}
            }
    }
    private func settingsRow(_ title: String, _ icon: String, value: String = "") -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 19)).frame(width: 23)
            Text(title).font(.system(size: 18)).lineLimit(1).minimumScaleFactor(0.65)
            Spacer(minLength: 0)
            if !value.isEmpty { Text(value).foregroundColor(muted) }
            Image(systemName: "chevron.right").font(.system(size: 16)).foregroundColor(muted)
        }.foregroundColor(.white).padding(.horizontal, 20).frame(minHeight: 53)
            .overlay(alignment: .bottom) { Rectangle().fill(canvas).frame(height: 0.6) }
    }
}

private struct HistoryView: View {
    let wallet: WalletData
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                brandBadge
                if wallet.entries.isEmpty { Text("No activity yet").font(.title2); Text("Added tokens will appear here.").foregroundColor(muted) }
                ForEach(wallet.entries) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.kind == "send" ? "arrow.up.right" : "plus.circle").foregroundColor(lavender)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.kind == "send" ? "Sent locally" : entry.kind == "buy" ? "Bought locally" : entry.kind == "cash" ? "Cash added" : "Funds added").font(.subheadline)
                            if let recipient = entry.note { Text(recipient).font(.caption).foregroundColor(muted).lineLimit(1) }
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(muted)
                        }
                        Spacer()
                        Text("\(entry.units >= 0 ? "+" : "")\(entry.units.formatted(.number.precision(.fractionLength(0...4)))) \(entry.coin)").font(.caption).foregroundColor(lavender)
                    }.padding(16).background(panel, in: RoundedRectangle(cornerRadius: 19))
                }
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
        }.background(canvas).navigationTitle("History")
    }
}

private struct WatchlistView: View {
    @AppStorage("spectra.watchlist.v1") private var watchlist = "SOL,BTC"
    var body: some View {
        List {
            Section { Text("Follow example tokens. Prices are fictional and fixed.").font(.footnote).foregroundColor(muted) }
            ForEach(Coin.all) { coin in
                HStack(spacing: 12) {
                    CoinMark(coin: coin)
                    VStack(alignment: .leading) { Text(coin.name); Text(money(coin.price)).font(.caption).foregroundColor(muted) }
                    Spacer()
                    Button {
                        var chosen = Set(watchlist.split(separator: ",").map(String.init))
                        if chosen.contains(coin.id) { chosen.remove(coin.id) } else { chosen.insert(coin.id) }
                        watchlist = chosen.sorted().joined(separator: ",")
                    } label: {
                        Image(systemName: watchlist.split(separator: ",").contains(Substring(coin.id)) ? "heart.fill" : "heart").foregroundColor(lavender)
                    }.accessibilityLabel("Toggle \(coin.name) watchlist")
                }.padding(.vertical, 6).listRowBackground(panel)
            }
        }.scrollContentBackground(.hidden).background(canvas).navigationTitle("Watchlist")
    }
}

struct ExplanationView: View {
    let title: String
    let icon: String
    let message: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                brandBadge
                Image(systemName: icon).font(.system(size: 40)).foregroundColor(lavender)
                Text(message).font(.body).foregroundColor(muted)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }.background(canvas).navigationTitle(title)
    }
}
struct AddFundsView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var coin = "SOL"
    @State private var amount = ""
    @State private var error = ""

    private var parsed: Double? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.isLenient = false
        let separator = formatter.decimalSeparator ?? "."
        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.components(separatedBy: separator).count <= 2,
              trimmed.replacingOccurrences(of: separator, with: "").allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Double(trimmed.replacingOccurrences(of: separator, with: "."))
    }

    var body: some View {
        Form {
            Section("Add funds") {
                Picker("Token", selection: $coin) { ForEach(Coin.all) { Text($0.name + " (" + $0.id + ")").tag($0.id) } }
                TextField("Number of tokens", text: $amount).keyboardType(.decimalPad)
                if let units = parsed, let asset = Coin.all.first(where: { $0.id == coin }), units.isFinite {
                    LabeledContent("Value", value: money(units * asset.price))
                }
                HStack {
                    ForEach([1, 10, 100, 1000], id: \.self) { value in
                        Button("\(value)") { amount = String(value) }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                    }
                }
            }
            Section {
                Button("Add tokens") {
                    guard let units = parsed, wallet.add(coin: coin, units: units) else {
                        error = "Enter a positive amount. The portfolio limit is $1 billion in simulated value."
                        return
                    }
                    save(); dismiss()
                }.disabled(parsed == nil || (parsed ?? 0) <= 0)
                if !error.isEmpty { Text(error).foregroundColor(.red).font(.footnote) }
            } footer: { Text("Changes appear in your balance and local activity. No real money is added or transferred.") }
        }.navigationTitle("Add funds")
    }
}

private func enteredAmount(_ text: String) -> Double? {
    let separator = Locale.current.decimalSeparator ?? "."
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalized = trimmed.replacingOccurrences(of: separator, with: ".")
    guard !normalized.isEmpty, normalized.components(separatedBy: ".").count <= 2,
          normalized.allSatisfy({ ($0.isASCII && $0.isNumber) || $0 == "." }),
          let amount = Double(normalized), amount.isFinite, amount > 0 else { return nil }
    return amount
}

private struct CashView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var error = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Cash balance").foregroundColor(muted)
                Text(money(wallet.cashBalance)).font(.system(size: 43, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.4)
                HStack { Text("$").font(.largeTitle); TextField("0.00", text: $amount).keyboardType(.decimalPad).font(.system(size: 42, weight: .medium)) }
                    .padding(20).background(panel, in: RoundedRectangle(cornerRadius: 22))
                HStack {
                    ForEach([25, 50, 100, 500], id: \.self) { value in
                        Button("$\(value)") { amount = String(value) }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                    }
                }
                Button {
                    guard let dollars = enteredAmount(amount), wallet.addCash(dollars) else {
                        error = "Enter a positive amount within the $1 billion portfolio limit."
                        return
                    }
                    save(); dismiss()
                } label: { primaryLabel("Add Cash") }.disabled(enteredAmount(amount) == nil)
                if !error.isEmpty { Text(error).font(.footnote).foregroundColor(.pink) }
                NavigationLink { BuyView(wallet: $wallet, save: save) } label: { Label("Buy crypto", systemImage: "arrow.left.arrow.right").font(.headline) }
                Text("This updates your local portfolio. No card or bank account is charged.").font(.footnote).foregroundColor(muted)
            }.padding(24)
        }.background(canvas).navigationTitle("Add Cash").navigationBarTitleDisplayMode(.inline)
    }
}

private func primaryLabel(_ title: String) -> some View {
    Text(title).font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding(18)
        .background(lavender, in: RoundedRectangle(cornerRadius: 18))
}

private struct BuyView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @State private var coin = "SOL"
    @State private var amount = ""
    @State private var error = ""
    @State private var review = false
    @State private var completed = false
    private var asset: Coin { Coin.all.first(where: { $0.id == coin }) ?? Coin.all[0] }
    private var canBuy: Bool { (enteredAmount(amount) ?? .infinity) <= wallet.cashBalance }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if completed {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 54)).foregroundColor(lavender)
                    Text("Portfolio updated").font(.title.bold())
                    Text("Your purchase is recorded in local History. No exchange order was placed.").foregroundColor(muted)
                } else {
                    Picker("Token", selection: $coin) {
                        ForEach(Coin.all) { Text($0.name + " (" + $0.id + ")").tag($0.id) }
                    }.pickerStyle(.menu)
                    HStack { Text("$").font(.largeTitle); TextField("0.00", text: $amount).keyboardType(.decimalPad).font(.system(size: 42, weight: .medium)) }
                        .padding(20).background(panel, in: RoundedRectangle(cornerRadius: 22))
                    Text("Cash available: " + money(wallet.cashBalance)).foregroundColor(muted)
                    if let dollars = enteredAmount(amount) {
                        LabeledContent("You receive", value: (dollars / asset.price).formatted(.number.precision(.fractionLength(0...8))) + " " + coin)
                    }
                    LabeledContent("Reference price", value: money(asset.price))
                    Button { review = true } label: { primaryLabel("Review purchase") }.disabled(!canBuy)
                    if !error.isEmpty { Text(error).foregroundColor(.pink) }
                    NavigationLink { CashView(wallet: $wallet, save: save) } label: { Text("Add Cash").font(.headline) }
                    Text("Uses your local cash balance at fixed example prices. No real crypto is purchased.").font(.footnote).foregroundColor(muted)
                }
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }.background(canvas).navigationTitle("Buy crypto").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Use \(money(enteredAmount(amount) ?? 0)) of local cash to buy \(coin)?", isPresented: $review, titleVisibility: .visible) {
                Button("Confirm purchase") {
                    guard let dollars = enteredAmount(amount), wallet.buy(coin: coin, dollars: dollars) else {
                        error = "Not enough cash. Add Cash first, or choose a smaller amount."
                        return
                    }
                    save(); completed = true
                }
                Button("Cancel", role: .cancel) {}
            }
    }
}

private struct SendView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    @State private var coin = "SOL"
    @State private var amount = ""
    @State private var recipient = ""
    @State private var review = false
    @State private var completed = false
    @State private var error = ""
    private var canSend: Bool {
        guard let units = enteredAmount(amount) else { return false }
        let label = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        return units <= (wallet.balances[coin] ?? 0) && !label.isEmpty && label.count <= 80
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if completed {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 54)).foregroundColor(lavender)
                    Text("Portfolio updated").font(.title.bold())
                    Text("The amount was deducted and saved to local History. Nothing was sent on a blockchain.").foregroundColor(muted)
                } else {
                    Picker("Token", selection: $coin) { ForEach(Coin.all) { Text($0.name + " (" + $0.id + ")").tag($0.id) } }.pickerStyle(.menu)
                    TextField("Recipient nickname", text: $recipient).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .padding(18).background(panel, in: RoundedRectangle(cornerRadius: 18))
                        .onChange(of: recipient) { value in recipient = String(value.prefix(80)) }
                    HStack {
                        TextField("0", text: $amount).keyboardType(.decimalPad).font(.system(size: 38, weight: .medium))
                        Text(coin).foregroundColor(muted)
                    }.padding(20).background(panel, in: RoundedRectangle(cornerRadius: 22))
                    Text("Available: \((wallet.balances[coin] ?? 0).formatted(.number.precision(.fractionLength(0...8)))) \(coin)").foregroundColor(muted)
                    Button { review = true } label: { primaryLabel("Review send") }.disabled(!canSend)
                    if !error.isEmpty { Text(error).foregroundColor(.pink) }
                    Text("Local roleplay action. The recipient is a label, not a destination wallet; no blockchain transfer occurs.").font(.footnote).foregroundColor(muted)
                }
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }.background(canvas).navigationTitle("Send").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Deduct \(amount) \(coin) locally for \(recipient)?", isPresented: $review, titleVisibility: .visible) {
                Button("Confirm local send") {
                    guard let units = enteredAmount(amount), wallet.send(coin: coin, units: units, recipient: recipient) else {
                        error = "Check the amount, recipient, and available balance."
                        return
                    }
                    save(); completed = true
                }
                Button("Cancel", role: .cancel) {}
            }
    }
}

private struct ReceiveView: View {
    @Binding var wallet: WalletData
    let save: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "qrcode").font(.system(size: 64)).foregroundColor(lavender).accessibilityHidden(true)
                Text("Receive tokens").font(.title.bold())
                Text("Spectra has no receiving address. Add tokens locally to try the wallet flow; don't send real crypto to this app.").foregroundColor(muted)
                NavigationLink { AddFundsView(wallet: $wallet, save: save) } label: { primaryLabel("Add tokens locally") }
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }.background(canvas).navigationTitle("Receive").navigationBarTitleDisplayMode(.inline)
    }
}
