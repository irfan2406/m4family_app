# Changelog

All notable changes to the M4 Family app are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Production config: release signing wiring (`android/key.properties`), R8/ProGuard
  rules, network-security & backup rules, iOS photo/camera usage descriptions.
- `.env.example`, `key.properties.example`, README, LICENSE.

### Changed
- App launch: removed the blocking secure-storage read from `main()`, faster
  splash logo, branded native launch screen (logo on black).

## [1.0.0] - Initial

- First internal build: Guest / Customer / CP / Investor portals, project
  catalog, bookings, lead capture, construction progress, and profile flows.
