## 2026-04-30 - Prevent PageView setState on every scroll frame
**Learning:** Adding a listener to a `PageController` that triggers `setState` on every frame causes massive performance bottlenecks by rebuilding the entire widget tree during the swipe animation. This is a common Flutter anti-pattern.
**Action:** Use `AnimatedBuilder` with the `PageController` as the animation, and pass the heavy `PageView` inside the `child` parameter. This isolates the frame-by-frame rebuilds to just the parts that actually need it (like background color and page indicators).
