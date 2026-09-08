import 'dart:collection';

/// Keeps only the most recently written payloads. Reads never mutate the map,
/// so iteration and async completion cannot invalidate each other's iterators.
class BoundedCache<K, V> extends MapBase<K, V> {
  BoundedCache(this.capacity) : assert(capacity > 0);
  final int capacity;
  final _entries = <K, V>{};

  @override
  V? operator [](Object? key) => _entries[key];
  @override
  void operator []=(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  @override
  Iterable<K> get keys => _entries.keys;
  @override
  V? remove(Object? key) => _entries.remove(key);
  @override
  void clear() => _entries.clear();
}
