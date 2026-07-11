## 2024-05-20 - Avoiding setState in Scroll Listeners
**Learning:** Calling `setState` inside a `ScrollController` listener causes the entire widget tree to rebuild on every frame during scrolling, leading to severe performance bottlenecks and UI jank.
**Action:** Use `AnimatedBuilder` attached directly to the `ScrollController` (or `PageController`) to listen for scroll changes, and pass the static parts of the UI as the `child` parameter. This confines rebuilds only to the specific widgets that depend on the scroll offset.
