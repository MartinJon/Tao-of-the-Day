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

> The app opens on a subscription screen. Subscribing starts a 3-day free trial through the store.
> A sandbox or license-test account can complete the purchase, and no app account is needed.
> Restore Purchases is on the same screen.

Add license testers in Play Console > Settings > License testing.

## 6. Test on real devices
- New user: paywall shows the 3-day trial and price, purchase enters the app with the welcome message.
- Cancel the purchase sheet: the spinner stops and no error appears.
- Restore on a second device or after reinstalling.
- Expire a test subscription: the next launch shows the paywall.
- Launch offline as a subscriber: the app opens.
- iPhone: audio keeps playing with the screen locked and with the silent switch on.
- Terms of Use and Privacy Policy both open from the paywall.
- About screen: tapping the version does nothing in a release build.
