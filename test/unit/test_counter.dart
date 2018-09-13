library test_counter;

import 'dart:async';

import 'package:built_redux/built_redux.dart';
import 'package:built_value/built_value.dart';

part 'test_counter.g.dart';

// Counter

abstract class CounterActions extends ReduxActions {
  CounterActions._();
  factory CounterActions() => new _$CounterActions();

  ActionDispatcher<int> increment;
  ActionDispatcher<int> incrementOther;
  SubCounterActions subCounterActions;
  MiddlewareActions middlewareActions;
}

abstract class SubCounterActions extends ReduxActions {
  SubCounterActions._();
  factory SubCounterActions() => new _$SubCounterActions();

  ActionDispatcher<int> increment;
  ActionDispatcher<int> doubleIt;
}

void _increment(Counter state, Action<int> action, CounterBuilder builder) =>
    builder.count = state.count + action.payload;

void _incrementOther(
        Counter state, Action<int> action, CounterBuilder builder) =>
    builder.otherCount = state.otherCount + action.payload;

void _incrementSubCount(
        Counter state, Action<int> action, CounterBuilder builder) =>
    builder.subCounter.subCount = state.subCounter.subCount + action.payload;

final reducer = (new ReducerBuilder<Counter, CounterBuilder>()
      ..add(CounterActionsNames.increment, _increment)
      ..combine(_otherReducer)
      ..add(SubCounterActionsNames.increment, _incrementSubCount))
    .build();

final _otherReducer = (new ReducerBuilder<Counter, CounterBuilder>()
  ..add(CounterActionsNames.incrementOther, _incrementOther));

abstract class Counter implements Built<Counter, CounterBuilder> {
  int get count;

  int get otherCount;

  SubCounter get subCounter;

  // Built value constructor
  Counter._();

  factory Counter() =>
      new _$Counter._(count: 1, otherCount: 1, subCounter: SubCounter());
}

abstract class SubCounter implements Built<SubCounter, SubCounterBuilder> {
  int get subCount;

  SubCounter._();

  factory SubCounter() => new _$SubCounter._(subCount: 1);
}

// Middleware

abstract class MiddlewareActions extends ReduxActions {
  ActionDispatcher<int> doubleIt;
  ActionDispatcher<int> tripleIt;

  MiddlewareActions._();
  factory MiddlewareActions() => new _$MiddlewareActions();
}

var counterMiddleware =
    (new MiddlewareBuilder<Counter, CounterBuilder, CounterActions>()
          ..add(MiddlewareActionsNames.doubleIt, _doubleIt)
          ..combine(tripleItMiddlewareBuilder)
          ..combineNested(subCountNested))
        .build();

void _doubleIt(MiddlewareApi<Counter, CounterBuilder, CounterActions> api,
    ActionHandler next, Action<int> action) {
  api.actions.increment(api.state.count * 2);
  next(action);
}

var tripleItMiddlewareBuilder =
    new MiddlewareBuilder<Counter, CounterBuilder, CounterActions>()
      ..add(MiddlewareActionsNames.tripleIt, _tripleIt);

void _tripleIt(MiddlewareApi<Counter, CounterBuilder, CounterActions> api,
    ActionHandler next, Action<int> action) {
  api.actions.increment(api.state.count * 3);
  next(action);
}

var subCountNested = NestedMiddlewareBuilder<
    Counter,
    CounterBuilder,
    CounterActions,
    SubCounter,
    SubCounterBuilder,
    SubCounterActions>((c) => c.subCounter, (a) => a.subCounterActions)
  ..combineMiddlewareBuilder(subCountMiddlewareBuilder);

var subCountMiddlewareBuilder =
    new MiddlewareBuilder<SubCounter, SubCounterBuilder, SubCounterActions>()
      ..add(SubCounterActionsNames.doubleIt, _subCounterDoubleIt);

void _subCounterDoubleIt(
    MiddlewareApi<SubCounter, SubCounterBuilder, SubCounterActions> api,
    ActionHandler next,
    Action<int> action) {
  api.actions.increment(api.state.subCount * 2);
  next(action);
}

// Change handler

StoreChangeHandlerBuilder<Counter, CounterBuilder,
    CounterActions> createChangeHandler(
        Completer comp) =>
    (new StoreChangeHandlerBuilder<Counter, CounterBuilder, CounterActions>()
      ..add(CounterActionsNames.increment, (change) => comp.complete(change)));
