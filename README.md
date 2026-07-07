# Bottler

A native macOS app for managing Wine bottles — create and organize Wine
prefixes, install Windows applications into them, and launch them again
later, all from a normal-looking Mac app.

## Requirements

- **macOS 13 (Ventura) or later.** Bottler won't run on older versions of macOS.
- **An internet connection for first-time setup**, so Bottler can install
  Homebrew, Wine, and winetricks on your behalf if they aren't already on
  your Mac.

## Setup

1. Open this repository's **Releases** tab (on the right-hand side of the
   main repository page on GitHub, or under the "Code" tab if you're on
   mobile).
2. Find the newest release at the top of the list.
3. Under that release, click **Assets** to expand it if it's collapsed,
   then click **Bottler.zip** to download it. It'll save to your **Downloads**
   folder by default.
4. Open **Finder**, go to **Downloads**, and double-click `Bottler.zip`.
   This unzips it into a plain `Bottler.app` file sitting right there in
   Downloads.
5. Drag `Bottler.app` out of the Downloads folder and drop it onto
   **Applications** in the Finder sidebar. This copies it into your
   Applications folder alongside all your other Mac apps.
6. You can now delete the original `Bottler.zip` file from Downloads if
   you like — it's no longer needed once the app has been copied over.

## First launch

The very first time you open Bottler, macOS will likely show a warning
that it's from an "unidentified developer," because it isn't signed with
a paid Apple Developer certificate. This is normal and expected:

1. Open **Applications** in Finder and find **Bottler**.
2. **Right-click** (or Control-click) on it — don't just double-click.
3. Choose **Open** from the menu that appears.
4. A dialog will pop up warning about the unidentified developer. Click
   **Open** on that dialog to confirm you trust it.

You only need to do this once. After this first launch, Bottler opens
normally with a regular double-click, just like any other app.

## Setting up Wine (happens automatically inside the app)

Once Bottler is open, if it doesn't find Wine already on your Mac, it
shows a "Let's set up Wine" screen with a single button:

1. Click **Set Up Wine Automatically**.
2. The **first time** you do this, macOS shows its own separate system
   popup: *"Bottler" wants access to control "Terminal."* Click **OK** /
   **Allow** on that popup — this is a one-time permission macOS requires
   before any app can open Terminal on your behalf, not something Bottler
   can skip.
3. A Terminal window opens and runs everything in one go: Homebrew (if
   it's missing), Rosetta 2 (if needed), Wine, and winetricks. If it asks
   for your **Mac's password** at any point, type it and press Return —
   the cursor won't visibly move as you type, which is normal for password
   prompts in Terminal.
4. This can take several minutes, especially the Wine download. Bottler
   automatically checks in the background every few seconds and moves on
   by itself once it detects Wine is ready — you don't need to click
   anything else. If you'd rather not wait, there's also an **"I finished
   — Check Now"** button once Terminal shows it's done.
5. When it's ready, you're set — go ahead and create your first bottle.

If a step doesn't behave as described — the setup button seems to do
nothing, or an error appears — check whether macOS is showing a permission
popup behind the main window (⌘+Tab to check for hidden dialogs), since the
first run needs a one-time system permission grant for Terminal access.
