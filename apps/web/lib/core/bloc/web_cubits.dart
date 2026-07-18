import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class WebState<T> extends Equatable {
  const WebState();
  @override
  List<Object?> get props => [];
}

class WebInitial<T> extends WebState<T> {}
class WebLoading<T> extends WebState<T> {}
class WebSuccess<T> extends WebState<T> {
  final T data;
  const WebSuccess(this.data);
  @override
  List<Object?> get props => [data];
}
class WebError<T> extends WebState<T> {
  final String message;
  const WebError(this.message);
  @override
  List<Object?> get props => [message];
}

class WebCubit<T> extends Cubit<WebState<T>> {
  final Future<T> Function() fetchData;
  
  WebCubit(this.fetchData) : super(WebInitial<T>()) {
    load();
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(WebLoading<T>());
    try {
      final data = await fetchData();
      if (isClosed) return;
      emit(WebSuccess<T>(data));
    } catch (e) {
      if (isClosed) return;
      emit(WebError<T>(e.toString()));
    }
  }
}
