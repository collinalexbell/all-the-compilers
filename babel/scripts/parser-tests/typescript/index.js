import path from "path";
import fs from "fs/promises";
import { fileURLToPath } from "url";
import ts from "../../../build/typescript/lib/typescript.js";
import TestRunner from "../utils/parser-test-runner.js";
import parsingErrorCodes from "./error-codes.js";

const dirname = path.dirname(fileURLToPath(import.meta.url));

async function* loadTests(dir) {
  const names = await fs.readdir(dir);

  for (const name of names) {
    const contents = await fs.readFile(path.join(dir, name), "utf8");
    yield { name, contents };
  }
}

const plugins = [
  "typescript",
  "classProperties",
  "decorators-legacy",
  "bigInt",
  "dynamicImport",
];

const TSTestsPath = path.join(dirname, "../../../build/typescript/tests");

// Check if the baseline errors contain the codes that should also be thrown from babel-parser
async function baselineContainsParserErrorCodes(testName) {
  try {
    const baselineErrors = await fs.readFile(
      path.join(
        TSTestsPath,
        "baselines/reference",
        testName.replace(/\.tsx?$/, ".errors.txt")
      ),
      "utf8"
    );
    return parsingErrorCodes.some(code => baselineErrors.includes(code));
  } catch (e) {
    if (e.code !== "ENOENT") {
      throw e;
    }
    return false;
  }
}

const runner = new TestRunner({
  testDir: path.join(TSTestsPath, "./cases/compiler"),
  allowlist: path.join(dirname, "allowlist.txt"),
  logInterval: 50,
  shouldUpdate: process.argv.includes("--update-allowlist"),

  async *getTests() {
    for await (const test of loadTests(this.testDir)) {
      const isTSX = test.name.slice(-4) === ".tsx";

      const ast = ts.createSourceFile(
        test.name,
        test.contents,
        ts.ScriptTarget.Latest,
        false,
        isTSX ? ts.ScriptKind.TSX : ts.ScriptKind.TS
      );

      yield {
        contents: test.contents,
        fileName: test.name,
        id: test.name,
        expectedError:
          ast.parseDiagnostics.length > 0 ||
          (await baselineContainsParserErrorCodes(test.name)),
        sourceType: "module",
        plugins: isTSX ? plugins.concat("jsx") : plugins,
      };
    }
  },
});

runner.run().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
