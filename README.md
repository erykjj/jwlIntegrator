**DISCLAIMER**: Whether we deal with *blockers* to remove content/functionality or *add-ons* to augment it, there will always be differing opinions. For instance, people use ad-blockers and VPNs for different reasons. I respect your conscience.

# jwlIntegrator

Commandline/terminal **utility** to integrate custom `.jwpub` archives into *JW Library*[^1] on Windows and macOS

## Downloads

- [macOS (universal)](https://github.com/erykjj/jwlIntegrator/releases/latest/download/jwlIntegrator_macos.tar.gz)
- [Windows (amd64)](https://github.com/erykjj/jwlIntegrator/releases/latest/download/jwlIntegrator_windows_amd64.zip)
- [Windows (ARM64)](https://github.com/erykjj/jwlIntegrator/releases/latest/download/jwlIntegrator_windows_arm64.zip)

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

<details>
<summary>What about other platforms?</summary><br/>

- on **Android**, stay on v15.6.1[^2] if you can and disable auto-updates in the Play Store
  - what is installed carries over when you do decide to update (for now)
  - if you are rooted, feel free to get in touch
- **iOS** - downgrade to v15.6 (technically-challenging)
- **Linux** - I wish we even had *JW Library*

</details><br/>

____
[![Static Badge](https://img.shields.io/badge/releases-orange?style=plastic&logo=rss&logoColor=orange&color=black)](https://github.com/erykjj/jwlIntegrator/releases.atom)

Feel free to get in touch and post any [issues and/or suggestions](https://github.com/erykjj/jwlIntegrator/issues).

My other *JW Library* projects: [**JWLManager**](https://github.com/erykjj/jwlmanager), [**jwlFusion**](https://github.com/erykjj/jwlFusion), [**jwlFusion** (Android)](https://github.com/erykjj/jwlFusion-app) & [**jwlFission**](https://github.com/erykjj/jwlFission-app)
____
#### Footnotes:
[^1]: [JW Library](https://www.jw.org/en/online-help/jw-library/) is a registered trademark of *Watch Tower Bible and Tract Society of Pennsylvania*
[^2]: Check (APKMirror)[https://www.apkmirror.com/apk/jehovahs-witnesses/jw-library/jw-library-15-6-1-release/] or (uptodown)[https://jw-library.en.uptodown.com/android/download/1136512921], etc. - at your own risk ;-)
