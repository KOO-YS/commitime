import 'dart:math';
import '../models/goal.dart';

/// 메시지 타입
enum MessageType {
  reminder,   // 마감 전 리마인더
  encourage,  // 독려
  praise,     // 칭찬
  scold,      // 잔소리/질책
  streak,     // 연속 달성 특별 메시지
}

/// 잔소리 메시지 모델
class NaggingMessage {
  final CharacterType character;
  final String text;
  final MessageType type;

  NaggingMessage({
    required this.character,
    required this.text,
    required this.type,
  });
}

/// 잔소리 메시지 생성기
class MessageGenerator {
  static final _random = Random();

  /// 상황에 맞는 메시지 생성
  static NaggingMessage generate({
    required CharacterType character,
    required int completedCount,
    required int totalCount,
    bool hasOverdue = false,
    int streakDays = 0,
  }) {
    MessageType type;
    
    if (streakDays >= 7) {
      type = MessageType.streak;
    } else if (completedCount == totalCount && totalCount > 0) {
      type = MessageType.praise;
    } else if (hasOverdue) {
      type = MessageType.scold;
    } else if (completedCount > 0) {
      type = MessageType.encourage;
    } else {
      type = MessageType.reminder;
    }

    final messages = _getMessages(character, type);
    final text = messages[_random.nextInt(messages.length)];

    return NaggingMessage(
      character: character,
      text: text,
      type: type,
    );
  }

  static List<String> _getMessages(CharacterType character, MessageType type) {
    switch (character) {
      case CharacterType.professor:
        return _professorMessages[type] ?? _professorMessages[MessageType.reminder]!;
      case CharacterType.mom:
        return _momMessages[type] ?? _momMessages[MessageType.reminder]!;
      case CharacterType.friend:
        return _friendMessages[type] ?? _friendMessages[MessageType.reminder]!;
      case CharacterType.drill:
        return _drillMessages[type] ?? _drillMessages[MessageType.reminder]!;
    }
  }

  // 교수님 메시지
  static final Map<MessageType, List<String>> _professorMessages = {
    MessageType.reminder: [
      "오늘 할 일은 확인했나? 아직 시간 있으니까 빨리 해.",
      "연구실에서 이 정도로 하면 졸업 못 해.",
      "내가 왜 매번 확인해야 하는 건지 모르겠네.",
      "계획대로 진행하고 있는 건가?",
    ],
    MessageType.encourage: [
      "그래, 진행하고 있구나. 마무리까지 잘 해보게.",
      "나쁘지 않네. 남은 것도 끝내도록.",
      "페이스 유지하면서 마무리하게나.",
    ],
    MessageType.praise: [
      "그래, 이 정도는 해야지. 수고했네.",
      "오늘은 제 시간에 했네. 내일도 이렇게 해.",
      "훌륭해. 이런 자세로 계속하면 되겠어.",
      "인정하지. 오늘은 잘했네.",
    ],
    MessageType.scold: [
      "마감 지났는데 아직도 안 했어? 내일 연구실로 와.",
      "이래가지고 되겠나. 정신 차려.",
      "변명은 듣고 싶지 않네. 결과로 보여주게.",
      "실망이야. 더 잘할 수 있는 학생인데.",
    ],
    MessageType.streak: [
      "7일 연속이라... 드디어 습관이 잡히기 시작했군.",
      "꾸준함이 실력이야. 계속 이어가게.",
      "이 정도면 인정해줄 수 있겠어.",
    ],
  };

  // 엄마 메시지
  static final Map<MessageType, List<String>> _momMessages = {
    MessageType.reminder: [
      "밥은 먹었어? 할 일은 하고 있는 거지?",
      "엄마가 계속 확인해야 하니... 얼른 해놓으렴.",
      "오늘 할 일 잊지 않았지?",
      "건강 챙기면서 해야 해~",
    ],
    MessageType.encourage: [
      "우리 아들/딸 열심히 하고 있구나~",
      "조금만 더 힘내! 엄마가 응원해~",
      "잘하고 있어. 무리하지 말고~",
    ],
    MessageType.praise: [
      "우리 아들/딸 잘했네~ 역시 내 자식이야.",
      "그래그래, 이렇게 꾸준히 하는 거야.",
      "기특해라~ 오늘 뭐 맛있는 거 먹을래?",
      "엄마가 다 봤어. 정말 잘했어~",
    ],
    MessageType.scold: [
      "아이고... 엄마가 뭐라 해야 하니. 내일은 꼭 해라?",
      "옆집 OO는 벌써 다 했다던데...",
      "엄마가 속상하다... 내일은 꼭 하자?",
      "그래도 내일은 할 수 있지? 엄마 믿어.",
    ],
    MessageType.streak: [
      "우리 아들/딸이 7일 연속이라니! 대단해~",
      "엄마가 정말 자랑스러워. 계속 화이팅!",
      "역시 내 자식이야~ 꾸준함이 최고지!",
    ],
  };

  // 친구 메시지
  static final Map<MessageType, List<String>> _friendMessages = {
    MessageType.reminder: [
      "야 오늘 할 일 했어? ㅋㅋ",
      "그거 해야 하는 거 아니야?",
      "슬슬 시작해야지~",
      "오늘도 파이팅! 💪",
    ],
    MessageType.encourage: [
      "오 하고 있구나! 좀 치네 ㅋㅋ",
      "굿굿~ 조금만 더!",
      "이 페이스면 되겠는데?",
    ],
    MessageType.praise: [
      "오 다 했어?? 대박 ㅋㅋㅋ",
      "미쳤다 진짜 ㅋㅋ 잘했어!",
      "역시~ 믿고 있었어 👍",
      "갓생 사네 ㅋㅋㅋ",
    ],
    MessageType.scold: [
      "야... 또 안 했어? ㅋㅋ",
      "에이~ 내일은 하자! ㅋㅋ",
      "괜찮아 내일 있잖아~",
      "ㅋㅋㅋ 그래도 내일은 진짜 해라?",
    ],
    MessageType.streak: [
      "7일 연속?? 레전드네 ㅋㅋㅋ",
      "미쳤다 진짜 갓생 ㅋㅋㅋ",
      "부럽다... 나도 좀 알려줘 ㅋㅋ",
    ],
  };

  // 조교관 메시지
  static final Map<MessageType, List<String>> _drillMessages = {
    MessageType.reminder: [
      "목표 달성 현황 보고! 왜 아직이야!",
      "정신 바짝 차려! 시간 없다!",
      "뭐해! 빨리 시작 안 해!",
      "오늘 목표 수행! 실행!",
    ],
    MessageType.encourage: [
      "그래! 그 기세 유지!",
      "좋아! 멈추지 마!",
      "아직 끝 아니야! 계속!",
    ],
    MessageType.praise: [
      "잘했다! 오늘은 합격이야!",
      "이게 진짜 너지! 수고했다!",
      "완벽해! 내일도 이렇게!",
      "임무 완수! 쉬어!",
    ],
    MessageType.scold: [
      "이게 뭐야! 다시 해!",
      "변명 필요 없어! 결과로 보여줘!",
      "정신력이 해이해졌어! 다잡아!",
      "내일은 두 배로 해! 알았어?!",
    ],
    MessageType.streak: [
      "7일 연속! 이게 진짜 군인 정신이야!",
      "대단하다! 이 기세 멈추지 마!",
      "완벽한 연속 달성! 자랑스럽다!",
    ],
  };
}
