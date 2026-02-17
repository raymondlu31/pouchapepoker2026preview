# pouchapepoker2026preview - Design Doc

## 袋猿扑克2026预览版


## Project Overview

Pouch Ape Poker 2026 preview is a poker intuition training game developed using Flutter, incorporating the philosophical ideas of the Chinese I Ching. The game trains players' probabilistic intuition and decision-making abilities through 27 rounds of card comparison, while also integrating game results with the Eight Trigrams (8 Gua) and the Sixty-Four Hexagrams (64 Gua) to provide players with a deeper gaming experience.

### Core Features

- **Probability Training Game**: Trains players' probabilistic intuition by comparing the value of playing cards.

- **I Ching Integration**: Maps game results to the Bagua and Sixty-Four Hexagrams system.

- **Multi-Platform Support**: Supports Windows, macOS, Linux, Android, iOS, and Web.

- **Detailed Statistics**: Provides game statistics and performance analysis.

- **Configurable Options**: Supports countdown timers, warnings, detailed logs, and other features.

### Technology Stack

- **Framework**: Flutter (Dart 3.9.2+)

- **UI Design**: Material Design 3

- **Architectural Pattern**: MVC (Model-View-Controller)

- **State Management**: Stream-based State Management

## Project Structure

```
lib/
├── main.dart # Application Entry Point
├── game_manager.dart # Core Game Manager
├── core/ # Core Data Model
│ ├── models/ # Data Model
│ │ ├── card_model.dart # Poker Card Model
│ │ ├── game_state.dart # Game State Enumeration
│ │ ├── user_guess.dart # User Guess Options
│ │ ├── flag_options.dart # Game Configuration Options
│ │ ├── round_info.dart # Round Information
│ │ ├── score_entry.dart # Score Record
│ │ └── stage_model.dart # Stage/Hexagram Model
│ └── data/ # Static Data
│ ├── 8gua_data.dart # Bagua Data
│ └── 64gua_data.dart # Sixty-four hexagrams data
├── helper/ # Auxiliary tools
│ ├── probability_calculator.dart # Probability calculator
│ ├── score_calculator.dart # Score calculator
│ ├── statistics_reporter.dart # Statistics report generator
│ ├── timer_helper.dart # Timer helper
│ ├── verbose_game_logger.dart # Detailed game log
│ ├── ui_debug_logger.dart # UI debug log
│ ├── message_order.dart # Message order management
│ └── round_probability_data.dart # Round probability data
└── ui/ # User interface
├── screens/ # Screen components
│ └── poker_game_screen.dart # Main Game Screen
├── widgets/ # Custom Components
│ ├── card_widget.dart # Playing Card Component
│ ├── countdown_timer_widget.dart # Countdown Timer Component
│ ├── game_buttons.dart # Game Buttons
│ └── dialogs/ # Dialog Boxes
│ ├── game_options_dialog.dart
│ └── message_dialogs.dart
└── styles/ # Style Definitions
└── game_colors.dart # Game Color Scheme

```

## Building and Running

### Prerequisites

- Flutter SDK 3.9.2 or later

- Dart SDK 3.9.2 or later

- Configure the appropriate development environment (Android Studio, Xcode, etc.) according to the target platform.

### Running the Application

```bash

# Check Flutter Environment

flutter doctor

# Get Dependencies

flutter pub get

# Run the Application (select based on target platform)

flutter run # Default platform

flutter run -d windows # Windows

flutter run -d macos # macOS

flutter run -d linux # Linux

flutter run -d chrome # Web

flutter run -d android # Android

flutter run -d ios # iOS

```

### Build release version

```bash
#Windows
flutter build windows --release

#macOS
flutter build macos --release

#Linux
flutter build linux --release

#Android
flutter build apk --release
flutter build appbundle --release

#iOS
flutter build ios --release

#Web
flutter build web --release
```

### Running Tests

```bash

# Run all tests

flutter test

# Run a specific test file

flutter test test/widget_test.dart

flutter test test/helper/probability_calculator_test.dart

flutter test test/helper/score_calculator_test.dart

```

### Code Inspection

```bash

# Run Flutter static analysis

flutter analyze

# Run code formatting

flutter format .

```

## Development Conventions

### Code Style

- **Dart Code**: Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

- **Naming Conventions**:

- Class names: PascalCase (e.g., `CardModel`)

- Variables and methods: camelCase (e.g., `calculateScore`)

- Constants: lowerCamelCase or UPPER_CASE (e.g., `maxScore`)

- Private members: Prefixed underscore (e.g., `_currentState`)

- **Formatting**: Use `flutter format` for automatic formatting.

- **Comments**: Use `///` for documentation comments, and use concise inline comments in the code.

### Architecture Patterns

The project uses the MVC architecture pattern:

