import 'package:equatable/equatable.dart';

class UserMemory extends Equatable {
  final String id;
  final String key;
  final String value;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const UserMemory({
    required this.id,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });
  
  @override
  List<Object?> get props => [id, key, value, createdAt, updatedAt];
}

class UserProfile extends Equatable {
  final String name;
  final String? email;
  final String? phone;
  final String preferredCurrency;
  final List<String> favoriteCryptos;
  final Map<String, dynamic> preferences;
  
  const UserProfile({
    required this.name,
    this.email,
    this.phone,
    this.preferredCurrency = 'USD',
    this.favoriteCryptos = const [],
    this.preferences = const {},
  });
  
  @override
  List<Object?> get props => [name, email, phone, preferredCurrency, favoriteCryptos, preferences];
}
