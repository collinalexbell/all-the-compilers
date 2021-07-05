import type Printer from "../printer";
import * as t from "@babel/types";

export function File(this: Printer, node: t.File) {
  if (node.program) {
    // Print this here to ensure that Program node 'leadingComments' still
    // get printed after the hashbang.
    this.print(node.program.interpreter, node);
  }

  this.print(node.program, node);
}

export function Program(this: Printer, node: t.Program) {
  this.printInnerComments(node, false);

  this.printSequence(node.directives, node);
  if (node.directives && node.directives.length) this.newline();

  this.printSequence(node.body, node);
}

export function BlockStatement(this: Printer, node: t.BlockStatement) {
  this.token("{");
  this.printInnerComments(node);

  const hasDirectives = node.directives?.length;

  if (node.body.length || hasDirectives) {
    this.newline();

    this.printSequence(node.directives, node, { indent: true });
    if (hasDirectives) this.newline();

    this.printSequence(node.body, node, { indent: true });
    this.removeTrailingNewline();

    this.source("end", node.loc);

    if (!this.endsWith("\n")) this.newline();

    this.rightBrace();
  } else {
    this.source("end", node.loc);
    this.token("}");
  }
}

export function Directive(this: Printer, node: t.Directive) {
  this.print(node.value, node);
  this.semicolon();
}

// These regexes match an even number of \ followed by a quote
const unescapedSingleQuoteRE = /(?:^|[^\\])(?:\\\\)*'/;
const unescapedDoubleQuoteRE = /(?:^|[^\\])(?:\\\\)*"/;

export function DirectiveLiteral(this: Printer, node: t.DirectiveLiteral) {
  const raw = this.getPossibleRaw(node);
  if (raw != null) {
    this.token(raw);
    return;
  }

  const { value } = node;

  // NOTE: In directives we can't change escapings,
  // because they change the behavior.
  // e.g. "us\x65 string" (\x65 is e) is not a "use strict" directive.

  if (!unescapedDoubleQuoteRE.test(value)) {
    this.token(`"${value}"`);
  } else if (!unescapedSingleQuoteRE.test(value)) {
    this.token(`'${value}'`);
  } else {
    throw new Error(
      "Malformed AST: it is not possible to print a directive containing" +
        " both unescaped single and double quotes.",
    );
  }
}

export function InterpreterDirective(
  this: Printer,
  node: t.InterpreterDirective,
) {
  this.token(`#!${node.value}\n`);
}

export function Placeholder(this: Printer, node: t.Placeholder) {
  this.token("%%");
  this.print(node.name);
  this.token("%%");

  if (node.expectedNode === "Statement") {
    this.semicolon();
  }
}
