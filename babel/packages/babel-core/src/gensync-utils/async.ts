import gensync from "gensync";

import type { Gensync, Handler } from "gensync";
type MaybePromise<T> = T | Promise<T>;

const id = x => x;

const runGenerator: {
  sync<Return>(gen: Generator<unknown, Return>): Return;
  async<Return>(gen: Generator<unknown, Return>): Promise<Return>;
  errback<Return>(
    gen: Generator<unknown, Return>,
    cb: (err: Error, val: Return) => void,
  ): void;
} = gensync<(item: Generator) => any>(function* <Return>(
  item: Generator<unknown, Return>,
) {
  return yield* item;
});

// This Gensync returns true if the current execution context is
// asynchronous, otherwise it returns false.
export const isAsync = gensync<() => boolean>({
  sync: () => false,
  errback: cb => cb(null, true),
});

// This function wraps any functions (which could be either synchronous or
// asynchronous) with a Gensync. If the wrapped function returns a promise
// but the current execution context is synchronous, it will throw the
// provided error.
// This is used to handle user-provided functions which could be asynchronous.
export function maybeAsync<Fn extends (...args: any) => any>(
  fn: Fn,
  message: string,
): Gensync<Fn> {
  return gensync({
    sync(...args) {
      const result = fn.apply(this, args) as ReturnType<Fn>;
      if (isThenable(result)) throw new Error(message);
      return result;
    },
    async(...args) {
      return Promise.resolve(fn.apply(this, args));
    },
  });
}

const withKind = gensync<(cb: (kind: "sync" | "async") => any) => any>({
  sync: cb => cb("sync"),
  async: cb => cb("async"),
}) as <T>(cb: (kind: "sync" | "async") => MaybePromise<T>) => Handler<T>;

// This function wraps a generator (or a Gensync) into another function which,
// when called, will run the provided generator in a sync or async way, depending
// on the execution context where this forwardAsync function is called.
// This is useful, for example, when passing a callback to a function which isn't
// aware of gensync, but it only knows about synchronous and asynchronous functions.
// An example is cache.using, which being exposed to the user must be as simple as
// possible:
//     yield* forwardAsync(gensyncFn, wrappedFn =>
//       cache.using(x => {
//         // Here we don't know about gensync. wrappedFn is a
//         // normal sync or async function
//         return wrappedFn(x);
//       })
//     )
export function forwardAsync<
  Action extends (...args: unknown[]) => any,
  Return,
>(
  action: (...args: Parameters<Action>) => Handler<ReturnType<Action>>,
  cb: (
    adapted: (...args: Parameters<Action>) => MaybePromise<ReturnType<Action>>,
  ) => MaybePromise<Return>,
): Handler<Return> {
  const g = gensync<Action>(action);
  return withKind(kind => {
    const adapted = g[kind];
    return cb(adapted);
  });
}

// If the given generator is executed asynchronously, the first time that it
// is paused (i.e. When it yields a gensync generator which can't be run
// synchronously), call the "firstPause" callback.
export const onFirstPause = gensync<(gen: Generator, cb: Function) => any>({
  name: "onFirstPause",
  arity: 2,
  sync: function (item) {
    return runGenerator.sync(item);
  },
  errback: function (item, firstPause, cb) {
    let completed = false;

    runGenerator.errback(item, (err, value) => {
      completed = true;
      cb(err, value);
    });

    if (!completed) {
      firstPause();
    }
  },
}) as <T>(gen: Generator<any, T, any>, cb: Function) => Handler<T>;

// Wait for the given promise to be resolved
export const waitFor = gensync({
  sync: id,
  async: id,
}) as <T>(p: T | Promise<T>) => Handler<T>;

export function isThenable<T = any>(val: any): val is PromiseLike<T> {
  return (
    !!val &&
    (typeof val === "object" || typeof val === "function") &&
    !!val.then &&
    typeof val.then === "function"
  );
}
