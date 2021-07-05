package eta.runtime.thunk;

import eta.runtime.stg.Closure;

public abstract class UpdatableThunk6 extends UpdatableThunk {
    public Closure x1;
    public Closure x2;
    public Closure x3;
    public Closure x4;
    public Closure x5;
    public Closure x6;

    public UpdatableThunk6(Closure x1, Closure x2, Closure x3, Closure x4, Closure x5, Closure x6) {
        this.x1 = x1;
        this.x2 = x2;
        this.x3 = x3;
        this.x4 = x4;
        this.x5 = x5;
        this.x6 = x6;
    }

    @Override
    public final void clear() {
        this.x1 = null;
        this.x2 = null;
        this.x3 = null;
        this.x4 = null;
        this.x5 = null;
        this.x6 = null;
    }
}
