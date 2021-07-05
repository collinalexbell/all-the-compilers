
namespace HH\__Private\MiniTest;

use type HH\__Private\MiniTest\HackTest;

use namespace HH\Lib\{C, Dict, Keyset, Str};

<<__EntryPoint>>
async function main(): Awaitable<void> {
  if (!\HH\Facts\enabled()) {
    \fwrite(\STDERR, "ext_facts is required\n");
    exit(1);
  }
  if (\ini_get('hhvm.hsl_systemlib_enabled')) {
    \fwrite(\STDERR, "HSL Systemlib must be disabled\n");
    exit(1);
  }
  if (!\function_exists("HH\\Lib\\Vec\\map")) {
    \fwrite(\STDERR, "Native autoloader must be configured; couldn't find HSL\n");
    exit(1);
  }

  if (!\class_exists(HackTest::class)) {
    \fprintf(
      \STDERR,
      "Native autoloader must be configured; couldn't find %s\n",
      HackTest::class,
    );
    exit(1);
  }

  $test_classes = Dict\filter(
    \HH\Facts\all_types(),
    $path ==>
      Str\starts_with($path, 'tests/') && Str\ends_with($path, 'Test.php'),
  );

  // Usage: minitest [FooTest] [tests/Foo.php]
  $argv = Keyset\map(\HH\global_get('argv') as vec<_>, $val ==> (string)$val)
    |> Keyset\drop($$, 1);
  if (!C\is_empty($argv)) {
    $test_classes = Dict\filter_with_key(
      $test_classes,
      ($class, $path) ==> {
        foreach ($argv as $arg) {
          if (Str\contains($class, $arg)) {
            return true;
          }
          if (Str\starts_with($path, $arg)) {
            return true;
          }
        }
        return false;
      },
    );
  }

  if (C\is_empty($test_classes)) {
    \fwrite(\STDERR, "No tests selected.\n");
    exit(1);
  }

  foreach ($test_classes as $class => $_path) {
    $rc = new \ReflectionClass($class);
    if (!$rc->isInstantiable()) {
      continue;
    }
    if (!$rc->isSubclassOf(HackTest::class)) {
      continue;
    }
    $c = $rc->getConstructor();
    if ($c !== null && $c->getNumberOfRequiredParameters() !== 0) {
      \printf(
        "!!! class %s has constructor with required parameters\n",
        $class,
      );
    }

    \printf("Starting %s...\n", $class);
    $obj = $rc->newInstance() as HackTest;
    await $obj->runAsync();
  }
}
