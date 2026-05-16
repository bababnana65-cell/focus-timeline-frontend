abstract class ProfileRemoteService {
  Future<List<String>> fetchInterestCategoryIds();

  Future<List<String>> saveInterestCategoryIds(List<String> categoryIds);

  Future<void> submitFeedback({
    required String message,
    String category = 'suggestion',
  });
}

class MockProfileRemoteService implements ProfileRemoteService {
  final List<String> _interestCategoryIds = <String>[];
  final List<ProfileFeedbackSubmission> feedbackSubmissions =
      <ProfileFeedbackSubmission>[];

  @override
  Future<List<String>> fetchInterestCategoryIds() async {
    return List<String>.unmodifiable(_interestCategoryIds);
  }

  @override
  Future<List<String>> saveInterestCategoryIds(List<String> categoryIds) async {
    _interestCategoryIds
      ..clear()
      ..addAll(_normalizeCategoryIds(categoryIds));
    return List<String>.unmodifiable(_interestCategoryIds);
  }

  @override
  Future<void> submitFeedback({
    required String message,
    String category = 'suggestion',
  }) async {
    feedbackSubmissions.add(
      ProfileFeedbackSubmission(
        message: message,
        category: category,
        submittedAt: DateTime.now(),
      ),
    );
  }
}

class ProfileFeedbackSubmission {
  const ProfileFeedbackSubmission({
    required this.message,
    required this.category,
    required this.submittedAt,
  });

  final String message;
  final String category;
  final DateTime submittedAt;
}

List<String> _normalizeCategoryIds(List<String> categoryIds) {
  final seen = <String>{};
  return <String>[
    for (final id in categoryIds)
      if (id.trim().isNotEmpty && seen.add(id.trim())) id.trim(),
  ];
}
