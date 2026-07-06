# Bottler

A native macOS app for managing Wine bottles.

## Requirements

- macOS 13 (Ventura) or later
- Wine — you don't need to install this yourself. If Bottler doesn't find
  one on first launch, it offers to install Wine + winetricks for you
  automatically via Homebrew (installing Homebrew first too, if needed).

## Setup

**Option A — Download the built app (easiest):**
Go to this repository's **Releases** tab, download the latest `Bottler.zip`,
unzip it, and drag `Bottler.app` into `/Applications`.

**Option B — Build it yourself:**
Requires only the Xcode Command Line Tools, not full Xcode:
```bash
xcode-select --install   # skip if already installed
```
Then, from this project folder:
```bash
chmod +x build_app.sh
./build_app.sh
mv Bottler.app /Applications/
```

## First launch

Since the app isn't signed with a paid Apple Developer ID, Gatekeeper will
flag it as being from an "unidentified developer" the first time you open
it. **Right-click the app → Open** (instead of double-clicking) and confirm
on the dialog that appears. This is only needed once per Mac — after that,
it opens normally.
