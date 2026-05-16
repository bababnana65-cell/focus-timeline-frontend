class InterestCategory {
  const InterestCategory({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

const List<InterestCategory> interestCategories = <InterestCategory>[
  InterestCategory(id: 'politics', label: '政治'),
  InterestCategory(id: 'military', label: '军事'),
  InterestCategory(id: 'history', label: '历史'),
  InterestCategory(id: 'economy', label: '经济'),
  InterestCategory(id: 'finance', label: '金融'),
  InterestCategory(id: 'technology', label: '科技'),
  InterestCategory(id: 'society', label: '社会'),
  InterestCategory(id: 'international', label: '国际'),
  InterestCategory(id: 'enterprise', label: '企业'),
  InterestCategory(id: 'health', label: '医疗'),
  InterestCategory(id: 'climate', label: '环境'),
  InterestCategory(id: 'culture', label: '文化/体育'),
];

InterestCategory interestCategoryById(String? id) {
  for (final category in interestCategories) {
    if (category.id == id) {
      return category;
    }
  }
  return interestCategories.first;
}

bool isKnownInterestCategoryId(String? id) {
  return interestCategories.any((category) => category.id == id);
}
