const Lib = require("./node.ch")
const NodeType = Lib.NodeType
const Node = Lib.Node
const Assertion = Lib.Assertion
const Charly = require("charly")

class Context {
  property tree
  property current
  property depth
  property visitor

  func constructor(visitor) {
    @visitor = visitor
    @depth = 0

    const title = "Charly [" + Charly.COMPILE_COMMIT + "] Unit Testing Framework"

    @current = Node(title, NodeType.Root)
    @tree = @current

    @visitor.on_root(@current)
  }

  func add_node(type, title, callback) {
    @depth += 1

    const new = Node(title, type)
    const backup = @current
    @current.push(new, @depth)
    @current = new

    try {
      @visitor.on_node(@current, @depth, callback)
    } catch(e) {
      @catch_exception(e)
    }

    @current = backup

    @depth -= 1
    self
  }

  func suite(title, callback) {
    @add_node(NodeType.Suite, title, callback)
  }

  func it(title, callback) {
    @add_node(NodeType.Test, title, callback)
  }

  func assert(real, expected) {
    const assertion = Assertion(real, expected)

    @current.push(
      assertion,
      @depth
    )

    @visitor.on_assertion(@current.length() - 1, assertion, @depth)
    self
  }

  func catch_exception(e) {
    @assert(e, "No exception to be thrown")
  }
}

export = Context
