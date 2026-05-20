class JwtRequestModel {
  final String userName;
  final String password;

  JwtRequestModel({required this.userName, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'password': password,
    };
  }
}
