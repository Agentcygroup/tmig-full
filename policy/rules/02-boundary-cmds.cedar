// These commands are never executed, by any principal.
@id("policy.rule.boundary")
forbid (
    principal,
    action == Action::"exec",
    resource
)
when {
    context.cmd like "*python -m http.server*"  ||
    context.cmd like "*python3 -m http.server*" ||
    context.cmd like "*nc -l*"                  ||
    context.cmd like "*socat TCP-LISTEN*"       ||
    context.cmd like "*postgres *"              ||
    context.cmd like "*mysqld*"                 ||
    context.cmd like "*mongod*"                 ||
    context.cmd like "*redis-server*"
};
