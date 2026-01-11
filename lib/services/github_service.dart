import 'dart:convert';
import 'package:http/http.dart' as http;

/// GitHub API 서비스
class GitHubService {
  static const String _baseUrl = 'https://api.github.com';
  
  /// 사용자의 오늘 커밋 수 조회
  /// 
  /// [username]: GitHub 사용자명
  /// 반환: 오늘 커밋 수 (실패 시 null)
  Future<int?> getTodayCommitCount(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username/events/public'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final List<dynamic> events = json.decode(response.body);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      int commitCount = 0;

      for (final event in events) {
        if (event['type'] != 'PushEvent') continue;
        
        final createdAt = event['created_at'] as String;
        if (!createdAt.startsWith(todayStr)) continue;

        // PushEvent의 commits 배열에서 커밋 수 계산
        final payload = event['payload'] as Map<String, dynamic>?;
        if (payload != null) {
          final commits = payload['commits'] as List<dynamic>?;
          if (commits != null) {
            commitCount += commits.length;
          }
        }
      }

      return commitCount;
    } catch (e) {
      print('GitHub API Error: $e');
      return null;
    }
  }

  /// 사용자 존재 여부 확인
  Future<bool> checkUserExists(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 사용자 기본 정보 조회
  Future<GitHubUser?> getUserInfo(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      return GitHubUser.fromJson(data);
    } catch (e) {
      print('GitHub API Error: $e');
      return null;
    }
  }

  /// 최근 커밋 히스토리 조회 (최근 N일)
  Future<Map<String, int>> getCommitHistory(String username, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username/events/public?per_page=100'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode != 200) {
        return {};
      }

      final List<dynamic> events = json.decode(response.body);
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final Map<String, int> history = {};

      for (final event in events) {
        if (event['type'] != 'PushEvent') continue;
        
        final createdAt = DateTime.parse(event['created_at'] as String);
        if (createdAt.isBefore(cutoffDate)) continue;

        final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        
        final payload = event['payload'] as Map<String, dynamic>?;
        if (payload != null) {
          final commits = payload['commits'] as List<dynamic>?;
          if (commits != null) {
            history[dateKey] = (history[dateKey] ?? 0) + commits.length;
          }
        }
      }

      return history;
    } catch (e) {
      print('GitHub API Error: $e');
      return {};
    }
  }
}

/// GitHub 사용자 정보 모델
class GitHubUser {
  final String login;
  final String? name;
  final String? avatarUrl;
  final int publicRepos;
  final int followers;
  final int following;

  GitHubUser({
    required this.login,
    this.name,
    this.avatarUrl,
    required this.publicRepos,
    required this.followers,
    required this.following,
  });

  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      login: json['login'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      publicRepos: json['public_repos'] as int? ?? 0,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
    );
  }
}
