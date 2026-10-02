# TrueHub Privacy Policy

TrueHub (TrueNAS Manager) does not sell, share or advertise with your data.

- No accounts with us, no advertising identifiers, no third-party analytics.
- The app talks to the TrueNAS servers you add yourself, using the address and
  credentials you enter. Data shown in the app, such as system health, pools,
  datasets, files and installed apps, comes from those servers and stays
  between your device and them.
- Passwords and API keys are stored in your device's system keychain and are
  sent only to the server they belong to. The keychain entries sync between
  your devices through iCloud Keychain, end-to-end encrypted by Apple.
- Server details other than credentials, such as name, address and username,
  sync between your devices through your private iCloud account (CloudKit).
  Apple's privacy policy covers that storage.
- Builds distributed through TestFlight and the App Store send diagnostic
  telemetry to a monitoring service operated by the developer: error messages
  and stack traces, and the timing and outcome of requests the app makes to
  your servers. Before anything is sent, the app removes passwords, API
  keys, access tokens and credentials embedded in addresses. Error messages
  can still include details such as a server's address or a message your
  server returned. File contents are never sent. Telemetry is used only to
  find and fix bugs.

If you have questions, open an issue at
https://github.com/cedricziel/trueapp/issues or write to
mail@cedric-ziel.com.
