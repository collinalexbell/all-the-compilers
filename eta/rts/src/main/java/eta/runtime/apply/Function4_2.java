package eta.runtime.apply;

import eta.runtime.stg.Closure;

public class Function4_2 extends Function4 {
    public Closure x1;
    public Closure x2;

    public Function4_2(Closure x1, Closure x2) {
        this.x1 = x1;
        this.x2 = x2;
    }
}
