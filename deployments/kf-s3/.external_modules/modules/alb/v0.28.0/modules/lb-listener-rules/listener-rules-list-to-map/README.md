# Helper module to map user input to for_each

This module remaps a list of rules objects into a map that flattens out the objects by load balancer listener ARNs that
the rule applies to.

This module is not meant to be used directly, and should be called through the `lb-listener-rules` module.
