import 'package:flutter_test/flutter_test.dart';
import 'package:voicescribe_mobile/shared/utils/text_utils.dart';

void main() {
  test('removeOverlap removes repeated chunk boundary text', () {
    expect(
      removeOverlap(
        'Merhaba bugün ürün yol haritasını konuşacağız',
        'ürün yol haritasını konuşacağız ve aksiyonları çıkaracağız',
      ),
      've aksiyonları çıkaracağız',
    );
  });

  test('removeOverlap returns incoming text when there is no overlap', () {
    expect(removeOverlap('ilk bölüm', 'ikinci bölüm'), 'ikinci bölüm');
  });

  test('formatDuration uses mm:ss shape', () {
    expect(formatDuration(65), '01:05');
  });
}
