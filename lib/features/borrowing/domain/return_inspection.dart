enum ReturnCondition { good, minorDamage, damaged, lost }

extension ReturnConditionX on ReturnCondition {
  String get firestoreValue {
    switch (this) {
      case ReturnCondition.good:
        return 'good';
      case ReturnCondition.minorDamage:
        return 'minor_damage';
      case ReturnCondition.damaged:
        return 'damaged';
      case ReturnCondition.lost:
        return 'lost';
    }
  }

  String get label {
    switch (this) {
      case ReturnCondition.good:
        return 'Baik';
      case ReturnCondition.minorDamage:
        return 'Rusak Ringan';
      case ReturnCondition.damaged:
        return 'Rusak';
      case ReturnCondition.lost:
        return 'Hilang';
    }
  }
}

ReturnCondition? returnConditionFromValue(String? value) {
  switch (value) {
    case 'good':
      return ReturnCondition.good;
    case 'minor_damage':
      return ReturnCondition.minorDamage;
    case 'damaged':
      return ReturnCondition.damaged;
    case 'lost':
      return ReturnCondition.lost;
    default:
      return null;
  }
}
