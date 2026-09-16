# Video-reference update: Spectra 1.4

Based on the provided 102-second recording. The source now adds:

- Animated selected-tab pill; a separate expanded token-search view.
- Home Watchlist and Support sections below Predictions.
- Trade: horizontally scrolling market cards, market filter chips and asset rows.
- Predict: sports preview, Upcoming cards, Up or Down chart, 5 Minute Markets grid.
- Explore: grouped discovery and Learn rows with local information sheets.
- Your Accounts sheet: create local accounts, switch between separate balances
  and histories, and edit the current account name.
- Profile summary with Open/Closed tabs and a separate Manage Profile screen.
- Preferences, Active Networks and Connected Apps screens.
- Security & Privacy layout with a functional wallet-shortcut toggle, diagnostic
  text sharing and current-account reset. Face ID and analytics are disabled
  and described as unavailable; no recovery phrases or wallet keys exist.

The menus use Spectra's name and original icon. Live markets, authentic network
connections, social linking, real purchases/transfers and gambling are not
implemented. Prices and charts remain explicit local examples in their detail
views. The video did not show the Send/Buy forms or the + menu opening; the
previous screenshot-based local transaction flows remain in place.

Animation curves and timing are approximations based on observed transitions,
not frame-for-frame recreations. No iOS Simulator or Xcode is available here.
All Swift files passed tree-sitter syntax parsing, and the project YAML was
checked. Syntax parsing is not type checking or an iOS build. The existing
model checks are included in GitHub Actions; this new native UI
still needs compilation and device review. The included HTML is the older 1.3
layout illustration, not a rendering of the new Trade/Predict/Explore screens.

## Updating the repository and installed app

Extract the ZIP and replace the project files in your existing GitHub repository.
In particular, include the NEW file SpectraWallet/ReferenceScreens.swift along
with SpectraWallet/SpectraApp.swift and project.yml. Keep the paths intact.
Run Actions → Build iPhone app → Run workflow again. Install the new IPA using
the same signing account and app identifier. Do not delete the current app if
you want to keep its local balances.

## Device review

- Switch all four tabs and verify no clipping at the bottom search bar.
- Open search, type a token, clear it, and close search.
- Open + and close it by tapping X or the backdrop; verify all four actions.
- Open Your Accounts; create Account 2, add cash, return to Account 1, and confirm
  their balances and histories stay separate after restarting the app.
- Profile → Manage: edit name and bio. Verify the drawer updates.
- Preferences: turn Full motion off, then try tabs and drawer again.
- Security: toggle Show Wallet Shortcuts and confirm the + button visibility.
- Verify the network choices persist without implying an actual connection.
