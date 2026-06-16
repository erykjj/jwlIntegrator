[![Static Badge](https://img.shields.io/badge/releases-orange?logo=rss&logoColor=orange&color=black)](https://github.com/erykjj/jwlIntegrator/releases.atom) [![GitHub Downloads](https://img.shields.io/github/downloads/erykjj/jwlIntegrator/total?style=flat)](https://github.com/erykjj/jwlIntegrator/releases/latest)

**DISCLAIMER**: Whether we deal with *blockers* to remove content/functionality or *add-ons* to augment it, there will always be differing opinions. For instance, people use ad-blockers and VPNs for different reasons. I respect your conscience.

# jwlIntegrator

Commandline/terminal **utility** to integrate custom `.jwpub` archives into *JW Library*[^1] on Windows and macOS

## Downloads

- [macOS (universal)](https://github.com/erykjj/jwlIntegrator/releases/latest/download/jwlIntegrator_macos.tar.gz)
- [Windows (amd64)](https://github.com/erykjj/jwlIntegrator/releases/latest/download/jwlIntegrator_windows_amd64.zip)
- [Windows (ARM64)](https://github.com/erykjj/jwlIntegrator/releases/latest/download/jwlIntegrator_windows_arm64.zip)
- [Android (aarch64)](https://github.com/erykjj/jwlIntegrator/releases/latest/download/jwlIntegrator_android.sh) - see [below](https://github.com/erykjj/jwlIntegrator#android)

## Usage

### Windows

Unzip and execute:
```
Usage: jwlIntegrator.exe [-h | -v] <JWPUB archive>

 Options:
   -h, --help       Show this help message and exit.
   -v, --version    Show the version and exit.
```

### macOS

Unzip and give permissions (only once after downloading an unsigned binary):

```
xattr -cr jwlIntegrator
```

then:
```
Usage: jwlIntegrator [-h | -v] <JWPUB archive>

 Options:
   -h, --help       Show this help message and exit.
   -v, --version    Show the version and exit.
```

### Android

If you are *not* rooted[^2], you will need to [downgrade to v15.6.1](https://github.com/erykjj/jwlIntegrator/blob/main/Android_downgrade.md).

If you are rooted (ie., are the administrator of your device), you will need to have [Termux](https://termux.dev/en/)[^3] installed.

First, install jwlIntegrator as root within Termux. For example, if you have it in Download:

```
$ su
# sh /sdcard/Download/jwlIntegrator_android.sh
```

then:
```
# /data/local/jwlIntegrator/jwlIntegrator <JWPUB archive>
```

### iOS

You will need to [downgrade to v15.6](https://github.com/erykjj/jwlIntegrator/blob/main/iOS_downgrade.md).


<p align="center"><img src=".github/inf.png" width=50 title="infiniti@inventati.org"></p>

____
Feel free to get in touch and post any [issues and/or suggestions](https://github.com/erykjj/jwlIntegrator/issues).

My other *JW Library* projects: [**JWLManager**](https://github.com/erykjj/jwlmanager), [**jwlFusion**](https://github.com/erykjj/jwlFusion), [**jwlFusion** (Android)](https://github.com/erykjj/jwlFusion-app) & [**jwlFission**](https://github.com/erykjj/jwlFission-app)
____
#### Footnotes:
[^1]: [JW Library](https://www.jw.org/en/online-help/jw-library/) is a registered trademark of *Watch Tower Bible and Tract Society of Pennsylvania*
[^2]: If you don't know what this means, it's not for you ;-)
[^3]: Make sure your Termux *is not* from the Play Store, but directly from the Termux [repo](https://github.com/termux/termux-app) or through [F-Droid](https://f-droid.org/en/packages/com.termux/)
