class SlideItem {
  String title;
  String content;

  SlideItem({
    required this.title,
    required this.content,
  });

  factory SlideItem.fromJson(Map<String, dynamic> json) {
    return SlideItem(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}