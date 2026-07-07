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
2. Find the newest release at the top of the list — it'll be named
   something like **Bottler v1.0.0**.
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
shows a "Let's set up Wine" screen and walks you through getting it
installed — no Terminal knowledge required:

1. **If Homebrew isn't installed yet**, Bottler shows an **"Install
   Homebrew First"** button. Click it — this opens Terminal with the
   official Homebrew install command already typed in for you.
   - The **first time** you do this, macOS will show its own separate
     permission popup: *"Bottler" wants access to control "Terminal."*
     Click **OK** / **Allow** on that popup. This is a one-time system
     permission, not something Bottler can skip — macOS requires it
     before any app can open Terminal on your behalf.
   - In the Terminal window that opens, you'll be asked for your **Mac's
     password** (the one you log into your computer with). Type it and
     press Return — the cursor won't visibly move as you type, which is
     normal for password prompts in Terminal.
   - Homebrew will then download and install. This can take a few
     minutes; you'll see a lot of text scroll by. Wait until it finishes
     and returns you to a plain prompt line.
2. Switch back to the **Bottler** app and click **Refresh**.
3. Once Bottler detects Homebrew, the screen changes to offer **"Install
   Wine Automatically."** Click it, and Bottler installs both Wine and
   winetricks for you in the background, showing a live progress log —
   no more Terminal needed from this point on.
4. When it finishes, you're ready to create your first bottle.

If a step doesn't behave as described — a button seems to do nothing, or
an error appears — check whether macOS is showing a permission popup
behind the main window (⌘+Tab to check for hidden dialogs), since several
of these steps require a one-time system permission grant the first time
around.
