import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_radio/features/player/data/playback_memory.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const hour = Duration(hours: 1);

  test('resumes mid-episode, survives a restart', () {
    PlaybackMemory(prefs).save('ep', const Duration(minutes: 12), hour);

    final reloaded = PlaybackMemory(prefs); // Simulates a new app launch.
    expect(reloaded.resumePointFor('ep'), const Duration(minutes: 12));
    expect(reloaded.positionOf('ep')!.remaining, const Duration(minutes: 48));
  });

  test('starts over when barely started or nearly finished', () {
    final memory = PlaybackMemory(prefs)
      ..save('start', const Duration(seconds: 5), hour)
      ..save('end', hour - const Duration(seconds: 5), hour);

    expect(memory.resumePointFor('start'), isNull);
    expect(memory.resumePointFor('end'), isNull);
    expect(memory.positionOf('end')!.finished, isTrue);
  });

  test('finished episodes restart from the top', () {
    final memory = PlaybackMemory(prefs)
      ..save('ep', const Duration(minutes: 30), hour)
      ..markFinished('ep');

    expect(memory.resumePointFor('ep'), isNull);
    expect(memory.positionOf('ep')!.finished, isTrue);
  });

  test('speed is remembered', () {
    PlaybackMemory(prefs).speed = 1.5;
    expect(PlaybackMemory(prefs).speed, 1.5);
  });
}
