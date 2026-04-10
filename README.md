# eventbridge

## Product Documentation

- EventBridge user flow and product rules: `docs/eventbridge_user_flow.md`

## Architecture

The app is organized by feature and follows a clean-architecture direction:

- `presentation`:
	- UI screens, widgets, state controllers, and Riverpod providers
	- depends on use cases, not concrete data classes
- `domain`:
	- repository contracts (abstractions)
	- use cases containing feature actions
	- no Flutter or infrastructure dependencies
- `data`:
	- concrete repository implementations
	- API/storage integrations
	- implements domain contracts

Current clean-architecture baseline is implemented for:

- `features/auth`
- `features/matching`

Dependency rule:

- `presentation -> domain`
- `data -> domain`
- `presentation` should not directly depend on concrete data implementations

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