- **Model**: `lib/core/models/` - Data model definition

- **View**: `lib/ui/` - UI components and screens

- **Controller**: `lib/game_manager.dart` - Game logic controller

### State Management

- State management using Streams

- Main state stream: `GameManager.stateStream`

- Dialog stream: `GameManager.dialogSequenceStream`

- Hint stream: `GameManager.hintStream`


### Testing Conventions

- Unit tests should be placed in the `test/` directory.

- Test file naming: `*_test.dart`

- Use the `flutter_test` package for testing.

- Write unit tests for critical logic (probability calculation, score calculation, etc.).

### Resource Management

- Image resources: `assets/images/cards/`

- Sound resources: `assets/sounds/`

- Resources are declared in `pubspec.yaml`.

### Logging System

The project provides two logging systems:

1. **Detailed Game Log** (`VerboseGameLogger`):

- Records game flow, user actions, probability calculations, etc.

- Enabled via `FlagOptions.verboseLogMode`

- Supports exporting to JSON files

2. **UI Debug Log** (`UIDebugLogger`):

- Records UI builds, state changes, user gestures, etc.

- Used for debugging UI issues

- Enabled via `FlagOptions.verboseLogMode`

### Game Flow

1. **Initialization**: Display instructions and options

2. **New Game**: Create deck, shuffle

3. **Round Cycle** (27 rounds):

- Deal cards (computer cards and player cards)

- Calculate probabilities

- Player guesses (Higher/Tie/Lower)

- Reveal player cards

- Calculate score

- Display results and warnings (if any)

4. **Game Over**: Display statistics report and final score

### Probability System

The game uses a 54-card deck (52 regular cards + 2 Jokers):

- **Higher**: Player's card is higher than the computer's card.

- **Tie**: Player's card is equal to the computer's card (excluding Jokers).

- **Lower**: Player's card is lower than the computer's card.

Probability calculations consider:

- Revealed cards

- Remaining cards in the deck

- Special rules for Jokers

### I Ching Integration

- Each stage (3 rounds) corresponds to one Bagua (8 Gua)

- Each stack (6 rounds) corresponds to one Liushisi Gua (64 Gua)

- The last 3 rounds (Stage I) are independent and do not form a complete stack

- Round results (win/lose) are mapped to Yin and Yang (1/0)

- Binary sequences are read from bottom to top


## Key File Descriptions

### Core Files

- `lib/game_manager.dart`: The core game controller, managing all game logic and states.

- `lib/core/models/card_model.dart`: The poker card model and deck management.

- `lib/helper/probability_calculator.dart`: The core logic for probability calculation.

- `lib/helper/score_calculator.dart`: The logic for score calculation and alerts.

- `lib/ui/screens/poker_game_screen.dart`: The main game interface.

### Configuration Files

- `pubspec.yaml`: Project dependencies and resource configuration

- `analysis_options.yaml`: Code analysis rules

### Test Files

- `test/widget_test.dart`: Widget test

- `test/helper/probability_calculator_test.dart`: Probability calculator test

- `test/helper/score_calculator_test.dart`: Score calculator test

## Development Considerations

1. **State Consistency**: Ensure consistency in game state transitions to avoid state conflicts.

2. **Probability Accuracy**: All probability calculations must be verified.

3. **UI Responsiveness**: Use StreamBuilder to ensure the UI responds promptly to state changes.

4. **Resource Paths**: Use relative paths to reference resources to ensure cross-platform compatibility.

5. **Log Performance**: Detailed logging should be disabled in production environments to improve performance.

6. **Platform Differences**: Be aware of differences in UI layout and interaction across different platforms.

## Frequently Asked Questions

### How to Enable Verbal Logs?

Enable `verboseLogMode` in the game options, or set it in code:

```dart
gameOptions.verboseLogMode = true;

```

### How to Add New Game Options?

1. Add a new field in `lib/core/models/flag_options.dart`

2. Add a UI control in `lib/ui/widgets/dialogs/game_options_dialog.dart`

3. Implement the corresponding logic in `GameManager`

### How to Modify Game Rules?

Mainly modify the following files:

- `lib/helper/probability_calculator.dart`: Probability calculation rules

- `lib/helper/score_calculator.dart`: Score calculation rules

- `lib/game_manager.dart`: Game flow control

### How to Add New Visual Effects?

1. Create a new widget in `lib/ui/widgets/`

2. Integrate it in `lib/ui/screens/poker_game_screen.dart`

3. Define styles in `lib/ui/styles/`

## Contribution Guidelines

1. Follow existing coding styles and architectural patterns.

2. Write tests for new features.

3. Update relevant documentation.

4. Run `flutter analyze` to ensure code quality.

5. Run `flutter test` before committing to ensure all tests pass.

## License

Please refer to the LICENSE file.




