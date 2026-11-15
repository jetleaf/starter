/// Pagination envelope shared by all repositories and controllers.
library;

class PageRequest {
  const PageRequest({this.page = 0, this.size = 20, this.sort = 'createdAt,desc'})
      : assert(page >= 0, 'page must be >= 0'),
        assert(size >= 1 && size <= 100, 'size must be within [1, 100]');

  final int page;
  final int size;
  final String sort;

  int get offset => page * size;

  String get sortField => sort.split(',').first;
  bool get descending => sort.split(',').length > 1 && sort.split(',')[1].toLowerCase() == 'desc';

  Map<String, dynamic> toJson() => {'page': page, 'size': size, 'sort': sort};
}

class Page<T> {
  const Page({
    required this.content,
    required this.totalElements,
    required this.page,
    required this.size,
  });

  final List<T> content;
  final int totalElements;
  final int page;
  final int size;

  int get totalPages => size == 0 ? 0 : (totalElements / size).ceil();
  bool get first => page == 0;
  bool get last => page + 1 >= totalPages;
  bool get empty => content.isEmpty;

  Page<R> map<R>(R Function(T) mapper) => Page<R>(
        content: content.map(mapper).toList(),
        totalElements: totalElements,
        page: page,
        size: size,
      );

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) => {
        'content': content.map(toJson).toList(),
        'page': {
          'number': page,
          'size': size,
          'totalElements': totalElements,
          'totalPages': totalPages,
          'first': first,
          'last': last,
        },
      };
}
