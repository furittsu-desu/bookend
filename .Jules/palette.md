## 2024-05-18 - Added Semantics and InkWell to Emoji Picker Buttons
**Learning:** Pure text emojis used as buttons inside custom dialogs lack proper interaction feedback (like a ripple) and screen-reader semantics by default if wrapped only in `GestureDetector` and `Container`. Users with screen readers would have no context that the emoji is a selectable button.
**Action:** When creating raw text-based or icon-based buttons that don't use standard Material Button widgets, always wrap them in `Semantics(button: true, label: ...)` and use `InkWell` inside a transparent `Material` widget to provide both visual and accessible interaction feedback.

## 2024-05-02 - Add Semantics to AnimatedTaskTile Custom Toggle
**Learning:** In Flutter, custom interactive toggle widgets (e.g., InkWell inside AnimatedTaskTile) must be explicitly wrapped in a Semantics widget with `checked` and `button` properties enabled for proper screen reader behavior. The visual children (like Row) should also be wrapped in `ExcludeSemantics` to prevent redundant or noisy screen reader readouts.
**Action:** When creating or modifying custom interactive elements (especially toggles/checkboxes), always apply Semantics wrapping the interactive zone and ExcludeSemantics around the visual children.
