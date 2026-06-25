import 'base_entity.dart';
import 'branch.dart';
import 'user_role.dart'; // Import the UserRole model

class User extends BaseEntity {
  final String userName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? role;
  final Branch? branch;
  final bool isActive;
  final String? pin;
  final String? password;
  final List<UserRole>? userRoles; // Add userRoles field
  final String? profilePicture; // Added profilePicture field

  User({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required this.userName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.role,
    this.branch,
    this.isActive = true,
    this.pin,
    this.password,
    this.userRoles, // Add to constructor
    this.profilePicture, // Add to constructor
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  // Getter for companyId
  String? get companyId => branch?.company?.id;

  // copyWith method
  User copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? userName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? role,
    Branch? branch,
    bool? isActive,
    String? pin,
    String? password,
    List<UserRole>? userRoles,
    String? profilePicture,
  }) {
    return User(
      id: id ?? this.id,
      dateCreated: dateCreated ,
      dateModified: dateModified ,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      userName: userName ?? this.userName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      isActive: isActive ?? this.isActive,
      pin: pin ?? this.pin,
      password: password ?? this.password,
      userRoles: userRoles ?? this.userRoles,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      userName: json['userName'] ?? json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      isActive: json['isActive'] ?? true,
      pin: json['pin'],
      password: json['password'],
      userRoles: json['userRoles'] != null // Parse userRoles from JSON
          ? (json['userRoles'] as List).map((i) => UserRole.fromJson(i)).toList()
          : null,
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'userName': userName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role,
      'branch': branch?.toJson(),
      'isActive': isActive,
      'pin': pin,
      'password': password,
      'userRoles': userRoles?.map((i) => i.toJson()).toList(), // Serialize userRoles to JSON
      'profilePicture': profilePicture,
    };
  }
}
