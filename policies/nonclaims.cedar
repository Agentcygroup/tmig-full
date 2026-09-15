// Schema layers without a non-claim fail. The freeze rewriter tags
// such layers as "schema:NAME" in the layer field; we require they
// carry a non-empty cmd, which is how a non-claim is emitted.
forbid (principal, action, resource)
when {
    context.layer like "schema:*" &&
    context.cmd == ""
};
