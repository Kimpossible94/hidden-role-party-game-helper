import 'dart:math';

class NameGenerator {
  static final List<String> _surnames = [
    '김', '이', '박', '최', '정', '강', '조', '윤', '장', '임',
    '한', '오', '서', '신', '권', '황', '안', '송', '류', '전',
    '홍', '고', '문', '양', '손', '배', '조', '백', '허', '유'
  ];

  static final List<String> _givenNames = [
    '민준', '서준', '도윤', '예준', '시우', '하준', '주원', '지호', '준서', '준우',
    '현우', '도현', '건우', '우진', '선우', '연우', '유준', '정우', '승현', '승우',
    '지윤', '서현', '예은', '지우', '채원', '하은', '소율', '서윤', '서연', '지원',
    '예린', '예원', '하윤', '소현', '유진', '수아', '윤서', '민서', '지민', '가은',
    '수빈', '태영', '성민', '진우', '영호', '상혁', '재현', '민수', '동현', '지훈',
    '소영', '은지', '혜진', '민지', '수정', '정은', '미경', '혜영', '영미', '은영'
  ];

  static final Random _random = Random();
  static final Set<String> _usedNames = <String>{};

  static String generateUniqueName() {
    String name;
    int attempts = 0;
    const maxAttempts = 1000;

    do {
      final surname = _surnames[_random.nextInt(_surnames.length)];
      final givenName = _givenNames[_random.nextInt(_givenNames.length)];
      name = '$surname$givenName';
      attempts++;

      // 너무 많이 시도했으면 숫자를 붙여서 고유하게 만들기
      if (attempts > maxAttempts) {
        final number = _random.nextInt(999) + 1;
        name = '$surname$givenName$number';
        break;
      }
    } while (_usedNames.contains(name));

    _usedNames.add(name);
    return name;
  }

  static void resetUsedNames() {
    _usedNames.clear();
  }
}