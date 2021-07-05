namespace HH\__Private\MiniTest;

abstract class HackTest {
  protected static function fail(string $message): noreturn {
    invariant_violation('%s', $message);
  }

  protected static function markTestSkipped(string $message): noreturn {
    throw new SkippedTestException($message);
  }

  final public async function runAsync(): Awaitable<void> {
    \printf("--- %s::%s()\n", static::class, __FUNCTION__);
    $rc = new \ReflectionClass($this);
    foreach ($rc->getMethods() as $method) {
      if (!$method->isPublic()) {
        continue;
      }
      $name = $method->getName();
      if (\strlen($name) < 4 || \substr($name, 0, 4) !== 'test') {
        continue;
      }
      \printf("-----   %s::%s()\n", static::class, $name);
      $dp = $method->getAttributeClass(DataProvider::class);
      if (!$dp) {
        try {
          $ret = $method->invoke($this);
          if ($ret is Awaitable<_>) {
            await $ret;
          }
        } catch (SkippedTestException $ex) {
          \printf("------- SKIPPED: %s\n", $ex->getMessage());
        }
      } else {
        try {
          $dp = $rc->getMethod($dp->provider);
        } catch (\ReflectionException $_) {
          \printf("!!!!! DataProvider %s::%s() does not exist\n", static::class, $dp->provider);
          exit(1);
        }
        if (!$dp->isPublic() && $dp->isStatic()) {
          \printf("!!!!! DataProvider %s::%s() must be public static\n", static::class, $dp->name);
          exit(1);
        }
        \printf("-----     Invoking DataProvider %s::%s()\n", static::class, $dp->name);
        $values = $dp->invoke($this);
        foreach($values as $k => $args) {
          \printf("-----     Invoking with data set %s...\n", \var_export($k, true));
          try {
            $ret = $method->invokeArgs($this, $args);
            if ($ret is Awaitable<_>) {
              await $ret;
            }
          } catch (SkippedTestException $ex) {
            \printf("------- SKIPPED: %s\n", $ex->getMessage());
          }
        }
      }
    }
    \printf("OK: %s\n", static::class);
  }
}
