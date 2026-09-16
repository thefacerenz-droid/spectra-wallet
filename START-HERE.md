# Spectra for iPhone

This ZIP contains the native SwiftUI app source, an Xcode project specification,
and a GitHub Actions workflow. It is **not a compiled or signed IPA**.
Version 1.4 uses the supplied screenshots as layout references: black background,
purple top tabs, left-aligned balance, horizontal cards, a sliding profile menu,
and grouped Settings. It keeps its own name and icon.
It is an independent simulator, not Phantom. The main screens use Spectra branding without simulation badges.
Settings → About Spectra explains that all balances are roleplay values. No seed phrase, private key, payment, or blockchain access is used.

## Tomorrow on your Windows PC

1. Download and extract this ZIP.
2. Create a GitHub repository. Upload the **contents** of the SpectraWallet
   folder into the repository root: project.yml, the SpectraWallet source
   folder, Tests, scripts, and **.github/workflows/build-ios.yml**.
   Do not upload the ZIP itself or nest the whole project an extra level down.
   If the Windows folder picker omits .github, use GitHub's Add file → Create
   new file, enter `.github/workflows/build-ios.yml` as its name, and paste
   the included workflow text. Keep the workflow on your default branch.
3. Open the repository's **Actions** tab. Enable Actions if prompted.
4. Choose **Build iPhone app → Run workflow**.
5. If the run succeeds, open it and download **Spectra-unsigned-iPhone** under
   Artifacts. Extract that download to get **Spectra-unsigned.ipa**.

The workflow uses a hosted Mac to build the app; your Windows PC controls it
through GitHub. Check your GitHub Actions allowance before running: hosted
Mac usage may be billed depending on your account and repository.
The workflow runs balance, cash, buy/send, and saved-data migration tests before compiling. The generated Xcode project
does not need to be manually created in Windows.

## Installing on your iPhone

An unsigned IPA does not install by itself. ESign is a signing tool, not a
compiler. You still need a legitimate Apple signing certificate with its
private key and a matching provisioning profile that permits your device
and the app identifier. The default app identifier is
`com.renz.spectrawallet`; edit PRODUCT_BUNDLE_IDENTIFIER in project.yml to
match your profile before building if necessary.

If you already have a working signing setup, import the generated IPA into
that tool and sign using your own valid credentials. Exact buttons vary by
signer version. This package includes no certificate or provisioning profile.
Keep signing credentials out of your repository and chat messages.

If you don't have signing set up, the next step is choosing a supported
device installation/signing route; uploading the ZIP to Drive does not
publish or install the app. App Store/TestFlight distribution requires a
separate signed archive and Apple's distribution setup; this unsigned
workflow is not an App Store publishing workflow.

## Using the app

- Start at $0. Tap the profile circle → Settings → Add funds.
- Choose SOL, ETH, BTC, or USDC and enter the number of pretend tokens.
- Tap Add tokens. The total and Activity tab update automatically.
- Balances and your account name persist on the phone across app launches.
- Tap a token for details; the bottom search opens Explore.
- Existing saved token balances and History remain readable after upgrading.
- The avatar opens a sliding profile menu with Profile, Watchlist, History, and Settings.
- Watchlist hearts save on this device. Trade browses tokens; trading is unavailable.
- Perps and Predictions cards show labeled sample data, not live markets or wagering.
- Reset balances and activity in Settings, with confirmation.
- The purple + button opens a blurred action menu: Send, Receive, Add Cash, Trade.
- Add Cash increases a separate local USD balance. Trade opens Buy crypto.
- Buy uses local cash to credit tokens at fixed prices. Send debits tokens after review.
- Receive links to local token crediting; it has no blockchain address.
- History records local cash, buy, send, and token additions.
- There are no real transfers, exchange orders, bank charges, or blockchain receipts.

Prices are intentionally fictional fixed examples: SOL $150, ETH $3,000,
BTC $60,000, USDC $1. These are not live market quotes. Portfolio value is
capped at $1 billion. The most recent 100 local additions are retained.

The preview folder contains a static HTML layout illustration. It is not the native
app or evidence of a successful iOS build; icons and text metrics may differ.
Open preview/layout.html in a browser for the version 1.3 Home, drawer and action
menu illustration. Version 1.4 adds native screens beyond that illustration;
see UPDATE-1.4.md.

## Validation and limits

Project structure, YAML, asset metadata, and packaging shell syntax were
checked when preparing this package. Native compilation, Swift tests, and
iPhone visual/device testing could not run in the Linux authoring environment.
The included workflow performs the first native compile and model test run.
An iOS 16+ iPhone is the target. Review the built app on-device before sharing.
This is a working-source deliverable, not a claim of a tested signed binary.

## Reference documentation

- [XcodeGen project specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [Run a GitHub Actions workflow](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)
- [Apple: distribute to registered devices](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)

## Local Mac build (optional)

Install Xcode and XcodeGen, then run from this folder:

```sh
swiftc SpectraWallet/Wallet.swift Tests/main.swift -o /tmp/wallet-tests
/tmp/wallet-tests
xcodegen generate
xcodebuild -project SpectraWallet.xcodeproj -scheme SpectraWallet \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
bash scripts/package-ipa.sh
```
