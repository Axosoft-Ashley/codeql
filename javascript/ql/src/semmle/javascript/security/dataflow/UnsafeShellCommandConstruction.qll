/**
 * Provides a taint tracking configuration for reasoning about shell command
 * constructed from library input vulnerabilities (CWE-078).
 *
 * Note, for performance reasons: only import this file if
 * `UnsafeShellCommandConstruction::Configuration` is needed, otherwise
 * `UnsafeShellCommandConstructionCustomizations` should be imported instead.
 */

import javascript

/**
 * Classes and predicates for the shell command constructed from library input query.
 */
module UnsafeShellCommandConstruction {
  import UnsafeShellCommandConstructionCustomizations::UnsafeShellCommandConstruction

  /**
   * A taint-tracking configuration for reasoning about shell command constructed from library input vulnerabilities.
   */
  class Configuration extends TaintTracking::Configuration {
    Configuration() { this = "UnsafeShellCommandConstruction" }

    override predicate isSource(DataFlow::Node source) { source instanceof Source }

    override predicate isSink(DataFlow::Node sink) { sink instanceof Sink }

    override predicate isSanitizer(DataFlow::Node node) { node instanceof Sanitizer }

    override predicate isSanitizerGuard(TaintTracking::SanitizerGuardNode guard) {
      guard instanceof PathExistsSanitizerGuard or
      guard instanceof TaintTracking::AdHocWhitelistCheckSanitizer
    }

    // override to require that there is a path without unmatched return steps
    override predicate hasFlowPath(DataFlow::SourcePathNode source, DataFlow::SinkPathNode sink) {
      super.hasFlowPath(source, sink) and
      exists(DataFlow::MidPathNode mid |
        source.getASuccessor*() = mid and
        sink = mid.getASuccessor() and
        mid.getPathSummary().hasReturn() = false
      )
    }

    override predicate isAdditionalTaintStep(DataFlow::Node pred, DataFlow::Node succ) {
      // flow-step from a property written in the constructor to a use in an instance method.
      // "simulates" client usage of a class, and regains some flow-steps lost by `hasFlowPath` above.
      exists(DataFlow::ClassNode clz, string name |
        pred =
          DataFlow::thisNode(clz.getConstructor().getFunction()).getAPropertyWrite(name).getRhs() and
        succ = DataFlow::thisNode(clz.getInstanceMethod(_).getFunction()).getAPropertyRead(name)
      )
    }
  }
}
