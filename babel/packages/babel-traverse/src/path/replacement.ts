// This file contains methods responsible for replacing a node with another.

import { codeFrameColumns } from "@babel/code-frame";
import traverse from "../index";
import NodePath from "./index";
import { path as pathCache } from "../cache";
import { parse } from "@babel/parser";
import * as t from "@babel/types";
import hoistVariables from "@babel/helper-hoist-variables";

/**
 * Replace a node with an array of multiple. This method performs the following steps:
 *
 *  - Inherit the comments of first provided node with that of the current node.
 *  - Insert the provided nodes after the current node.
 *  - Remove the current node.
 */

export function replaceWithMultiple<Nodes extends Array<t.Node>>(
  nodes: Nodes,
): NodePath[] {
  // todo NodePaths
  this.resync();

  nodes = this._verifyNodeList(nodes);
  t.inheritLeadingComments(nodes[0], this.node);
  t.inheritTrailingComments(nodes[nodes.length - 1], this.node);
  pathCache.get(this.parent)?.delete(this.node);
  this.node = this.container[this.key] = null;
  const paths = this.insertAfter(nodes);

  if (this.node) {
    this.requeue();
  } else {
    this.remove();
  }
  return paths;
}

/**
 * Parse a string as an expression and replace the current node with the result.
 *
 * NOTE: This is typically not a good idea to use. Building source strings when
 * transforming ASTs is an antipattern and SHOULD NOT be encouraged. Even if it's
 * easier to use, your transforms will be extremely brittle.
 */

export function replaceWithSourceString(this: NodePath, replacement) {
  this.resync();

  try {
    replacement = `(${replacement})`;
    replacement = parse(replacement);
  } catch (err) {
    const loc = err.loc;
    if (loc) {
      err.message +=
        " - make sure this is an expression.\n" +
        codeFrameColumns(replacement, {
          start: {
            line: loc.line,
            column: loc.column + 1,
          },
        });
      err.code = "BABEL_REPLACE_SOURCE_ERROR";
    }
    throw err;
  }

  replacement = replacement.program.body[0].expression;
  traverse.removeProperties(replacement);
  return this.replaceWith(replacement);
}

/**
 * Replace the current node with another.
 */

export function replaceWith(this: NodePath, replacement: t.Node | NodePath) {
  this.resync();

  if (this.removed) {
    throw new Error("You can't replace this node, we've already removed it");
  }

  if (replacement instanceof NodePath) {
    replacement = replacement.node;
  }

  if (!replacement) {
    throw new Error(
      "You passed `path.replaceWith()` a falsy node, use `path.remove()` instead",
    );
  }

  if (this.node === replacement) {
    return [this];
  }

  if (this.isProgram() && !t.isProgram(replacement)) {
    throw new Error(
      "You can only replace a Program root node with another Program node",
    );
  }

  if (Array.isArray(replacement)) {
    throw new Error(
      "Don't use `path.replaceWith()` with an array of nodes, use `path.replaceWithMultiple()`",
    );
  }

  if (typeof replacement === "string") {
    throw new Error(
      "Don't use `path.replaceWith()` with a source string, use `path.replaceWithSourceString()`",
    );
  }

  let nodePath = "";

  if (this.isNodeType("Statement") && t.isExpression(replacement)) {
    if (
      !this.canHaveVariableDeclarationOrExpression() &&
      !this.canSwapBetweenExpressionAndStatement(replacement) &&
      !this.parentPath.isExportDefaultDeclaration()
    ) {
      // replacing a statement with an expression so wrap it in an expression statement
      replacement = t.expressionStatement(replacement);
      nodePath = "expression";
    }
  }

  if (this.isNodeType("Expression") && t.isStatement(replacement)) {
    if (
      !this.canHaveVariableDeclarationOrExpression() &&
      !this.canSwapBetweenExpressionAndStatement(replacement)
    ) {
      // replacing an expression with a statement so let's explode it
      return this.replaceExpressionWithStatements([replacement]);
    }
  }

  const oldNode = this.node;
  if (oldNode) {
    t.inheritsComments(replacement, oldNode);
    t.removeComments(oldNode);
  }

  // replace the node
  this._replaceWith(replacement);
  this.type = replacement.type;

  // potentially create new scope
  this.setScope();

  // requeue for visiting
  this.requeue();

  return [nodePath ? this.get(nodePath) : this];
}

/**
 * Description
 */

