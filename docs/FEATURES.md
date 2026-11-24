# Feature map and provenance

Tinsel is an independent reimplementation. This document records what was
observed in the shipped App Store app **Deck the Desktop** 1.0
(`com.mikefifield.snow.mas`, bundle build `202610230902`, 39 MB, `LSUIElement`,
macOS 14+, native arm64/x86_64, AppKit + SwiftUI + Combine + ServiceManagement),
which is the reference for feature parity, and how each observed feature maps to
this codebase.

The observations are kept in [`evidence/`](evidence/) so the claims below can be
checked: raw `strings` output from the binary, the filtered user-facing string
inventory, a screenshot of one settings pane, and a dump of the app's saved
preferences.

## What was observed, and where

| Observation | How it was seen | Evidence |
| --- | --- | --- |
| Native universal binary, Swift 5/6, AppKit + SwiftUI, menu-bar-only (`LSUIElement`) | `file`, `otool -L`, `plutil -p Info.plist` | `evidence/README.txt` |
| Seven source files: `main`, `Decorations`, `DesktopIcons`, `SettingsArt`, `SettingsView`, `SnowController`, `SnowWorld`, plus panel/window files | Swift debug file paths in the binary | `binary-strings-raw.txt` |
| 34 Swift types: snow simulation (`SnowWorld`, `SnowScene`, `Flake`, `Drop`, `Pile`, `Chunk`, `FallingChunk`, `FallingIcicle`, `Drift`), layers (`OverlayWindow`, `SnowPanel`, `SnowPanelView`, `LayerView`), decoration system (`Decoration`, `Decorations`, `DecorationPlacer`, `PieceCarrier`, `PieceStamper`, `LightString`, `LightsEditor`, `IcicleRow`), settings (`SettingsWindow`, `SettingsView`, ten `…Pane` types, `SnowSwitch`, `SliderRow`, `ChoiceRow`, `ColorSwatches`, `PieceTray`, `EditingGuide`, `HintPanel`), storage (`LooksStore`, `SavedLook`), window tracking (`WindowTracker`, `TrackedWindow`) | Swift mangled type names in the binary | `binary-strings-raw.txt` |
| Ten settings panes in three sidebar groups: Snow (Snowfall, Piling Up, Screen Saver), Decorate (Christmas Lights, Snowmen, Christmas Tree, Decorations, Countdown Calendar), Your desktop (My Decorations, Wallpapers) | All pane titles and the appearance banner subtitle strings; pane identifiers persisted as `settingsPane` | `binary-ui-strings.txt`, `original-preferences.json`, `original-settings-snowmen.png` |
| Snowfall controls: amount, flake size, wind, "Where it falls" (behind windows / in front of everything), background snow | User-facing labels and help text | `binary-ui-strings.txt` |
| Piling controls: piles up or not, dusting vs deep, shake-to-clear, icicles, slowly/quickly | Same | `binary-ui-strings.txt` |
| Screen-saver snow: start after 1 min … 1 hour, what happens on return, darken screen, pile over the menu bar, wait while video is playing, only in winter | Same, plus `Lock Screen Settings` reference | `binary-ui-strings.txt` |
| Lights: six looks, six twinkle patterns, speed, sparse/packed, colours, strings that follow a window | Same | `binary-ui-strings.txt` |
| Snowman: snowballs stacked freely; 15 pieces (top hat, beanie, Santa hat, earmuffs, scarf, mitten, bow tie, coal, carrot, pipe, stick, broom, bucket, pinecone, rock); ready-made snowman | Same | `binary-ui-strings.txt` |
| Tree: freely hung ornaments; 18 ornament kinds; resize carries the ornaments | Same | `binary-ui-strings.txt` |
| Countdown calendar: one door per day, December gating, remembered doors, sleeps-till-Christmas message | Same | `binary-ui-strings.txt` |
| Saved looks: save/apply/rename/delete, put away / bring back, take everything down | Same | `binary-ui-strings.txt` |
| 31 wallpapers applied to every display (numbered `wallpaper-01-village` … `wallpaper-41-stockholm`) | Resource inventory, wallpaper title strings | `evidence/README.txt` |
| Decoration record shape: `kind`, `x`, `y`, `height`, `radii`, `hang`, `seed`, and `props` of `{kind, u, v, scale, angle, anchor, color}` in normalised coordinates | Saved preferences (`decorations` array) | `original-preferences.json` |
| Two overlay windows per display at window levels 18 and 19, plus one settings window | `CGWindowListCopyWindowInfo` while the app was running | `evidence/README.txt` |

