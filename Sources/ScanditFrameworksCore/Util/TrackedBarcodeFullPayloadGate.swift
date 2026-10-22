/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2026- Scandit AG. All rights reserved.
 */

import Foundation

/// Tracks, per tracked-barcode identifier, whether the full TrackedBarcode payload has already
/// been emitted at least once.
///
/// The BarcodeBatch advanced-overlay listeners (view/anchor/offset/tap) are re-asked by the
/// native layer at camera frame rate for the same identifier, but the full ~1.1 KB
/// `TrackedBarcode` JSON is only needed once per (identifier, tracking lifetime): everything a
/// listener needs on a repeat ask is the identifier plus the current-frame location. Callers
/// consult `shouldEmitFull` to decide which payload shape to build for a given identifier.
///
/// Bounded with a simple LRU eviction at `maxSize` entries, since tracked identifiers accumulate
/// over the lifetime of a scanning session and would otherwise grow unbounded.
///
/// This gate never caches serialized JSON or `TrackedBarcode` instances themselves - only the
/// boolean "was the full payload already sent" fact. `TrackedBarcode` content mutates every
/// frame, so caching bytes/instances keyed by identifier would serve stale data (see SDC-32033).
///
/// Not thread-safe by design: every mutation site runs on the main thread — the advanced
/// overlay's view/anchor/offset delegate callbacks are main-thread by UIKit necessity (the
/// native overlay asserts `NSThread.isMainThread` before asking, see
/// SDCBarcodeBatchAdvancedOverlayDrawing.mm), and the tap handlers are gesture callbacks.
public class TrackedBarcodeFullPayloadGate {
    public static let defaultMaxSize = 256

    private let maxSize: Int

    // Oldest-first insertion/access order, kept in sync with `sentIdentifiers`.
    private var order: [Int] = []
    private var sentIdentifiers: Set<Int> = []

    public init(maxSize: Int = TrackedBarcodeFullPayloadGate.defaultMaxSize) {
        self.maxSize = maxSize
    }

    /// Returns whether the caller should emit the full TrackedBarcode payload for `identifier`.
    ///
    /// Returns `true` (and records the identifier) the first time it is called for a given
    /// `identifier`; returns `false` on every subsequent call for the same identifier, until
    /// that identifier is evicted by the `maxSize` LRU bound, at which point it is treated as
    /// new again.
    public func shouldEmitFull(identifier: Int) -> Bool {
        if sentIdentifiers.contains(identifier) {
            touch(identifier)
            return false
        }
        sentIdentifiers.insert(identifier)
        order.append(identifier)
        evictIfNeeded()
        return true
    }

    /// Clears all recorded state, so every identifier is treated as new again. Callers should
    /// reset whenever the listener registration on the other side of the bridge resets (fresh
    /// JS/Dart side subscribing, overlay recreation, module teardown) so a fresh consumer always
    /// receives full payloads first instead of inheriting gate state from a previous session.
    public func reset() {
        sentIdentifiers.removeAll()
        order.removeAll()
    }

    private func touch(_ identifier: Int) {
        if let index = order.firstIndex(of: identifier) {
            order.remove(at: index)
            order.append(identifier)
        }
    }

    private func evictIfNeeded() {
        while order.count > maxSize {
            let evicted = order.removeFirst()
            sentIdentifiers.remove(evicted)
        }
    }
}
