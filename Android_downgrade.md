# Downgrading JW Library on Android

Read this through first to make sure you understand all the steps:

1. **Download [JW Library v15.6.1](https://www.apkmirror.com/apk/jehovahs-witnesses/jw-library/jw-library-15-6-1-release/)**

2. **Backup your notes, highlights, and bookmarks**
   - Go to *Personal Study > Create Backup*

3. **Uninstall and reinstall**
    - Uninstall the current version of JW Library
    - Install the downloaded APK file
      - You will be *starting from scratch* with no data

4. **Install all the JWPUBs you need/want**
   - You can install them normally/as before (without *jwlIntegrator*)

5. **You now have two choices**
    - **Stay on v15.6.1**
      - Go to the *Play Store > JW Library* and disable automatic updates
    - **Update to the latest version**
      - Let the Play Store update the app normally

6. **Personal Study > Restore Backup**
    - If you chose to **stay on v15.6.1**, your backup *will not* restore as is, as it was made with a newer version of the app
      - You will need to downgrade it using [JWLManager](https://github.com/erykjj/jwlmanager) to open it and then save it selecting the `v14 schema`
    - If you are on the **latest version**, your backup should restore normally

7. **Redownload all your publications and videos**
