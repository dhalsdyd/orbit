enum MemoryKind {
  giftGiven,
  giftReceived,
  meal,
  cafe,
  trip,
  hobby,
}

extension MemoryKindLabel on MemoryKind {
  String get label {
    return switch (this) {
      MemoryKind.giftGiven => 'Gift given',
      MemoryKind.giftReceived => 'Gift received',
      MemoryKind.meal => 'Meal & drinks',
      MemoryKind.cafe => 'Cafe',
      MemoryKind.trip => 'Trip',
      MemoryKind.hobby => 'Shared hobby',
    };
  }

  bool get isGift {
    return switch (this) {
      MemoryKind.giftGiven || MemoryKind.giftReceived => true,
      _ => false,
    };
  }
}
