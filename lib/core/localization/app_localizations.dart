import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get appTitle =>
      _translate(en: 'QSW Mobile', ko: 'QSW Mobile', ru: 'QSW Mobile');

  String get appDescription => _translate(
    en: 'Quick Search in Warehouse',
    ko: '창고 빠른 검색',
    ru: 'Быстрый поиск на складе',
  );

  String get receiving => _translate(en: 'Receiving', ko: '입고', ru: 'Приёмка');

  String get shipping => _translate(en: 'Shipping', ko: '출고', ru: 'Отгрузка');

  String get partSearch =>
      _translate(en: 'Part Search', ko: '부품 검색', ru: 'Поиск детали');

  String get inventory => _translate(en: 'Inventory', ko: '재고', ru: 'Остатки');

  String get partCodeOrName => _translate(
    en: 'Part Code or Name',
    ko: '부품 코드 또는 이름',
    ru: 'Код или название детали',
  );

  String get enterPartCodeOrName => _translate(
    en: 'Enter part code or name',
    ko: '부품 코드 또는 이름을 입력하세요',
    ru: 'Введите код или название детали',
  );

  String get searching =>
      _translate(en: 'Searching...', ko: '검색 중...', ru: 'Поиск...');

  String get search => _translate(en: 'Search', ko: '검색', ru: 'Поиск');

  String get enterPartCodeOrNameToSearch => _translate(
    en: 'Enter a part code or name to search.',
    ko: '검색하려면 부품 코드 또는 이름을 입력하세요.',
    ru: 'Введите код или название детали для поиска.',
  );

  String get noPartsFound => _translate(
    en: 'No parts found',
    ko: '부품을 찾을 수 없습니다',
    ru: 'Детали не найдены',
  );

  String get barcode => _translate(en: 'Barcode', ko: '바코드', ru: 'Штрихкод');

  String get unit => _translate(en: 'Unit', ko: '단위', ru: 'Единица');

  String get addPart =>
      _translate(en: 'Add Part', ko: '부품 추가', ru: 'Добавить деталь');

  String get partCode =>
      _translate(en: 'Part Code', ko: '부품 코드', ru: 'Код детали');

  String get enterPartCode => _translate(
    en: 'Enter part code',
    ko: '부품 코드를 입력하세요',
    ru: 'Введите код детали',
  );

  String get partCodeRequired => _translate(
    en: 'Part Code is required',
    ko: '부품 코드는 필수입니다',
    ru: 'Код детали обязателен',
  );

  String get name => _translate(en: 'Name', ko: '이름', ru: 'Название');

  String get enterPartName => _translate(
    en: 'Enter part name',
    ko: '부품 이름을 입력하세요',
    ru: 'Введите название детали',
  );

  String get nameRequired => _translate(
    en: 'Name is required',
    ko: '이름은 필수입니다',
    ru: 'Название обязательно',
  );

  String get specification =>
      _translate(en: 'Specification', ko: '사양', ru: 'Спецификация');

  String get enterSpecification => _translate(
    en: 'Enter specification',
    ko: '사양을 입력하세요',
    ru: 'Введите спецификацию',
  );

  String get enterBarcode =>
      _translate(en: 'Enter barcode', ko: '바코드를 입력하세요', ru: 'Введите штрихкод');

  String get enterUnit =>
      _translate(en: 'Enter unit', ko: '단위를 입력하세요', ru: 'Введите единицу');

  String get unitRequired => _translate(
    en: 'Unit is required',
    ko: '단위는 필수입니다',
    ru: 'Единица обязательна',
  );

  String get saving =>
      _translate(en: 'Saving...', ko: '저장 중...', ru: 'Сохранение...');

  String get partAddedSuccessfully => _translate(
    en: 'Part added successfully',
    ko: '부품이 성공적으로 추가되었습니다',
    ru: 'Деталь успешно добавлена',
  );

  String failedToAddPart(String error) => _translate(
    en: 'Failed to add part: $error',
    ko: '부품 추가에 실패했습니다: $error',
    ru: 'Не удалось добавить деталь: $error',
  );

  String failedToSearchParts(String error) => _translate(
    en: 'Failed to search parts: $error',
    ko: '부품 검색에 실패했습니다: $error',
    ru: 'Не удалось выполнить поиск деталей: $error',
  );

  String get parts => _translate(en: 'Parts', ko: '부품', ru: 'Детали');

  String get refresh => _translate(en: 'Refresh', ko: '새로고침', ru: 'Обновить');

  String get deletePart =>
      _translate(en: 'Delete Part', ko: '부품 삭제', ru: 'Удаление детали');

  String confirmDeletePart(String partCode) => _translate(
    en: 'Are you sure you want to delete "$partCode"?',
    ko: '"$partCode" 부품을 삭제하시겠습니까?',
    ru: 'Вы уверены, что хотите удалить деталь "$partCode"?',
  );

  String get cancel => _translate(en: 'Cancel', ko: '취소', ru: 'Отмена');

  String get delete => _translate(en: 'Delete', ko: '삭제', ru: 'Удалить');

  String get partDeletedSuccessfully => _translate(
    en: 'Part deleted successfully',
    ko: '부품이 성공적으로 삭제되었습니다',
    ru: 'Деталь успешно удалена',
  );

  String failedToDeletePart(String error) => _translate(
    en: 'Failed to delete part: $error',
    ko: '부품 삭제에 실패했습니다: $error',
    ru: 'Не удалось удалить деталь: $error',
  );

  String get addPartToSeeItHere => _translate(
    en: 'Add a part to see it here.',
    ko: '부품을 추가하면 여기에 표시됩니다.',
    ru: 'Добавьте деталь, чтобы увидеть её здесь.',
  );

  String get failedToLoadParts => _translate(
    en: 'Failed to load parts',
    ko: '부품을 불러오지 못했습니다',
    ru: 'Не удалось загрузить детали',
  );

  String get retry => _translate(en: 'Retry', ko: '다시 시도', ru: 'Повторить');

  String _translate({
    required String en,
    required String ko,
    required String ru,
  }) {
    switch (locale.languageCode) {
      case 'ko':
        return ko;
      case 'ru':
        return ru;
      case 'en':
      default:
        return en;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ko', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) {
    return false;
  }
}
