# Update to Spectra 1.3

## What changed

- Bottom-right + opens a right-aligned menu over a blurred background: Send,
  Receive, Add Cash, Trade. Tap X or the backdrop to close it.
- Native spring transitions respect Reduce Motion. Screenshot references do
  not establish exact animation timing; motion is an approximation.
- Home now includes a separate Cash card and a compact percentage pill.
  Performance stays at zero because reference prices are fixed.
- The drawer includes a username-copy button, account row and social-link row.
  Social linking remains unavailable; History remains in the drawer.
- Send reviews and deducts local tokens. Buy reviews and spends local cash.
  These actions make no network requests and create no blockchain receipts.
- Receive provides local token crediting, not an actual deposit address.
- Existing balances and old history entries remain compatible.

## Update your GitHub repository

Extract the new ZIP. In the repository's Code tab, upload/replace:

1. SpectraWallet/Wallet.swift
2. SpectraWallet/SpectraApp.swift
3. Tests/main.swift
4. project.yml

Keep these paths the same as before. Alternatively upload the complete project
contents, including .github, without nesting another SpectraWallet folder.
Commit the files, then Actions → Build iPhone app → Run workflow on main.
Download the new artifact and install the resulting IPA through Sideloadly.
Use the same Apple Account and bundle identifier when upgrading. Do not delete
an existing installation if you want to preserve its locally saved balances.

## Checks

The package/YAML structure and preview JavaScript were checked locally. Swift
and Xcode are unavailable in the authoring environment. The new Swift tests
are included for the cloud workflow; they have not been run here. The previous
version's balance tests passed in the user's supplied Actions log.

After installing, check: + opens/closes, the background blocks taps, each action
opens the right sheet, Add Cash $100 → Buy SOL for $75 leaves $25 cash and 0.5
SOL, Send 0.1 SOL leaves 0.4 SOL, History shows all three entries, and restarting
preserves the state. Sending more than the balance should remain disabled.
