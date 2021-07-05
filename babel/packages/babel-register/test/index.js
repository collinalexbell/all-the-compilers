"use strict";

const fs = require("fs");
const path = require("path");
const child = require("child_process");

let currentHook;
let currentOptions;
let sourceMapSupport = false;

const registerFile = require.resolve("../lib/index");
const testCacheFilename = path.join(__dirname, ".babel");
const testFile = require.resolve("./fixtures/babelrc/es2015");
const testFileContent = fs.readFileSync(testFile);
const sourceMapTestFile = require.resolve("./fixtures/source-map/index");
const sourceMapNestedTestFile = require.resolve(
  "./fixtures/source-map/foo/bar",
);
const internalModulesTestFile = require.resolve(
  "./fixtures/internal-modules/index",
);

jest.mock("pirates", () => {
  return {
    addHook(hook, opts) {
      currentHook = hook;
      currentOptions = opts;

      return () => {
        currentHook = null;
        currentOptions = null;
      };
    },
  };
});

jest.mock("source-map-support", () => {
  return {
    install() {
      sourceMapSupport = true;
    },
  };
});

const defaultOptions = {
  exts: [".js", ".jsx", ".es6", ".es", ".mjs", ".cjs"],
  ignoreNodeModules: false,
};

function cleanCache() {
  try {
    fs.unlinkSync(testCacheFilename);
  } catch (e) {
    // It is convenient to always try to clear
  }
}

function resetCache() {
  process.env.BABEL_CACHE_PATH = null;
}

describe("@babel/register", function () {
  let babelRegister;

  function setupRegister(config = { babelrc: false }) {
    process.env.BABEL_CACHE_PATH = testCacheFilename;
    config = {
      cwd: path.dirname(testFile),
      ...config,
    };

    babelRegister = require(registerFile);
    babelRegister.default(config);
  }

  function revertRegister() {
    if (babelRegister) {
      babelRegister.revert();
      delete require.cache[registerFile];
      babelRegister = null;
    }
    cleanCache();
  }

  afterEach(async () => {
    // @babel/register saves the cache on process.nextTick.
    // We need to wait for at least one tick so that when jest
    // tears down the testing environment @babel/register has
    // already finished.
    await new Promise(setImmediate);

    revertRegister();
    currentHook = null;
    currentOptions = null;
    sourceMapSupport = false;
    jest.resetModules();
  });

  afterAll(() => {
    resetCache();
  });

  test("registers hook correctly", () => {
    setupRegister();

    expect(typeof currentHook).toBe("function");
    expect(currentOptions).toEqual(defaultOptions);
  });

  test("unregisters hook correctly", () => {
    setupRegister();
    revertRegister();

    expect(currentHook).toBeNull();
    expect(currentOptions).toBeNull();
  });

  test("installs source map support by default", () => {
    setupRegister();

    currentHook("const a = 1;", testFile);

    expect(sourceMapSupport).toBe(true);
  });

  test("installs source map support when requested", () => {
    setupRegister({
      babelrc: false,
      sourceMaps: true,
    });

    currentHook("const a = 1;", testFile);

    expect(sourceMapSupport).toBe(true);
  });

  test("does not install source map support if asked not to", () => {
    setupRegister({
      babelrc: false,
      sourceMaps: false,
    });

    currentHook("const a = 1;", testFile);

    expect(sourceMapSupport).toBe(false);
  });

  it("returns concatenatable sourceRoot and sources", async () => {
    // The Source Maps R3 standard https://sourcemaps.info/spec.html states
    // that `sourceRoot` is “prepended to the individual entries in the
    // ‘source’ field.” If `sources` contains file names, and `sourceRoot`
    // is intended to refer to a directory but doesn’t end with a trailing
    // slash, any consumers of the source map are in for a bad day.
    //
    // The underlying problem seems to only get triggered if one file
    // requires() another with @babel/register active, and I couldn’t get
    // that working inside a test, possibly because of jest’s mocking
    // hooks, so we spawn a separate process.
    const output = await spawnNodeAsync([
      "-r",
      registerFile,
      sourceMapTestFile,
    ]);
    const sourceMap = JSON.parse(output);
    expect(sourceMap.map.sourceRoot + sourceMap.map.sources[0]).toBe(
      sourceMapNestedTestFile,
    );
  });

  test("hook transpiles with config", () => {
    setupRegister({
      babelrc: false,
      sourceMaps: false,
      plugins: ["@babel/transform-modules-commonjs"],
    });

    const result = currentHook(testFileContent, testFile);

    expect(result).toBe('"use strict";\n\nrequire("assert");');
  });

  test("hook transpiles with babelrc", () => {
    setupRegister({
      babelrc: true,
      sourceMaps: false,
    });

    const result = currentHook(testFileContent, testFile);

    expect(result).toBe('"use strict";\n\nrequire("assert");');
  });

  test("transforms modules used within register", async () => {
    // Need a clean environment without `convert-source-map`
    // already in the require cache, so we spawn a separate process

    const output = await spawnNodeAsync([internalModulesTestFile]);
    const { convertSourceMap } = JSON.parse(output);
    expect(convertSourceMap).toMatch("/* transformed */");
  });
});

function spawnNodeAsync(args) {
  const spawn = child.spawn(process.execPath, args, { cwd: __dirname });

  let output = "";
  let callback;

  for (const stream of [spawn.stderr, spawn.stdout]) {
    stream.on("data", chunk => {
      output += chunk;
    });
  }

  spawn.on("close", function () {
    callback(output);
  });

  return new Promise(resolve => {
    callback = resolve;
  });
}
