enum SubscriptionTier {
  free,
  pro,
  elite;

  /// Returns true if the plan allows adding team members (inviting others).
  /// Free plan: Owner only (no invites).
  bool get canInviteMembers => this != free;

  /// Returns true if the plan allows data export.
  bool get canExportData => this != free;

  /// Returns true if the plan allows cloud backup.
  bool get canUseCloudBackup => this != free;

  /// Returns true if the plan allows using Deepgram (High Quality Speech-to-Text).
  bool get canUseDeepgram => this != free;

  /// Returns true if the plan allows using advanced AI models (GPT-4o, Claude 3.5 Sonnet).
  bool get canUseAdvancedModels =>
      this == elite ||
      this == pro; // Pro has some, but Elite has all. Simplified for now.

  /// Returns true if the plan allows using truly elite models like GPT-4o / Claude 3.5.
  bool get canUseEliteModels => this == elite;

  /// Max number of patients allowed (Total).
  /// -1 means unlimited.
  int get maxPatients => this == free ? 50 : (this == pro ? 1000 : 10000);

  /// Max number of sessions allowed per month.
  /// -1 means unlimited.
  int get maxMonthlySessions =>
      this == free ? 50 : (this == pro ? 3000 : 50000);

  /// Max number of evaluations allowed per month.
  /// -1 means unlimited.
  int get maxMonthlyEvaluations =>
      this == free ? 50 : (this == pro ? 1500 : 25000);

  /// Daily AI Chat limit.
  /// -1 means unlimited.
  int get dailyChatLimit => this == free ? 5 : (this == pro ? 100 : 500);

  /// Monthly Image Analysis limit.
  /// -1 means unlimited.
  int get monthlyImageAnalysisLimit =>
      this == free ? 0 : (this == pro ? 50 : 500);

  /// Monthly AI Token limit.
  /// Free: 100,000
  /// Pro: 1,000,000
  /// Elite: 5,000,000
  int get maxMonthlyTokens {
    switch (this) {
      case free:
        return 100000;
      case pro:
        return 1000000;
      case elite:
        return 5000000;
    }
  }

  /// Max Doctors allowed in the team (including owner).
  /// -1 means unlimited.
  int get maxDoctors => this == free ? 1 : (this == pro ? 3 : 15);

  /// Max Staff allowed in the team.
  /// Free plan has 0 staff slots (Owner is the only user).
  /// -1 means unlimited.
  int get maxStaff => this == free ? 0 : (this == pro ? 5 : 30);

  static SubscriptionTier fromString(String? value) {
    if (value == null) return SubscriptionTier.free;
    switch (value.toLowerCase()) {
      case 'pro':
      case 'professional':
        return SubscriptionTier.pro;
      case 'elite':
        return SubscriptionTier.elite;
      default:
        return SubscriptionTier.free;
    }
  }
}
