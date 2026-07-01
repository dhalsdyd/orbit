enum RelationshipMode {
  archiveOnly,
  gentleNudge,
  reconnect,
}

extension RelationshipModeLabel on RelationshipMode {
  String get label {
    return switch (this) {
      RelationshipMode.archiveOnly => 'Memory archive',
      RelationshipMode.gentleNudge => 'Gentle nudge',
      RelationshipMode.reconnect => 'Reconnect orbit',
    };
  }

  String get description {
    return switch (this) {
      RelationshipMode.archiveOnly => 'No reminders. Capture meaningful moments.',
      RelationshipMode.gentleNudge => 'Soft reminders and easy icebreakers.',
      RelationshipMode.reconnect => 'Dimmed orbit with stronger reconnect cues.',
    };
  }
}
