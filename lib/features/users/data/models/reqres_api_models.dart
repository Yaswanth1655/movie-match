/// JSON models for https://reqres.in/api/users

class ReqresUserDto {
  const ReqresUserDto({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;

  factory ReqresUserDto.fromJson(Map<String, dynamic> json) {
    return ReqresUserDto(
      id: _readInt(json['id']) ?? 0,
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }
}

class ReqresSupportDto {
  const ReqresSupportDto({this.url, this.text});

  final String? url;
  final String? text;

  factory ReqresSupportDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ReqresSupportDto();
    }
    return ReqresSupportDto(
      url: json['url']?.toString(),
      text: json['text']?.toString(),
    );
  }
}

/// Response for `GET /users?page=`
class ReqresUsersPageResponse {
  const ReqresUsersPageResponse({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.data,
    this.support,
  });

  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final List<ReqresUserDto> data;
  final ReqresSupportDto? support;

  factory ReqresUsersPageResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    return ReqresUsersPageResponse(
      page: _readInt(json['page']) ?? 1,
      perPage: _readInt(json['per_page']) ?? 6,
      total: _readInt(json['total']) ?? 0,
      totalPages: _readInt(json['total_pages']) ?? 1,
      data: rawList
          .map((e) => ReqresUserDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      support: ReqresSupportDto.fromJson(json['support'] as Map<String, dynamic>?),
    );
  }

  bool get hasNextPage => page < totalPages;
}

/// Response for `POST /users`
class ReqresCreateUserResponse {
  const ReqresCreateUserResponse({
    this.id,
    this.name,
    this.job,
    this.createdAt,
  });

  final String? id;
  final String? name;
  final String? job;
  final String? createdAt;

  factory ReqresCreateUserResponse.fromJson(Map<String, dynamic> json) {
    return ReqresCreateUserResponse(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      job: json['job']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
