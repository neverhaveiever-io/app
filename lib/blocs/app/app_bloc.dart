import 'dart:async';

import 'package:flutter/cupertino.dart' show required;
import 'package:flutter_bloc/flutter_bloc.dart' show Bloc;

import 'package:nhie/blocs/app/app.dart';
import 'package:nhie/blocs/statement/statement.dart';
import 'package:nhie/env.dart';
import 'package:nhie/models/category.dart';
import 'package:nhie/models/statement.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final StatementBloc statementBloc;

  StreamSubscription statementSubscription;
  List<Statement> statements = [];
  int currentStatementIndex = -1;
  List<Category> categories;
  bool goForward = false;

  AppBloc({@required this.statementBloc}) : super(Uninitialized()) {
    statementSubscription = statementBloc.listen((state) {
      if (state is StatementLoaded) {
        add(AddStatement(state.statement));
      } else if (state is StatementNotLoaded) {
        add(HandleException(state.exception));
      }
    });
  }

  @override
  Stream<AppState> mapEventToState(AppEvent event) async* {
    if (event is HandleException) {
      yield* _mapHandleExceptionToAppException(event);
    } else if (event is Initialize) {
      yield* _mapInitializeToInitialized(event);
    } else if (event is GoForward) {
      yield* _mapGoForwardToForward(event);
    } else if (event is AddStatement) {
      _mapAddStatement(event);
    } else if (event is ChangeCategories) {
      _mapChangeCategories(event);
    } else if (event is ChangeLanguage) {
      _mapChangeLanguage(event);
    }
  }

  Stream<AppException> _mapHandleExceptionToAppException(
      HandleException event) async* {
    yield AppException(event.exception);
  }

  Stream<Initialized> _mapInitializeToInitialized(Initialize event) async* {
    categories = event.categories;
    statementBloc.add(LoadStatement(categories: categories));
    yield Initialized();

    new Timer.periodic(Duration(seconds: env.prefetchWaitTime), (Timer t) {
      if ((statements.length - 1 - currentStatementIndex) <
          env.maxPrefetchCalls) {
        statementBloc.add(LoadStatement(categories: categories));
      }
    });
  }

  Stream<Forward> _mapGoForwardToForward(GoForward event) async* {
    if (statements.length - 1 == currentStatementIndex) {
      categories ??= event.categories;
      goForward = true;
      if (event.statement != null) {
        statementBloc.add(LoadStatement(statement: event.statement));
      } else {
        statementBloc.add(LoadStatement(categories: event.categories));
      }
      return;
    }
    var statement = statements[++currentStatementIndex];
    yield Forward(statement);
  }

  void _mapAddStatement(AddStatement event) {
    statements.add(event.statement);
    if (goForward || state is AppException) {
      goForward = false;
      add(GoForward(categories: categories));
    }
  }

  void _mapChangeCategories(ChangeCategories event) {
    categories = event.categories;
    statements.removeRange(currentStatementIndex + 1, statements.length);
  }

  void _mapChangeLanguage(ChangeLanguage event) {
    env.selectedLanguage = event.language;
    statements.removeRange(currentStatementIndex + 1, statements.length);
    if (currentStatementIndex == -1) return;
    add(GoForward(statement: statements[statements.length - 1]));
  }

  @override
  Future<void> close() {
    statementSubscription.cancel();
    return super.close();
  }
}