Nothing above was copied: the evidence is string names, window geometry and
saved-record shapes, which describe behaviour rather than expression. The art,
the code, the icon and the name in this repository are original.

## Feature parity

| Original capability | Tinsel implementation |
| --- | --- |
| Snowfall: amount, flake size, wind | `SnowSettings`, `SnowScene` (`Snow.swift`), Snowfall pane |
| Layer behind windows or in front; quiet background snow | two overlay windows per display (`Overlay.swift`), `Layering`, `BackgroundSnow` |
| Drifts, deep drifts, dusting, pace | `SnowScene.pile`, `Depth`, `Pace` |
| Shake a window to knock snow off | `WindowTracker` motion detection → `OverlayController.shake` |
| Icicles hanging from window tops | `SnowScene.draw(icicles:)` |
| Snow caps on window tops | `SnowScene.drawCaps`, `WindowTracker` |
| Snow while away, darken screen, melt or stay, menu-bar pile, wait for video, winter only | `SaverController` (`App.swift`), Screen Saver pane |
| Six light looks, six twinkle patterns, speed, density, colours | `LightConfig`, `Lights` (`Lights.swift`), Lights pane |
| String lights on a window's top edge, following the window | `Decoration.windowPid`, `PlacementController.followWindows`, `Lights.polyline` |
| Free-standing tacked light strings | `hang == "free"` with stored points |
| Snowballs stacked as high as you like | `Decoration.radii`, `PlacementController.addBall` |
| Fifteen snowman pieces that snap to size | `Art.prop`, `Prop` records with normalised `u`/`v`, `addPiece` |
| Ready-made snowman | `SnowmenPane.putReadySnowman` |
| Put up a tree, resize it, ornaments grow with it | `Art.tree`, `PlacementController.scroll` |
| Eighteen ornament kinds, standing or hanging | `Art.ornament`, `Catalogue` |
| Drag to move, grip to resize, handle to rotate, right-click to remove, Esc/Done to finish | `PlacementController` + `PlacementView` overlay with hint bar |
| Countdown calendar with remembered doors and sleeps message | `Art.calendar`, `Advent`, `Decoration.props` "door" records |
| Wallpapers on every display | `Scenes` (31 procedural pictures), `WallpaperManager.apply` |
| Saved looks, put away/bring back, take everything down | `SavedLook`, `LooksStore` equivalent in `TinselStore`, My Decorations pane |
| Menu bar control | `StatusItemController` (`App.swift`) |
| Settings window with sidebar, banner header, help cards | `SettingsUI.swift`, `Panes.swift` |
| Decorations persisted across launches | `TinselStore` JSON snapshot in `UserDefaults` |

## Deliberate differences

* **Original art.** The reference app ships 139 bitmap resources (wallpapers,
  ornaments, snowman pieces, banners). Tinsel ships none: ornaments, pieces,
  trees, calendars, banners and 31 desktop pictures are drawn at runtime.
* **Original name, icon and identity.** Tinsel is its own app with its own
  bundle identifier and MIT licence.
* **Settings persistence format** is Tinsel's own JSON snapshot; it is not
  binary-compatible with the original's preferences, and does not try to be.
* Desktop-icon awareness (`DesktopIcons`/`IconShape` in the original, used to
  keep snow off icons) is not implemented; Tinsel's behind-windows layer simply
  renders beneath the icons.
