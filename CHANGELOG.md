# Changelog

## [0.6.1](https://github.com/cedricziel/trueapp/compare/v0.6.0...v0.6.1) (2026-09-05)


### Bug Fixes

* **ci:** make the macOS TestFlight lane sign and package correctly ([#163](https://github.com/cedricziel/trueapp/issues/163)) ([47ec764](https://github.com/cedricziel/trueapp/commit/47ec7642697c6d6121f53a99fc21e9b764f630c8))

## [0.6.0](https://github.com/cedricziel/trueapp/compare/v0.5.0...v0.6.0) (2026-09-05)


### Features

* add macOS TestFlight submission ([#158](https://github.com/cedricziel/trueapp/issues/158)) ([6949e3b](https://github.com/cedricziel/trueapp/commit/6949e3baf852caf39d258022e7b0bc1d93bb1e68))

## [0.5.0](https://github.com/cedricziel/trueapp/compare/v0.4.3...v0.5.0) (2026-09-05)


### Features

* evolve dashboard, pools, files, health, and home screens ([#156](https://github.com/cedricziel/trueapp/issues/156)) ([1d5a70c](https://github.com/cedricziel/trueapp/commit/1d5a70c1156a36558d371bc5992d7b61eeffb775))


### Bug Fixes

* load apps reliably over slow links and surface the real error instead of "Connection error" ([#155](https://github.com/cedricziel/trueapp/issues/155)) ([b7c97bb](https://github.com/cedricziel/trueapp/commit/b7c97bb20a84091484c8d7151c717afcb43ae3c2))

## [0.4.3](https://github.com/cedricziel/trueapp/compare/v0.4.2...v0.4.3) (2026-09-05)


### Bug Fixes

* **release:** pass OTLP secrets to the TestFlight build so telemetry is enabled ([#152](https://github.com/cedricziel/trueapp/issues/152)) ([1d93513](https://github.com/cedricziel/trueapp/commit/1d93513a05308655addedad7dc67485da2770035))

## [0.4.2](https://github.com/cedricziel/trueapp/compare/v0.4.1...v0.4.2) (2026-08-31)


### Bug Fixes

* enable automatic dark mode by following system brightness ([#150](https://github.com/cedricziel/trueapp/issues/150)) ([cdf3100](https://github.com/cedricziel/trueapp/commit/cdf31001a9d413f84c13bbf75809a40721c8ad46))

## [0.4.1](https://github.com/cedricziel/trueapp/compare/v0.4.0...v0.4.1) (2026-08-30)


### Bug Fixes

* close the AppResourceUsage.last_updated parsing gap, and extend tracing to cover it ([#146](https://github.com/cedricziel/trueapp/issues/146)) ([8e6b4e8](https://github.com/cedricziel/trueapp/commit/8e6b4e8d1bb34a03b1d52e17c392f06059cf33f9))
* coalesce concurrent connect and login attempts in TrueNasApiClient ([#147](https://github.com/cedricziel/trueapp/issues/147)) ([1a6af31](https://github.com/cedricziel/trueapp/commit/1a6af3154d6fa4a69ced0f51dee71acbdad1d53f))
* harden session recovery and close() against races found in review ([#148](https://github.com/cedricziel/trueapp/issues/148)) ([d6d20f9](https://github.com/cedricziel/trueapp/commit/d6d20f9597b7a5d53c57c47e2350a8d7dde724d2))

## [0.4.0](https://github.com/cedricziel/trueapp/compare/v0.3.0...v0.4.0) (2026-08-30)


### Features

* wire OTel tracing into TrueNasApiClient's connection flow ([#144](https://github.com/cedricziel/trueapp/issues/144)) ([6738379](https://github.com/cedricziel/trueapp/commit/6738379628d0ce6273f85a58a0052a0d9f597d6e))

## [0.3.0](https://github.com/cedricziel/trueapp/compare/v0.2.0...v0.3.0) (2026-08-30)


### Features

* consolidate loading and empty states across screens ([#141](https://github.com/cedricziel/trueapp/issues/141)) ([8e653f5](https://github.com/cedricziel/trueapp/commit/8e653f563d96f547b7de2867b1b9bd80cfd9ea0a))
* integrate flutter_otel OpenTelemetry SDK for logs ([#142](https://github.com/cedricziel/trueapp/issues/142)) ([3e8636e](https://github.com/cedricziel/trueapp/commit/3e8636e46ff4b0e783b2d8f0ee82ca92f0c95214))

## [0.2.0](https://github.com/cedricziel/trueapp/compare/v0.1.5...v0.2.0) (2026-08-30)


### Features

* add a Jobs view, nav bar job indicator, and a segmented memory bar ([#137](https://github.com/cedricziel/trueapp/issues/137)) ([7604fa7](https://github.com/cedricziel/trueapp/commit/7604fa719e0739edda4d84bd1b74a89f47d8f4fc))


### Bug Fixes

* parse App.last_update defensively instead of assuming Mongo-style JSON ([#139](https://github.com/cedricziel/trueapp/issues/139)) ([6318adc](https://github.com/cedricziel/trueapp/commit/6318adc307c68a6ad6e82765cb1dada093c29897))

## [0.1.5](https://github.com/cedricziel/trueapp/compare/v0.1.4...v0.1.5) (2026-08-30)


### Bug Fixes

* cast keychain mock arguments defensively and run package tests in CI ([#134](https://github.com/cedricziel/trueapp/issues/134)) ([c32eb70](https://github.com/cedricziel/trueapp/commit/c32eb7053cf59e39481ab7067352263b4cda2983)), closes [#105](https://github.com/cedricziel/trueapp/issues/105)
* close cached API client when a server is deleted ([#131](https://github.com/cedricziel/trueapp/issues/131)) ([9f89451](https://github.com/cedricziel/trueapp/commit/9f89451c61396f7b0dce9a4613c417a8f5fec51e))
* delete servers and Keychain passwords when clearing database ([#128](https://github.com/cedricziel/trueapp/issues/128)) ([9a80d1b](https://github.com/cedricziel/trueapp/commit/9a80d1b58b5c51270e2a1320f39fb56d52c2b599)), closes [#106](https://github.com/cedricziel/trueapp/issues/106)
* guard ServerProvider auth emit after dispose ([#133](https://github.com/cedricziel/trueapp/issues/133)) ([f6a0571](https://github.com/cedricziel/trueapp/commit/f6a05719e38ad2a18bf688df9017a92bf84a0a48))
* stop Clear Database success dialog from double-popping the router ([#129](https://github.com/cedricziel/trueapp/issues/129)) ([afb13cf](https://github.com/cedricziel/trueapp/commit/afb13cf5981e865fab641e905d7e26c1ef7b8bdf)), closes [#108](https://github.com/cedricziel/trueapp/issues/108)
* stop CompactNavigation double-counting the bottom safe-area inset ([#135](https://github.com/cedricziel/trueapp/issues/135)) ([9d953a0](https://github.com/cedricziel/trueapp/commit/9d953a041b36d62f8c885fb6747498de2b3b2c97))
* stop pinning AppProvider to a database instance closed by Clear Database ([#130](https://github.com/cedricziel/trueapp/issues/130)) ([32e43ed](https://github.com/cedricziel/trueapp/commit/32e43ed4aeb72a9904d45d6cf8ed0b50c29e0a7f)), closes [#107](https://github.com/cedricziel/trueapp/issues/107)
* unsubscribe from system stats synchronously on dispose ([#132](https://github.com/cedricziel/trueapp/issues/132)) ([9d72051](https://github.com/cedricziel/trueapp/commit/9d72051c9c4b3ff78a57d7e73ad1611caca12edb))

## [0.1.4](https://github.com/cedricziel/trueapp/compare/v0.1.3...v0.1.4) (2026-08-29)


### Bug Fixes

* reconnect and refresh when the app returns to the foreground ([#123](https://github.com/cedricziel/trueapp/issues/123)) ([b55ddba](https://github.com/cedricziel/trueapp/commit/b55ddba643dec21707a76ad5747b9d2c92ba3aba))

## [0.1.3](https://github.com/cedricziel/trueapp/compare/v0.1.2...v0.1.3) (2026-08-29)


### Bug Fixes

* **keychain:** match synchronizable items in iOS read and update queries ([#120](https://github.com/cedricziel/trueapp/issues/120)) ([37d4521](https://github.com/cedricziel/trueapp/commit/37d452159bde8a8e8ae2e03a9fc483bc487fe801))

## [0.1.2](https://github.com/cedricziel/trueapp/compare/v0.1.1...v0.1.2) (2026-08-29)


### Bug Fixes

* **test:** move the macOS floor pin to 12.0 raised by the deps bump ([#117](https://github.com/cedricziel/trueapp/issues/117)) ([64b99d1](https://github.com/cedricziel/trueapp/commit/64b99d12c4666cff8f40a198911710aa29fe01ae))

## [0.1.1](https://github.com/cedricziel/trueapp/compare/v0.1.0...v0.1.1) (2026-08-29)


### Bug Fixes

* close the [#84](https://github.com/cedricziel/trueapp/issues/84)-[#95](https://github.com/cedricziel/trueapp/issues/95) review batch - compact layout, deep-link routing, coverage ratchet and hygiene ([#114](https://github.com/cedricziel/trueapp/issues/114)) ([c15b6e9](https://github.com/cedricziel/trueapp/commit/c15b6e9bc9dab7d4b4c2c2e5fbbe0b04f027cc23)), closes [#85](https://github.com/cedricziel/trueapp/issues/85) [#86](https://github.com/cedricziel/trueapp/issues/86) [#87](https://github.com/cedricziel/trueapp/issues/87) [#88](https://github.com/cedricziel/trueapp/issues/88) [#89](https://github.com/cedricziel/trueapp/issues/89) [#90](https://github.com/cedricziel/trueapp/issues/90) [#91](https://github.com/cedricziel/trueapp/issues/91) [#92](https://github.com/cedricziel/trueapp/issues/92) [#93](https://github.com/cedricziel/trueapp/issues/93) [#110](https://github.com/cedricziel/trueapp/issues/110)

## [0.1.0](https://github.com/cedricziel/trueapp/compare/v0.0.1...v0.1.0) (2026-08-29)


### Features

* add AGPL-3.0 license to project ([#14](https://github.com/cedricziel/trueapp/issues/14)) ([de85d6a](https://github.com/cedricziel/trueapp/commit/de85d6ab803d6a21499ccfa09bd80a1c50866774))
* add CODEOWNERS file to replace Dependabot reviewers configuration ([#12](https://github.com/cedricziel/trueapp/issues/12)) ([fb3155e](https://github.com/cedricziel/trueapp/commit/fb3155e50565d7be6b4d56861019bb06cab34797))
* add comprehensive apps summary card to server detail screen ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* add configurable default server for automatic selection on app launch ([#32](https://github.com/cedricziel/trueapp/issues/32)) ([79926b2](https://github.com/cedricziel/trueapp/commit/79926b211d531f73c86d31b9d8877ce2de7e9060)), closes [#11](https://github.com/cedricziel/trueapp/issues/11)
* add JSON-RPC keepalive mechanism with ping/pong ([#34](https://github.com/cedricziel/trueapp/issues/34)) ([0a4f7df](https://github.com/cedricziel/trueapp/commit/0a4f7df7478eb93947bfee97f248677244199ad9))
* add local app configuration with public URL navigation ([#43](https://github.com/cedricziel/trueapp/issues/43)) ([46ebdea](https://github.com/cedricziel/trueapp/commit/46ebdea243acf27e0ddda04cdf4a31f417ff08f9))
* add local URL support for WiFi connections ([#18](https://github.com/cedricziel/trueapp/issues/18)) ([d20aa69](https://github.com/cedricziel/trueapp/commit/d20aa69f68179fa983fc4e8706e94dc59a1ea8bd))
* add macOS menu bar/system tray support with custom NAS icons ([#37](https://github.com/cedricziel/trueapp/issues/37)) ([39e57ea](https://github.com/cedricziel/trueapp/commit/39e57eaa28d474dd835b48bccf81fc0343dd85f8))
* add port and portal information to installed apps ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* add real-time app resource usage monitoring with persistent state ([#45](https://github.com/cedricziel/trueapp/issues/45)) ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* add sorting and new filters to apps list ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* add TrueNAS apps display section to server details screen ([#24](https://github.com/cedricziel/trueapp/issues/24)) ([1b14afa](https://github.com/cedricziel/trueapp/commit/1b14afa4db141fc840bffcb8acd9082bf39cb22a))
* enhance AppCardWidget with comprehensive app information ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* extract CloudKit and Keychain plugins into reusable package ([#53](https://github.com/cedricziel/trueapp/issues/53)) ([54f2400](https://github.com/cedricziel/trueapp/commit/54f2400141d96a6bf9638e4d1ddb22366e0df18a))
* implement adaptive Cupertino sidebar navigation ([#55](https://github.com/cedricziel/trueapp/issues/55)) ([399099b](https://github.com/cedricziel/trueapp/commit/399099bae891f513516bf56e15494140ac337c50))
* implement centralized API client management to optimize connections ([#33](https://github.com/cedricziel/trueapp/issues/33)) ([30e7357](https://github.com/cedricziel/trueapp/commit/30e7357f3c1eddbd1b6263057aa4f1184c5a3007))
* implement favorites functionality for apps ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* implement secure credential storage with biometric authentication ([#38](https://github.com/cedricziel/trueapp/issues/38)) ([d1bc1c8](https://github.com/cedricziel/trueapp/commit/d1bc1c81f751058173e348d4100b9863d0482f3a))
* initial commit for TrueNAS Manager Flutter app ([536c0dc](https://github.com/cedricziel/trueapp/commit/536c0dca38fb7a4543a7a4a7fe3a0ff0aa389c4c))
* integrate custom URLs and display names from app configuration ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* integrate JSON-RPC client for TrueNAS Scale API ([#8](https://github.com/cedricziel/trueapp/issues/8)) ([0495c9c](https://github.com/cedricziel/trueapp/commit/0495c9cc340b43efa13efc925d7ad9f519eb3f51))
* persist portal URLs and add system tray quick access menu ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* setup CI/CD pipeline with GitHub Actions ([#10](https://github.com/cedricziel/trueapp/issues/10)) ([2dce335](https://github.com/cedricziel/trueapp/commit/2dce3351a8e2eeed62bd12217fb9637d2616089f))
* show instance names for installed apps in effectiveDisplayName ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* unify app list and app configs with offline persistence ([#47](https://github.com/cedricziel/trueapp/issues/47)) ([9e3db5d](https://github.com/cedricziel/trueapp/commit/9e3db5d3978d25419eae65138089fa611bcbbaa9))


### Bug Fixes

* address release-pipeline review findings from [#99](https://github.com/cedricziel/trueapp/issues/99) ([#101](https://github.com/cedricziel/trueapp/issues/101)) ([674c434](https://github.com/cedricziel/trueapp/commit/674c434cc69d3562704d1582d7c7e4a2ddd0164e))
* get CI back to green, refresh dependencies and docs ([#83](https://github.com/cedricziel/trueapp/issues/83)) ([67d0dbe](https://github.com/cedricziel/trueapp/commit/67d0dbe808552f995c83659d58557c6d3b9d7478))
* remove temporary exceptions ([#49](https://github.com/cedricziel/trueapp/issues/49)) ([efe86a2](https://github.com/cedricziel/trueapp/commit/efe86a2788cf2b229e1cf5d195243cf50012fcfb))
* remove temporary exceptions ([#50](https://github.com/cedricziel/trueapp/issues/50)) ([9943a97](https://github.com/cedricziel/trueapp/commit/9943a97b2cfb5e4abe191a619f0d59b791be1cdf))
* resolve dart analyze issues and enable tray portal URL functionality ([5a11fdd](https://github.com/cedricziel/trueapp/commit/5a11fdd7e225b09a5deb3178fea7e1cb507c8d44))
* resolve failing integration and local URL tests ([#23](https://github.com/cedricziel/trueapp/issues/23)) ([eecfc56](https://github.com/cedricziel/trueapp/commit/eecfc56c9d5a86ad2bc1dc1b03a90c6ff405e067))
