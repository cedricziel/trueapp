# Changelog

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
