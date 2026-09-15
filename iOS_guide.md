# *JW Library* roll-back guide for iOS

Read this through first to make sure you understand all the steps:

**Goal:** To download and install an older version of *JW Library* (v15.6) in order to install custom JWPUB archives on an iPhone/iPad using your iMac/MacBook ("Mac") (without jailbreaking). Once the custom JWPUB files are installed, *JW Library* can be updated to the latest version, while the custom JWPUBs remain in the app.

**Difficulty:** Intermediate — some experience with using Terminal and command-line commands is helpful.

**Duration:** About 20 to 30 minutes.

**Important:** The process involves re-installing *JW Library*, so you will need to re-download all your Bible, publications, videos, etc.

## What you need

- Mac
- iPhone or iPad
- USB cable
- Apple Account
- Internet connection

> ⚠️ **IMPORTANT:** Before proceeding, **make sure to make a backup of your personal *JW Library* data** (notes, highlights and playlists). Go to *Personal Study → Create Backup*.

> 📌 **NOTE:** The older `JWLibrary-15.6.ipa` app file obtained through this process is downloaded from the official App Store and is tied to your personal Apple Account. Therefore, it cannot be shared with other people. Each person needs to obtain their own copy.

## 1. Install necessary tools

Search for and open Terminal on your Mac.

First, install Homebrew, which will allow us to install the other tools needed for this process.

Inside Terminal, run (copy and paste or type) the following command:

```bash
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew is already installed — skipping Homebrew installation."
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
```

If Homebrew is already installed, you'll see a message saying so and can continue. Otherwise, Homebrew will be installed on your Mac. This may take a while, and the installation may ask for your Mac's login password; enter the password when prompted.

After Homebrew has been successfully installed, run the following commands:

```bash
brew install ipatool
brew install -y ideviceinstaller
```

## 2. Log in to *ipatool*

First, connect your device to your Mac using a USB cable. Unlock your device and, if prompted, choose "Trust" and follow the instructions on the screen.

Once connected, back inside Terminal, run:

```bash
ipatool auth login
```

Follow the instructions to sign in with your Apple Account.

> 📌 **NOTE:** *ipatool* communicates with Apple's servers to authenticate your account, and Apple might require two-factor authentication as part of the sign-in process.

### 3. Download *JW Library* v15.6

Once you've successfully logged in, you can download the older version of *JW Library* directly from the App Store...

**For an iPhone** inside Terminal, run:

```bash
ipatool download --app-id 672417831 --external-version-id 878901217 --platform iphone --output ~/Downloads/JWLibrary-15.6.ipa --purchase
```

**For an iPad** inside Terminal, run:

```bash
ipatool download --app-id 672417831 --external-version-id 878901217 --platform ipad --output ~/Downloads/JWLibrary-15.6.ipa --purchase
```

> 📌 **NOTE:** Though we are using the `--purchase` flag, there is no charge since *JW Library* is free.

The downloaded file will be saved in your Mac's `Downloads` directory. It should be named `JWLibrary-15.6.ipa`. Check to see if it's there.

## 4. Import *JW Library* v15.6 to your device

To install the older version of the *JW Library* we just downloaded, delete the currently installed *JW Library* app from your iPhone/iPad, if you have one installed. 

> ⚠️ **IMPORTANT:** Make sure you have successfully completed the backup described at the beginning of this guide.

After deleting *JW Library* from your device, you are ready to install the older version.

Make sure your device is connected to your Mac. Inside Terminal, run:

```bash
ideviceinstaller install ~/Downloads/JWLibrary-15.6.ipa
```

Check that *JW Library* installed properly on your iPhone/iPad; you should now be running version 15.6.

## 5. Install custom JWPUBs

You are now ready to install your custom JWPUB archives to your device. If the files are already on your iPhone/iPad, you can import them manually, one by one, using the normal file-sharing/open-in-JW-Library process.

## ✅ Done

Once you have installed everything you need, you can safely update *JW Library* to the latest version; your custom JWPUB archives will remain installed after the update.

At this point, you can restore your saved backup and download your official Bibles, publications, videos, etc. Go to *Personal Study → Restore Backup*.

You may wish to keep the downloaded `JWLibrary-15.6.ipa` file on your Mac in case you need to repeat the process (starting with step #4).
