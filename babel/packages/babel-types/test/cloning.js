import * as t from "../lib";
import { parse } from "@babel/parser";

describe("cloneNode", function () {
  it("should handle undefined", function () {
    const node = undefined;
    const cloned = t.cloneNode(node);
    expect(cloned).toBeUndefined();
  });

  it("should handle null", function () {
    const node = null;
    const cloned = t.cloneNode(node);
    expect(cloned).toBeNull();
  });

  it("should handle simple cases", function () {
    const node = t.identifier("a");
    const cloned = t.cloneNode(node);
    expect(node).not.toBe(cloned);
    expect(t.isNodesEquivalent(node, cloned)).toBe(true);
  });

  it("should handle full programs", function () {
    const file = parse("1 + 1");
    const cloned = t.cloneNode(file);
    expect(file).not.toBe(cloned);
    expect(file.program.body[0].expression.right).not.toBe(
      cloned.program.body[0].expression.right,
    );
    expect(file.program.body[0].expression.left).not.toBe(
      cloned.program.body[0].expression.left,
    );
    expect(t.isNodesEquivalent(file, cloned)).toBe(true);
  });

  it("should handle complex programs", function () {
    const program = "'use strict'; function lol() { wow();return 1; }";
    const node = parse(program);
    const cloned = t.cloneNode(node);
    expect(node).not.toBe(cloned);
    expect(t.isNodesEquivalent(node, cloned)).toBe(true);
  });

  it("should handle deep cloning without loc of fragments", function () {
    const program = "foo();";
    const node = parse(program);
    const cloned = t.cloneNode(node, /* deep */ true, /* withoutLoc */ true);
    expect(node).not.toBe(cloned);
    expect(t.isNodesEquivalent(node, cloned)).toBe(true);
  });

  it("should handle missing array element", function () {
    const node = parse("[,0]");
    const cloned = t.cloneNode(node);
    expect(node).not.toBe(cloned);
    expect(t.isNodesEquivalent(node, cloned)).toBe(true);
  });

  it("should support shallow cloning", function () {
    const node = t.memberExpression(t.identifier("foo"), t.identifier("bar"));
    const cloned = t.cloneNode(node, /* deep */ false);
    expect(node).not.toBe(cloned);
    expect(node.object).toBe(cloned.object);
    expect(node.property).toBe(cloned.property);
  });

  it("should preserve type annotations", function () {
    const node = t.variableDeclaration("let", [
      t.variableDeclarator({
        ...t.identifier("value"),
        typeAnnotation: t.anyTypeAnnotation(),
      }),
    ]);
    const cloned = t.cloneNode(node, /* deep */ true);
    expect(cloned.declarations[0].id.typeAnnotation).toEqual(
      node.declarations[0].id.typeAnnotation,
    );
    expect(cloned.declarations[0].id.typeAnnotation).not.toBe(
      node.declarations[0].id.typeAnnotation,
    );
  });

  it("should support shallow cloning without loc", function () {
    const node = t.variableDeclaration("let", [
      t.variableDeclarator({
        ...t.identifier("value"),
        typeAnnotation: t.anyTypeAnnotation(),
      }),
    ]);
    node.loc = {};
    const cloned = t.cloneNode(node, /* deep */ false, /* withoutLoc */ true);
    expect(cloned.loc).toBeNull();
  });

  it("should support deep cloning without loc", function () {
    const node = t.variableDeclaration("let", [
      t.variableDeclarator({
        ...t.identifier("value"),
        typeAnnotation: t.anyTypeAnnotation(),
      }),
    ]);
    node.loc = {};
    node.declarations[0].id.loc = {};
    const cloned = t.cloneNode(node, /* deep */ true, /* withoutLoc */ true);
    expect(cloned.loc).toBeNull();
    expect(cloned.declarations[0].id.loc).toBeNull();
  });

  it("should support deep cloning for comments", function () {
    const node = t.variableDeclaration("let", [
      t.variableDeclarator({
        ...t.identifier("value"),
        leadingComments: [{ loc: {} }],
        innerComments: [{ loc: {} }],
        trailingComments: [{ loc: {} }],
      }),
    ]);
    node.loc = {};
    node.declarations[0].id.loc = {};

    const cloned = t.cloneNode(node, /* deep */ true, /* withoutLoc */ false);
    expect(cloned.declarations[0].id.leadingComments[0]).not.toBe(
      node.declarations[0].id.leadingComments[0],
    );
    expect(cloned.declarations[0].id.leadingComments[0].loc).toBe(
      node.declarations[0].id.leadingComments[0].loc,
    );
    expect(cloned.declarations[0].id.innerComments[0].loc).toBe(
      node.declarations[0].id.innerComments[0].loc,
    );
    expect(cloned.declarations[0].id.trailingComments[0].loc).toBe(
      node.declarations[0].id.trailingComments[0].loc,
    );
  });

  it("should support deep cloning for comments without loc", function () {
    const node = t.variableDeclaration("let", [
      t.variableDeclarator({
        ...t.identifier("value"),
        leadingComments: [{ loc: {} }],
        innerComments: [{ loc: {} }],
        trailingComments: [{ loc: {} }],
      }),
    ]);
    node.loc = {};
    node.declarations[0].id.loc = {};

    const cloned = t.cloneNode(node, /* deep */ true, /* withoutLoc */ true);
    expect(cloned.declarations[0].id.leadingComments[0].loc).toBe(null);
    expect(cloned.declarations[0].id.innerComments[0].loc).toBe(null);
    expect(cloned.declarations[0].id.trailingComments[0].loc).toBe(null);
  });
});
