# Sound Enhancement Sony Xperia 10 Magisk Module

## DISCLAIMER
- Dolby & Sony apps and blobs are owned by Dolby™ and Sony™.
- The MIT license specified here is for the Magisk Module, not for Dolby nor Sony apps and blobs.

## Descriptions
- Equalizer soundfx ported from Sony Xperia 10 (I4113) and Sony Xperia 1 II (XQ-AT51) and integrated as a Magisk Module for all supported and rooted devices with Magisk
- Global type soundfx
- The Dolby Atmos changes ro.product.manufacturer system property, may breaks your platform apps and features functionality
- Doesn't support ACDB module because using effect proxy

## Sources
- https://dumps.tadiphone.dev/dumps/sony/i4113 kirin_dsds-user-10-53.1.A.2.2-053001A00020000200894138764-release-keys
- libhscomp_jni.so & libhscomp.so: https://dumps.tadiphone.dev/dumps/sony/akari akari-user-9-TAMA2-2.0.1-191021-1837-1-dev-keys
- system_dolby: https://dumps.tadiphone.dev/dumps/sony/xq-at51 qssi-user-10-58.0.A.3.31-058000A003003102854466984-release-keys

## Screenshots
- https://t.me/androidryukimodsdiscussions/144433

## Requirements
- Sound Enhancement:
  - Android 9 and up
  - Magisk installed

- Dolby Atmos:
  - Architecture 64 bit
  - Android 9 and up
  - Magisk installed (Recommended to use Magisk Delta for systemless early init mount manifest.xml if your ROM is Read-Only https://t.me/androidryukimodsdiscussions/100091)

## WARNING!!!
- Possibility of bootloop or even softbrick or a service failure on Read-Only ROM with the Dolby Atmos if you don't use Magisk Delta.

## Installation Guide & Download Link
- Recommended to use Magisk Delta if Dolby Atmos is activated https://t.me/androidryukimodsdiscussions/100091
- Don't use ACDB Magisk Module!
- Remove any other Dolby module with different name (no need to remove if it's the same name) if Dolby Atmos is activated
- Reboot
- Install this module https://www.pling.com/p/1531791/ via Magisk app or Recovery
- Install AML Magisk Module https://t.me/androidryukimodsdiscussions/29836 only if using any other audio mod module
- Disable the "No active profiles" notification and ignore it it's nothing
- Reboot
- Sound Enhancement FX now can be applied with apps that doesn't use external EQ option like YouTube and SoundCloud (except you are enabling music stream mode option) but you need to play music with an app that uses external EQ option first after device boot like Xperia Music, YouTube Music, & Spotify
- Force-stopping Sound Enhancement app (not the Sound Enhancement launcher app) causes Sound Enhancement FX failure

## Optionals & Troubleshootings
- https://t.me/androidryukimodsdiscussions/29836
- https://t.me/androidryukimodsdiscussions/60861
- https://t.me/androidryukimodsdiscussions/25187
- https://t.me/androidryukimodsdiscussions/26764

## Support & Bug Report
- https://t.me/androidryukimodsdiscussions/2618
- If you don't do above, issues will be closed immediately

## Tested on
- Android 10 CrDroid ROM
- Android 11 DotOS ROM
- Android 12 AncientOS ROM
- Android 12.1 Nusantara ROM
- Android 13 AOSP ROM

## Credits and contributors
- https://t.me/viperatmos
- https://t.me/androidryukimodsdiscussions
- You can contribute ideas about this Magisk Module here: https://t.me/androidappsportdevelopment

## Thanks for Donations
- This Magisk Module is always will be free but you can however show us that you are care by making a donations:
- https://ko-fi.com/reiryuki
- https://www.paypal.me/reiryuki
- https://t.me/androidryukimodsdiscussions/2619


