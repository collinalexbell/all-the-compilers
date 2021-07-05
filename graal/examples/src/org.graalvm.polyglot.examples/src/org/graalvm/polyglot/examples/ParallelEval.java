package org.graalvm.polyglot.examples;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.graalvm.polyglot.Context;

/**
 * Example shows how scripts can be executed in parallel. Please note that contexts are single
 * threaded by design. It is allowed to use a context on more than one thread, but not at the same
 * time.
 */
public class ParallelEval {

    public static void main(String[] args) throws InterruptedException, ExecutionException {
        ExecutorService service = Executors.newFixedThreadPool(1);
        Context context = Context.create("js");
        Future<Integer> future = service.submit(
                        () -> context.eval("js", "21 + 21").asInt());

        // do work while JavaScript executes

        int result = future.get();
        assert 42 == result;

        context.close();
    }

}
