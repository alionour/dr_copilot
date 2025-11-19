# 🔧 Fixed: BLoC Emit After Event Handler Completed Error

## ❌ The Error

```
Unhandled Exception: 'package:bloc/src/emitter.dart': Failed assertion: line 114 pos 7: '!_isCompleted':

emit was called after an event handler completed normally. 
This is usually due to an unawaited future in an event handler.
```

## 🔍 Root Cause

The problem was in `_onWatchNotifications()`:

**Bad Pattern:**
```dart
Future<void> _onWatchNotifications(...) async {
  emit(NotificationsLoading());
  
  // ❌ This subscription outlives the event handler
  _subscription = stream.listen((data) {
    emit(newState);  // ❌ Called after handler completes!
  });
  
  // Handler completes here, but stream is still active
}
```

**Issue:** The stream subscription continues to call `emit()` even after the event handler has completed, which violates BLoC rules.

## ✅ The Fix

Use `emit.forEach()` which is the proper BLoC pattern for handling streams:

**Good Pattern:**
```dart
Future<void> _onWatchNotifications(...) async {
  emit(NotificationsLoading());
  
  // ✅ emit.forEach keeps handler alive until stream completes
  await emit.forEach<List<dynamic>>(
    stream,
    onData: (data) {
      return NewState(...);  // ✅ Safe to return states
    },
    onError: (error, stackTrace) {
      return ErrorState(...);
    },
  );
}
```

## 📝 Changes Made

### Before:
```dart
Future<void> _onWatchNotifications(...) async {
  emit(NotificationsLoading());
  
  _notificationsSubscription = useCase.watchNotifications(userId).listen(
    (result) {
      result.fold(
        (failure) => emit(NotificationsError(...)),
        (notifications) => emit(NotificationsLoaded(...)),
      );
    },
  );
  
  _unreadCountSubscription = useCase.watchUnreadCount(userId).listen(...);
}
```

### After:
```dart
Future<void> _onWatchNotifications(...) async {
  emit(NotificationsLoading());
  
  await emit.forEach<List<dynamic>>(
    useCase.watchNotifications(userId).asyncMap((notificationsResult) async {
      final unreadCountResult = await useCase.getUnreadCount(userId);
      return [notificationsResult, unreadCountResult];
    }),
    onData: (results) {
      final notificationsResult = results[0];
      final unreadCountResult = results[1];
      
      return notificationsResult.fold(
        (failure) => NotificationsError(failure.message),
        (notifications) {
          final unreadCount = unreadCountResult.fold(
            (failure) => notifications.where((n) => !n.isRead).length,
            (count) => count,
          );
          
          return NotificationsLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          );
        },
      );
    },
    onError: (error, stackTrace) => NotificationsError(error.toString()),
  );
}
```

## ✨ Benefits

1. **No more assertion errors** - `emit()` is properly managed
2. **Proper BLoC pattern** - Uses `emit.forEach()` as recommended
3. **Cleaner code** - No manual subscription management
4. **Combines streams** - Both notifications and unread count in one stream
5. **Better error handling** - Built-in error handling with `onError`

## 📚 Why `emit.forEach` Works

- Keeps event handler alive until stream completes
- Ensures `emit()` is only called when valid
- Automatically checks `emit.isDone`
- Follows official BLoC recommendations
- Prevents data loss and crashes

## 🔗 References

- [BLoC Documentation - Handling Streams](https://bloclibrary.dev/#/coreconcepts?id=bloc)
- [Flutter Platform Channels Threading](https://docs.flutter.dev/platform-integration/platform-channels#channels-and-platform-threading)

## ✅ Testing

After this fix:
1. ✅ No assertion errors
2. ✅ Notifications stream works properly
3. ✅ Real-time updates from Firestore
4. ✅ Unread count updates automatically
5. ✅ No threading warnings

---

**Status:** ✅ Fixed and tested!
