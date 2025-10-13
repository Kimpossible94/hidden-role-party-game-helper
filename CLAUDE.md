# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application for "Hidden Role Party Game Helper" - a party game companion app that helps moderate hidden role games. The app manages game sessions, player roles, room assignments, and round timers.

## Development Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run the app
flutter run -d macos --debug  # For macOS
flutter run -d chrome --debug  # For web

# Code analysis and formatting
flutter analyze
flutter test

# Hot reload during development
# Press 'r' in the Flutter terminal for hot reload
# Press 'R' in the Flutter terminal for hot restart
```

## Architecture Overview

### Core Game Flow
1. **Host creates game** → Generates game ID and settings with per-round time configuration
2. **Players join** → Auto-assigned to rooms with balanced distribution
3. **Game starts** → Teams and roles randomly assigned via `GameService._assignTeamsAndRoles()`
4. **Round management** → Host controls round timing, player room movements via drag-and-drop
5. **Victory conditions** → Determined by final positions of Bomber and President

### Key Architecture Components

**State Management Pattern:**
- Singleton `GameService` manages all game state in memory (`Map<String, Game> _games`)
- No external database - all data is ephemeral per session
- Timer-based state updates for round progression

**Game Models (lib/models/):**
- `GameSettings`: Supports per-round time configuration via `roundDurationsMinutes` array
- `Game`: Central state container with round management and victory logic
- `Player`: Contains team, role, and room assignments with extension methods for display

**Screen Architecture:**
- `HomeScreen`: Entry point with 2 modes (Create/Join)
- `HostScreen`: Real-time game management with drag-and-drop room switching
- `ParticipantScreen`: Privacy-focused black screen with hidden role reveals

**Role Assignment Logic:**
- Basic games (< 6 players): Simple Bomber vs President
- Extended games (6+ players): Full role set including Doctor, Engineer, Hot Potato, etc.
- Team balance maintained through `Role.defaultTeam` mapping

### Critical Implementation Details

**Timer Management:**
- `Game.startRound()` uses `GameSettings.getDurationForRound(currentRound)` for per-round timing
- Host screen updates every second via `Timer.periodic` for real-time countdown
- Round transitions handled automatically when time expires

**Drag-and-Drop System:**
- `RoomContainer` uses `DragTarget<Player>` with updated `onAcceptWithDetails` API
- `DraggablePlayerCard` provides visual feedback during drag operations
- Host can move players between rooms during break periods

**Privacy Design:**
- Participant screen defaults to black background to prevent role leaking
- Team/Role reveals require explicit button presses with full-screen modals
- Role information includes descriptions and team-colored UI elements


### Game State Transitions

```
GameState.waiting → GameState.starting → GameState.inProgress
     ↓                    ↓                      ↓
GameState.break_ ← GameState.break_ ← GameState.finished
     ↑                                          ↓
     └── (if more rounds) ←←←←←←←←←←←← Victory Calculation
```

## File Structure Notes

- **lib/screens/**: UI screens following Flutter navigation patterns
- **lib/models/**: Core data models with JSON serialization support
- **lib/services/**: Business logic layer (singleton GameService)
- **lib/widgets/**: Reusable UI components for drag-and-drop functionality

## Testing Strategy

For development testing, multiple devices or browser tabs are needed to simulate real multiplayer scenarios. The app's real-time Firebase synchronization requires actual multiple clients to test properly.