````markdown
# Flutter Floating Bubble (Messenger-Style Chat Head)

A **floating, draggable, minimizable bubble UI** in Flutter, designed to be **multi–state management compatible** (Provider, Riverpod, GetX, BLoC).

---

## 1. Requirements

We want a component that:
- ✅ Can **minimize** into a circle.
- ✅ Can **expand** into a panel (e.g., chat box).
- ✅ Can be **dragged** freely across the screen.
- ✅ Works **globally** across the app (via `OverlayEntry`).
- ✅ Supports **multiple state management approaches**.

---

## 2. Core Design

### 2.1 Interface (Neutral Contract)

```dart
abstract class IBubbleController with ChangeNotifier {
  Offset get position;
  bool get minimized;

  void toggle();
  void updatePosition(Offset delta);
}
````

This **abstract contract** makes the UI independent of specific state management.

---

### 2.2 Bubble Widget (UI-Only)

```dart
import 'package:flutter/material.dart';

class BubbleWidget extends StatelessWidget {
  final IBubbleController controller;

  const BubbleWidget({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Positioned(
          left: controller.position.dx,
          top: controller.position.dy,
          child: GestureDetector(
            onPanUpdate: (details) => controller.updatePosition(details.delta),
            onTap: controller.toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: controller.minimized ? 60 : 200,
              height: controller.minimized ? 60 : 250,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(
                  controller.minimized ? 30 : 16,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: controller.minimized
                  ? const Icon(Icons.chat, color: Colors.white)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Expanded Content",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: controller.toggle,
                          child: const Text("Minimize"),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
```

---

### 2.3 Overlay Service (Global Bubble)

```dart
class BubbleOverlay {
  OverlayEntry? _entry;

  void show(BuildContext context, IBubbleController controller) {
    if (_entry != null) return;

    _entry = OverlayEntry(
      builder: (_) => BubbleWidget(controller: controller),
    );

    Overlay.of(context).insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}
```

---

## 3. State Management Implementations

### 3.1 Provider

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProviderBubbleController extends ChangeNotifier implements IBubbleController {
  Offset _position = const Offset(100, 300);
  bool _minimized = true;

  @override
  Offset get position => _position;

  @override
  bool get minimized => _minimized;

  @override
  void toggle() {
    _minimized = !_minimized;
    notifyListeners();
  }

  @override
  void updatePosition(Offset delta) {
    _position += delta;
    notifyListeners();
  }
}

// Usage
ChangeNotifierProvider(
  create: (_) => ProviderBubbleController(),
  child: Consumer<ProviderBubbleController>(
    builder: (context, ctrl, _) => BubbleWidget(controller: ctrl),
  ),
)
```

---

### 3.2 Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodBubbleController extends ChangeNotifier implements IBubbleController {
  Offset _position = const Offset(100, 300);
  bool _minimized = true;

  @override
  Offset get position => _position;

  @override
  bool get minimized => _minimized;

  @override
  void toggle() {
    _minimized = !_minimized;
    notifyListeners();
  }

  @override
  void updatePosition(Offset delta) {
    _position += delta;
    notifyListeners();
  }
}

final bubbleProvider = ChangeNotifierProvider<RiverpodBubbleController>((ref) {
  return RiverpodBubbleController();
});

// Usage
Consumer(
  builder: (context, ref, _) {
    final ctrl = ref.watch(bubbleProvider);
    return BubbleWidget(controller: ctrl);
  },
);
```

---

### 3.3 GetX

```dart
import 'package:get/get.dart';

class GetBubbleController extends GetxController implements IBubbleController {
  var _position = const Offset(100, 300).obs;
  var _minimized = true.obs;

  @override
  Offset get position => _position.value;

  @override
  bool get minimized => _minimized.value;

  @override
  void toggle() => _minimized.value = !_minimized.value;

  @override
  void updatePosition(Offset delta) => _position.value += delta;
}

// Usage
GetBuilder<GetBubbleController>(
  init: GetBubbleController(),
  builder: (ctrl) => BubbleWidget(controller: ctrl),
);
```

---

### 3.4 BLoC

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class BubbleState {
  final Offset position;
  final bool minimized;

  BubbleState({required this.position, required this.minimized});

  BubbleState copyWith({Offset? position, bool? minimized}) {
    return BubbleState(
      position: position ?? this.position,
      minimized: minimized ?? this.minimized,
    );
  }
}

abstract class BubbleEvent {}
class ToggleBubble extends BubbleEvent {}
class MoveBubble extends BubbleEvent {
  final Offset delta;
  MoveBubble(this.delta);
}

class BubbleBloc extends Bloc<BubbleEvent, BubbleState> implements IBubbleController {
  BubbleBloc() : super(BubbleState(position: const Offset(100, 300), minimized: true));

  @override
  Stream<BubbleState> mapEventToState(BubbleEvent event) async* {
    if (event is ToggleBubble) {
      yield state.copyWith(minimized: !state.minimized);
    } else if (event is MoveBubble) {
      yield state.copyWith(position: state.position + event.delta);
    }
  }

  // IBubbleController methods
  @override
  Offset get position => state.position;

  @override
  bool get minimized => state.minimized;

  @override
  void toggle() => add(ToggleBubble());

  @override
  void updatePosition(Offset delta) => add(MoveBubble(delta));
}

// Usage
BlocBuilder<BubbleBloc, BubbleState>(
  builder: (context, state) {
    final ctrl = context.read<BubbleBloc>();
    return BubbleWidget(controller: ctrl);
  },
);
```

---

## 4. Enhancements

* **Snap to edge** → After drag, animate bubble to nearest screen edge.
* **Bounds checking** → Prevent bubble from going off-screen.
* **Persistence** → Save last bubble position via `SharedPreferences`.
* **Lifecycle** → Hide bubble when navigating to certain screens.

---

## 5. Packages to Explore

* [`flutter_floating`](https://pub.dev/packages/flutter_floating) → Floating widgets.
* [`overlay_support`](https://pub.dev/packages/overlay_support) → Easy global overlays.
* Or wrap this into your own **reusable package**.

---

## 6. Summary

* Define a neutral `IBubbleController` contract.
* Build a pure `BubbleWidget` UI on top.
* Implement controller with any state management:

  * Provider
  * Riverpod
  * GetX
  * BLoC
* Use `OverlayEntry` for global, app-wide floating bubbles.

This makes the bubble **scalable, reusable, and AI-agent friendly** across multiple architectures.

---

```
```
