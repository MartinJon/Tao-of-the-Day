# Store setup for Tao of the Day

The free trial now belongs to the stores. The app shows a trial only when the store
confirms one for that user, so the steps below decide what users see.

## 1. Before the first build
- Install Flutter 3.38 or later. Codemagic is pinned to 3.38.10.
- Run `flutter pub get` and commit the updated `pubspec.lock`. It still lists Billing Library 7.
  `flutter pub get` replaces it with Billing Library 8 or later.
- Copy `android/key.properties.example` to `android/key.properties` and fill it in for local builds.
- Reset the upload key: the old password stays in public git history. Play Console >
  Test and release > App integrity > App signing > Request upload key reset.
  Then update `android/app/upload-keystore.jks`, `key.properties`, and Codemagic's `android_signing` group.

## 2. Google Play Console
Monetize > Products > Subscriptions > `tao_subscription_monthly`
- Confirm an active monthly base plan with auto-renewal.
- Add an offer on that base plan with eligibility set to "New customer acquisition",
  one free phase of 3 days. Activate it. Play shows this offer only to eligible users.
- App content > Data safety: declare purchase history handling only as your payment flow requires,
  and make the answers match the privacy policy.
- If the account is personal and was created after Nov 13, 2023, confirm production access:
  12 testers opted in for 14 straight days.

## 3. App Store Connect
Monetization > Subscriptions > `tao_subscription_monthly`
- Add a 3-day free Introductory Offer for all territories you sell in.
- Complete the display name, description, review screenshot, and price.
- Attach the subscription to the app version on the version page before you submit it.
- Add the Terms link to the app description or the EULA field. Add the Privacy Policy URL.
- App Privacy: make the answers match the privacy policy.
- iPad is enabled, so iPad screenshots are required.

## 4. Website
Update https://www.martinjon.com/tao-app-privacy to match the in-app policy: stored subscription status,
payments handled by Apple or Google, and audio streamed from Google Cloud Storage.
Publish the Terms at a URL for the store listings.

## 5. Notes for app review
Paste this into the App Store review notes and Play's app access section:

> A new user's first chapter is free. To reach the subscription screen on the first day, open the
> top-right menu and choose Go Premium. From the next day, the app opens on that screen.
> Subscribing starts a 3-day free trial through the store. Restore Purchases is on the same screen.
> No app account is needed. Google Play reviewers can unlock the app without payment: on that
> screen, tap Access Code and enter the code in the Sign in details declaration. One new chapter
> a day is the app's intended design, including with the code.
>
> Keep the code only in Play Console. The repository stores just its hash.

Add license testers in Play Console > Settings > License testing.

## 6. Test on real devices
- New user: the app opens without a paywall, and the first chapter opens in full.
- Reopen the same day: the same chapter opens.
- Next day, or with the phone's date moved forward: the paywall shows the 3-day trial and price, and purchase enters the app.
- Cancel the purchase sheet: the spinner stops and no error appears.
- Restore on a second device or after reinstalling.
- Expire a test subscription: the next launch shows the paywall.
- Launch offline as a subscriber: the app opens.
- iPhone: audio keeps playing with the screen locked and with the silent switch on.
- Terms of Use and Privacy Policy both open from the paywall.
- About screen: tapping the version does nothing in a release build.