export function _replaceWith(this: NodePath, node) {
  if (!this.container) {
    throw new ReferenceError("Container is falsy");
  }

  if (this.inList) {
    // @ts-expect-error todo(flow->ts): check if t.validate accepts a numeric key
    t.validate(this.parent, this.key, [node]);
  } else {
    t.validate(this.parent, this.key as string, node);
  }

  this.debug(`Replace with ${node?.type}`);
  pathCache.get(this.parent)?.set(node, this).delete(this.node);

  this.node = this.container[this.key] = node;
}

/**
 * This method takes an array of statements nodes and then explodes it
 * into expressions. This method retains completion records which is
 * extremely important to retain original semantics.
 */

export function replaceExpressionWithStatements(
  this: NodePath,
  nodes: Array<t.Statement>,
) {
  this.resync();

  const toSequenceExpression = t.toSequenceExpression(nodes, this.scope);

  if (toSequenceExpression) {
    return this.replaceWith(toSequenceExpression)[0].get("expressions");
  }

  const functionParent = this.getFunctionParent();
  const isParentAsync = functionParent?.is("async");
  const isParentGenerator = functionParent?.is("generator");

  const container = t.arrowFunctionExpression([], t.blockStatement(nodes));

  this.replaceWith(t.callExpression(container, []));
  // replaceWith changes the type of "this", but it isn't trackable by TS
  type ThisType = NodePath<
    t.CallExpression & { callee: t.ArrowFunctionExpression }
  >;

  // hoist variable declaration in do block
  // `(do { var x = 1; x;})` -> `var x; (() => { x = 1; return x; })()`
  const callee = (this as ThisType).get("callee");
  hoistVariables(
    callee.get("body"),
    (id: t.Identifier) => {
      this.scope.push({ id });
    },
    "var",
  );

  // add implicit returns to all ending expression statements
  const completionRecords: Array<NodePath> = (this as ThisType)
    .get("callee")
    .getCompletionRecords();
  for (const path of completionRecords) {
    if (!path.isExpressionStatement()) continue;

    const loop = path.findParent(path => path.isLoop());
    if (loop) {
      let uid = loop.getData("expressionReplacementReturnUid");

      if (!uid) {
        uid = callee.scope.generateDeclaredUidIdentifier("ret");
        callee
          .get("body")
          .pushContainer("body", t.returnStatement(t.cloneNode(uid)));
        loop.setData("expressionReplacementReturnUid", uid);
      } else {
        uid = t.identifier(uid.name);
      }

      path
        .get("expression")
        .replaceWith(
          t.assignmentExpression("=", t.cloneNode(uid), path.node.expression),
        );
    } else {
      path.replaceWith(t.returnStatement(path.node.expression));
    }
  }

  // This is an IIFE, so we don't need to worry about the noNewArrows assumption
  callee.arrowFunctionToExpression();
  // Fixme: we can not `assert this is NodePath<t.FunctionExpression>` in `arrowFunctionToExpression`
  // because it is not a class method known at compile time.
  const newCallee = callee as unknown as NodePath<t.FunctionExpression>;

  // (() => await xxx)() -> await (async () => await xxx)();
  const needToAwaitFunction =
    isParentAsync &&
    traverse.hasType(
      (this.get("callee.body") as NodePath<t.BlockStatement>).node,
      "AwaitExpression",
      t.FUNCTION_TYPES,
    );
  const needToYieldFunction =
    isParentGenerator &&
    traverse.hasType(
      (this.get("callee.body") as NodePath<t.BlockStatement>).node,
      "YieldExpression",
      t.FUNCTION_TYPES,
    );
  if (needToAwaitFunction) {
    newCallee.set("async", true);
    // yield* will await the generator return result
    if (!needToYieldFunction) {
      this.replaceWith(t.awaitExpression((this as ThisType).node));
    }
  }
  if (needToYieldFunction) {
    newCallee.set("generator", true);
    this.replaceWith(t.yieldExpression((this as ThisType).node, true));
  }

  return newCallee.get("body.body");
}

export function replaceInline(this: NodePath, nodes: t.Node | Array<t.Node>) {
  this.resync();

  if (Array.isArray(nodes)) {
    if (Array.isArray(this.container)) {
      nodes = this._verifyNodeList(nodes);
      const paths = this._containerInsertAfter(nodes);
      this.remove();
      return paths;
    } else {
      return this.replaceWithMultiple(nodes);
    }
  } else {
    return this.replaceWith(nodes);
  }
}
