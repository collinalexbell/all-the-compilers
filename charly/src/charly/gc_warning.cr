# See https://github.com/crystal-lang/crystal/issues/2104

lib LibGC
  alias WarnProc = LibC::Char*, Word ->
  fun set_warn_proc = GC_set_warn_proc(WarnProc)
  $warn_proc = GC_current_warn_proc : WarnProc
end

LibGC.set_warn_proc ->(msg, word) {
  # Ignore the message
}
