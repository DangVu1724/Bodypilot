class PageResponseModel<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  PageResponseModel({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PageResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final List<dynamic> rawContent = json['content'] is List ? json['content'] as List : [];
    final items = rawContent.map((e) => fromJsonT(e as Map<String, dynamic>)).toList();

    return PageResponseModel<T>(
      content: items,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? (items.isNotEmpty ? 1 : 0),
      last: (json['last'] as bool?) ?? true,
    );
  }

  factory PageResponseModel.empty() {
    return PageResponseModel<T>(
      content: [],
      pageNumber: 0,
      pageSize: 20,
      totalElements: 0,
      totalPages: 0,
      last: true,
    );
  }
}
