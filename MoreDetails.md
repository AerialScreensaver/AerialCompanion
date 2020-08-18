## I thought Aerial had auto-updates already?  

Aerial had auto-updates starting with [version 1.5.0](https://github.com/JohnCoates/Aerial/blob/master/Documentation/ChangeLog.md#150---may-31-2019), this feature was provided by the (awesome) [Sparkle framework](https://sparkle-project.org). 

With the introduction of macOS 10.15 (Catalina), things changed for screen savers and Aerial was no longer able to update itself because of the new security restrictions introduced with sandboxing. A temporary workaround was put in place in [version 1.8.0](https://github.com/JohnCoates/Aerial/blob/master/Documentation/ChangeLog.md#180---february-18-2020) where you could get notified of a new version.

![74758954-5858f700-5278-11ea-8e17-d034fdf57f33](https://user-images.githubusercontent.com/37544189/88542800-4e050b00-d017-11ea-8a80-6c9e0ef7b93b.jpg)

While this worked *most of the time*, for some users, the update check caused the ScreenSaverEngine to lose the keyboard/mouse focus, and pressing a key would no longer let you exit the screen saver (pressing `cmd-alt-shift-esc` would workaround the issue). This issue seem to trigger a lot more often in macOS 11 (Big Sur), so because of this, Sparkle was completely removed from Aerial with version 2.0.0, and this tool was created to replace it. 

## How does it work? 

You simply pick in the menu which version of Aerial you want to use (you can specify if you just want releases or beta versions too), and whether you want updates to happen automatically in the background, or if you'd rather be notified. If you choose to be notified, the icon will change color and clicking the menu will let you install the new version. 

## I meant, how does it work technically?

In this repository, I store a [manifest file](https://github.com/glouel/AerialUpdater/blob/main/manifest.json) that contains the version number of the latest release, and also the sha256 of the releases. This is generated after Aerial gets notarized for distribution and before I upload a new version on Aerial's [releases page](https://github.com/JohnCoates/Aerial/releases). 

Periodically, AerialUpdater checks the manifest to see if a new version was released. When you decide to perform an update, the following happens 
- AerialUpdater uses the version number from the manifest to infer the download link from Aerial's repository (the download links are always of the same format, so version `1.9.2` will be available at `https://github.com/JohnCoates/Aerial/releases/download/v1.9.2/Aerial.saver.zip`)
- The zip file is downloaded to `~/Library/Application Support/AerialUpdater/`
- The sha256 of the file is computed, and compared to the one from the manifest
- The zip is unzipped in place, looking for `Aerial.saver`
- `Aerial.saver` is verified (using macOS codesigning) to be using the correct Bundle ID (com.JohnCoates.Aerial)
- `Aerial.saver` is verified (using macOS codesigning) to be signed/notarized with my Developer Apple ID. 

If and only if everything checks out, then `Aerial.saver` gets copied to `~/Library/Screen Savers/`. 

## Do I have to use this? Is there an alternative?

You don't, and sure, as pointed out in Aerial's [installation instructions](https://github.com/JohnCoates/Aerial/blob/master/Documentation/Installation.md), you can also use `homebrew` if you want automatic updates. 

And you can always manually download and install Aerial from its Github repository.

## I don't want one more icon on my status bar!

Starting with version 0.5, Aerial Updater can now run in the background !

## Why should I trust you ? Who are you ?

I'm [Guillaume Louel](https://github.com/glouel), the developer of [Aerial](https://github.com/JohnCoates/Aerial/) since version 1.4. 
