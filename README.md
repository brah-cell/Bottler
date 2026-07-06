# Bottler

A native macOS app for managing Wine bottles — create and organize Wine
prefixes, install Windows applications into them, and launch them again
later, all from a normal-looking Mac app.

## Requirements

- **macOS 13 (Ventura) or later.** Bottler won't run on older versions of macOS.
- **An internet connection for first-time setup.** Bottler needs Wine (the
  compatibility layer that lets Windows programs run on macOS) to actually
  do anything, but you don't need to go find and install this yourself.
  The first time you open Bottler and it doesn't find Wine already on your
  Mac, it will offer to install both Wine and winetricks for you
  automatically in the background, using Homebrew. If Homebrew itself
  isn't installed either, Bottler will walk you through getting that set
  up first, since that one step needs your Mac password and can't be
  fully automated.

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
a paid Apple Developer certificate. This is normal and expected — here's
how to get past it:

1. Open **Applications** in Finder and find **Bottler**.
2. **Right-click** (or Control-click) on it — don't just double-click.
3. Choose **Open** from the menu that appears.
4. A dialog will pop up warning about the unidentified developer. Click
   **Open** on that dialog to confirm you trust it.

You only need to do this once. After this first launch, Bottler opens
normally with a regular double-click, just like any other app.

Once it's open, if Wine isn't already installed on your Mac, Bottler will
show a short setup screen and offer to install everything it needs — just
click through that, and you're ready to create your first bottle.
