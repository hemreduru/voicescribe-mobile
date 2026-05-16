import 'package:bloc/bloc.dart';
import 'package:voicescribe_mobile/ui/core/utils/logger.dart';

class VoiceScribeBlocObserver extends BlocObserver {
  const VoiceScribeBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error('Bloc error in ${bloc.runtimeType}', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
