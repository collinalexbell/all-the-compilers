{
  local c = (import '../../common.jsonnet'),
  local bc = (import '../../bench-common.libsonnet'),
  local cc = (import 'compiler-common.libsonnet'),

  local uniq_key(o) = o['suite'],
  // convenient sets of benchmark suites for easy reuse
  groups:: {
    open_suites:: std.set([$.awfy, $.dacapo, $.scala_dacapo, $.renaissance], keyF=uniq_key),
    spec_suites:: std.set([$.specjvm2008, $.specjbb2005, $.specjbb2015], keyF=uniq_key),
    legacy_suites:: std.set([$.renaissance_legacy], keyF=uniq_key),
    jmh_micros_suites:: std.set([$.micros_graal_dist, $.micros_misc_graal_dist , $.micros_shootout_graal_dist], keyF=uniq_key),
    graal_internals_suites:: std.set([$.micros_graal_whitebox], keyF=uniq_key),
    special_suites:: std.set([$.renaissance_0_10, $.specjbb2015_full_machine], keyF=uniq_key),
    microservice_suites:: std.set([$.microservice_benchmarks], keyF=uniq_key),

    main_suites:: std.set(self.open_suites + self.spec_suites + self.legacy_suites, keyF=uniq_key),
    all_suites:: std.set(self.main_suites + self.jmh_micros_suites + self.special_suites + self.microservice_suites, keyF=uniq_key),

    weekly_forks_suites:: self.main_suites,
    profiled_suites::     std.setDiff(self.main_suites, [$.specjbb2015], keyF=uniq_key),
  },

  // suite definitions
  // *****************
  awfy: cc.compiler_benchmark + c.heap.small + {
    suite:: "awfy",
    run+: [
      self.benchmark_cmd + ["awfy:*", "--"] + self.extra_vm_args
    ],
    timelimit: "30:00",
    forks_batches:: null, // disables it for now (GR-30956)
    forks_timelimit:: "3:00:00"
  },

  dacapo: cc.compiler_benchmark + c.heap.default + {
    suite:: "dacapo",
    run+: [
      self.benchmark_cmd + ["dacapo:*", "--"] + self.extra_vm_args
    ],
    timelimit: "45:00",
    forks_batches:: 1,
    forks_timelimit:: "02:45:00"
  },

  dacapo_timing: cc.compiler_benchmark + c.heap.default + {
    suite:: "dacapo-timing",
    run+: [
      self.benchmark_cmd + ["dacapo-timing:*", "--"] + self.extra_vm_args
    ],
    timelimit: "45:00"
  },

  scala_dacapo: cc.compiler_benchmark + c.heap.default + {
    suite:: "scala-dacapo",
    run+: [
      self.benchmark_cmd + ["scala-dacapo:*", "--"] + self.extra_vm_args
    ],
    timelimit: "45:00",
    forks_batches:: 1,
    forks_timelimit:: "03:30:00"
  },

  scala_dacapo_timing: cc.compiler_benchmark + c.heap.default + {
    suite:: "scala-dacapo-timing",
    run+: [
      self.benchmark_cmd + ["scala-dacapo-timing:*", "--"] + self.extra_vm_args
    ],
    timelimit: "45:00"
  },

  renaissance: cc.compiler_benchmark + c.heap.default + {
    suite:: "renaissance",
    environment+: {
      "SPARK_LOCAL_IP": "127.0.0.1"
    },
    run+: [
      if self.arch == "aarch64" then
        self.benchmark_cmd + ["renaissance:~db-shootout", "--bench-suite-version=$RENAISSANCE_VERSION", "--"] + self.extra_vm_args
      else
        self.benchmark_cmd + ["renaissance:*", "--bench-suite-version=$RENAISSANCE_VERSION", "--"] + self.extra_vm_args
    ],
    timelimit: "3:00:00",
    forks_batches:: 4,
    forks_timelimit:: "06:30:00"
  },

  renaissance_0_10: self.renaissance + {
    suite:: "renaissance-0-10",
    environment+: {
      "RENAISSANCE_VERSION": "0.10.0"
    }
  },

  renaissance_legacy: cc.compiler_benchmark + c.heap.default + {
    suite:: "renaissance-legacy",
    downloads+: {
      "RENAISSANCE_LEGACY": { name: "renaissance", version: "0.1" }
    },
    environment+: {
      "SPARK_LOCAL_IP": "127.0.0.1"
    },
    run+: [
      self.benchmark_cmd + ["renaissance-legacy:*", "--"] + self.extra_vm_args
    ],
    timelimit: "2:45:00",
    forks_batches:: 4,
    forks_timelimit:: "06:30:00"
  },

  specjbb2005: cc.compiler_benchmark + c.heap.large_with_large_young_gen + {
    suite:: "specjbb2005",
    downloads+: {
      "SPECJBB2005": { name: "specjbb2005", version: "1.07" }
    },
    run+: [
      self.benchmark_cmd + ["specjbb2005", "--"] + self.extra_vm_args + ["--", "input.ending_number_warehouses=77"]
    ],
    timelimit: "4:00:00",
    forks_batches:: 1,
    forks_timelimit:: "20:00:00"
  },

  specjbb2015: cc.compiler_benchmark + c.heap.large_with_large_young_gen + {
    suite:: "specjbb2015",
    downloads+: {
      "SPECJBB2015": { name: "specjbb2015", version: "1.03" }
    },
    run+: [
      self.benchmark_cmd + ["specjbb2015", "--"] + self.extra_vm_args
    ],
    timelimit: "3:00:00",
    forks_batches:: 1,
    forks_timelimit:: "20:00:00"
  },

  specjbb2015_full_machine: cc.compiler_benchmark + c.heap.large_with_large_young_gen + {
    suite:: "specjbb2015-full-machine",
    downloads+: {
      "SPECJBB2015": { name: "specjbb2015", version: "1.03" }
    },
    run+: [
      self.plain_benchmark_cmd + ["specjbb2015", "--"] + self.extra_vm_args
    ],
    timelimit: "3:00:00"
  },

  specjvm2008: cc.compiler_benchmark + c.heap.large + {
    suite:: "specjvm2008",
    downloads+: {
      "SPECJVM2008": { name: "specjvm2008", version: "1.01" }
    },
    run+: [
      self.benchmark_cmd + ["specjvm2008:*", "--"] + self.extra_vm_args + ["--", "-ikv", "-it", "240s", "-wt", "120s"]
    ],
    teardown+: [
      ["rm", "-r", "${SPECJVM2008}/results"]
    ],
    timelimit: "3:00:00",
    forks_batches:: 5,
    forks_timelimit:: "06:00:00"
  },

  // Microservice benchmarks
  microservice_benchmarks: cc.compiler_benchmark + {
    suite:: "microservices",
    packages+: {
      "python3": "==3.6.5",
      "pip:psutil": "==5.8.0"
    },
    local upload = ["bench-uploader.py", "bench-results.json"],
    run+: [
      self.benchmark_cmd + ["shopcart-jmeter:large", "--"] +               self.extra_vm_args + ["-Xms8g",    "-Xmx8g"],
      upload,
      self.benchmark_cmd + ["petclinic-jmeter:tiny", "--"] +               self.extra_vm_args + ["-Xms8g",    "-Xmx8g"],
      upload,
      self.benchmark_cmd + ["shopcart-wrk:mixed-tiny", "--"] +             self.extra_vm_args + ["-Xms32m",   "-Xmx112m",  "-XX:ActiveProcessorCount=1",  "-XX:MaxDirectMemorySize=256m"],
      upload,
      self.benchmark_cmd + ["shopcart-wrk:mixed-small", "--"] +            self.extra_vm_args + ["-Xms64m",   "-Xmx224m",  "-XX:ActiveProcessorCount=2",  "-XX:MaxDirectMemorySize=512m"],
      upload,
      self.benchmark_cmd + ["shopcart-wrk:mixed-medium", "--"] +           self.extra_vm_args + ["-Xms128m",  "-Xmx512m",  "-XX:ActiveProcessorCount=4",  "-XX:MaxDirectMemorySize=1024m"],
      upload,
      self.benchmark_cmd + ["shopcart-wrk:mixed-large", "--"] +            self.extra_vm_args + ["-Xms512m",  "-Xmx3072m", "-XX:ActiveProcessorCount=16", "-XX:MaxDirectMemorySize=4096m"],
      upload,
      self.benchmark_cmd + ["shopcart-wrk:mixed-huge", "--"] +             self.extra_vm_args + ["-Xms1024m", "-Xmx8192m", "-XX:ActiveProcessorCount=32", "-XX:MaxDirectMemorySize=8192m"],
      upload,
      self.benchmark_cmd + ["tika-wrk:odt-tiny", "--"] +                   self.extra_vm_args + ["-Xms32m",   "-Xmx150m",  "-XX:ActiveProcessorCount=1"],
      upload,
      self.benchmark_cmd + ["tika-wrk:odt-small", "--"] +                  self.extra_vm_args + ["-Xms64m",   "-Xmx250m",  "-XX:ActiveProcessorCount=2"],
      upload,
      self.benchmark_cmd + ["tika-wrk:odt-medium", "--"] +                 self.extra_vm_args + ["-Xms128m",  "-Xmx600m",  "-XX:ActiveProcessorCount=4"],
      upload,
      self.benchmark_cmd + ["tika-wrk:pdf-tiny", "--"] +                   self.extra_vm_args + ["-Xms20m",   "-Xmx80m",   "-XX:ActiveProcessorCount=1"],
      upload,
      self.benchmark_cmd + ["tika-wrk:pdf-small", "--"] +                  self.extra_vm_args + ["-Xms40m",   "-Xmx200m",  "-XX:ActiveProcessorCount=2"],
      upload,
      self.benchmark_cmd + ["tika-wrk:pdf-medium", "--"] +                 self.extra_vm_args + ["-Xms80m",   "-Xmx500m",  "-XX:ActiveProcessorCount=4"],
      upload,
      self.benchmark_cmd + ["petclinic-wrk:mixed-tiny", "--"] +            self.extra_vm_args + ["-Xms32m",   "-Xmx100m",  "-XX:ActiveProcessorCount=1"],
      upload,
      self.benchmark_cmd + ["petclinic-wrk:mixed-small", "--"] +           self.extra_vm_args + ["-Xms40m",   "-Xmx128m",  "-XX:ActiveProcessorCount=2"],
      upload,
      self.benchmark_cmd + ["petclinic-wrk:mixed-medium", "--"] +          self.extra_vm_args + ["-Xms80m",   "-Xmx256m",  "-XX:ActiveProcessorCount=4"],
      upload,
      self.benchmark_cmd + ["petclinic-wrk:mixed-large", "--"] +           self.extra_vm_args + ["-Xms320m",  "-Xmx1280m", "-XX:ActiveProcessorCount=16"],
      upload,
      self.benchmark_cmd + ["petclinic-wrk:mixed-huge", "--"] +            self.extra_vm_args + ["-Xms640m",  "-Xmx3072m", "-XX:ActiveProcessorCount=32"],
      upload,
      self.benchmark_cmd + ["micronaut-helloworld-wrk:helloworld", "--"] + self.extra_vm_args + ["-Xms8m",    "-Xmx64m",   "-XX:ActiveProcessorCount=1", "-XX:MaxDirectMemorySize=256m"],
      upload,
      self.benchmark_cmd + ["quarkus-helloworld-wrk:helloworld", "--"] +   self.extra_vm_args + ["-Xms8m",    "-Xmx64m",   "-XX:ActiveProcessorCount=1", "-XX:MaxDirectMemorySize=256m"],
      upload,
      self.benchmark_cmd + ["spring-helloworld-wrk:helloworld", "--"] +    self.extra_vm_args + ["-Xms8m",    "-Xmx64m",   "-XX:ActiveProcessorCount=1", "-XX:MaxDirectMemorySize=256m"],
      upload
    ],
    timelimit: "7:00:00"
  },

  // JMH microbenchmarks
  micros_graal_whitebox: cc.compiler_benchmark + c.heap.default + {
    suite:: "micros-graal-whitebox",
    run+: [
      self.benchmark_cmd + ["jmh-whitebox:*", "--"] + self.extra_vm_args
    ],
    timelimit: "3:00:00"
  },

  micros_graal_dist: cc.compiler_benchmark + c.heap.default + {
    suite:: "micros-graal-dist",
    run+: [
      self.benchmark_cmd + ["jmh-dist:GRAAL_COMPILER_MICRO_BENCHMARKS", "--"] + self.extra_vm_args
    ],
    timelimit: "3:00:00"
  },

  micros_misc_graal_dist: cc.compiler_benchmark + c.heap.default + {
    suite:: "micros-misc-graal-dist",
    run+: [
      self.benchmark_cmd + ["jmh-dist:GRAAL_BENCH_MISC", "--"] + self.extra_vm_args
    ],
    timelimit: "3:00:00"
  },

  micros_shootout_graal_dist: cc.compiler_benchmark + c.heap.default {
    suite:: "micros-shootout-graal-dist",
    run+: [
      self.benchmark_cmd + ["jmh-dist:GRAAL_BENCH_SHOOTOUT", "--"] + self.extra_vm_args
    ],
    timelimit: "3:00:00"
  }
}
