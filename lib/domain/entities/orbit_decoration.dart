enum PlanetSkin {
  solarGold,
  oceanBlue,
  violetGas,
  forestMoss,
  crystalIce,
}

enum NebulaTheme {
  dawn,
  deepSea,
  roseGalaxy,
  snowfall,
  firefly,
}

enum MemorySticker {
  ribbon,
  cup,
  plate,
  flag,
  sparkle,
  bubble,
}

enum MemoryStamp {
  bright,
  cozy,
  funny,
  grateful,
  longing,
}

class OrbitDecoration {
  const OrbitDecoration({
    required this.contactId,
    required this.planetSkin,
    required this.nebulaTheme,
  });

  final String contactId;
  final PlanetSkin planetSkin;
  final NebulaTheme nebulaTheme;

  OrbitDecoration copyWith({
    PlanetSkin? planetSkin,
    NebulaTheme? nebulaTheme,
  }) {
    return OrbitDecoration(
      contactId: contactId,
      planetSkin: planetSkin ?? this.planetSkin,
      nebulaTheme: nebulaTheme ?? this.nebulaTheme,
    );
  }
}

extension PlanetSkinLabel on PlanetSkin {
  String get label {
    return switch (this) {
      PlanetSkin.solarGold => 'Solar gold',
      PlanetSkin.oceanBlue => 'Ocean blue',
      PlanetSkin.violetGas => 'Violet gas',
      PlanetSkin.forestMoss => 'Forest moss',
      PlanetSkin.crystalIce => 'Crystal ice',
    };
  }
}

extension NebulaThemeLabel on NebulaTheme {
  String get label {
    return switch (this) {
      NebulaTheme.dawn => 'Dawn',
      NebulaTheme.deepSea => 'Deep sea',
      NebulaTheme.roseGalaxy => 'Rose galaxy',
      NebulaTheme.snowfall => 'Snowfall',
      NebulaTheme.firefly => 'Firefly',
    };
  }
}

extension MemoryStickerLabel on MemorySticker {
  String get label {
    return switch (this) {
      MemorySticker.ribbon => 'Ribbon moon',
      MemorySticker.cup => 'Cafe star',
      MemorySticker.plate => 'Table star',
      MemorySticker.flag => 'Place flag',
      MemorySticker.sparkle => 'Sparkle',
      MemorySticker.bubble => 'Talk bubble',
    };
  }
}

extension MemoryStampLabel on MemoryStamp {
  String get label {
    return switch (this) {
      MemoryStamp.bright => 'Bright',
      MemoryStamp.cozy => 'Cozy',
      MemoryStamp.funny => 'Funny',
      MemoryStamp.grateful => 'Grateful',
      MemoryStamp.longing => 'Longing',
    };
  }
}
