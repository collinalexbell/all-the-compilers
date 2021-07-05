package eta.runtime.apply;

import eta.runtime.stg.Closure;
import eta.runtime.stg.StgContext;

public class Function4 extends Function {
    public int arity() { return 4; }

    @Override
    public Closure apply5(StgContext context, Closure p1, Closure p2, Closure p3, Closure p4, Closure p5) {
        boolean old = context.getAndSetTrampoline();
        Closure result = apply4(context, p1, p2, p3, p4);
        context.trampoline = old;
        return result.apply1(context, p5);
    }

    @Override
    public Closure apply6(StgContext context, Closure p1, Closure p2, Closure p3, Closure p4, Closure p5, Closure p6) {
        boolean old = context.getAndSetTrampoline();
        Closure result = apply4(context, p1, p2, p3, p4);
        context.trampoline = old;
        return result.apply2(context, p5, p6);
    }
}
