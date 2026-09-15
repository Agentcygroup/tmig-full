// Units are the atomic operations the reconciler executes.
// Every unit is a Request against this policy before it runs.
//
// Principal is always Principal::"reconcile".
// Action is the unit kind: "install", "service", "file", "exec".
// Resource is the unit name.
// Context carries: host, recipe, cmd (for exec units).

// A unit is denied unless the host is one we sign for.
@id("infra.host.allow")
permit (
    principal == Principal::"reconcile",
    action,
    resource
)
when {
    context.host in ["Dannys-MacBook-Pro", "metadusa-m4", "localhost"]
};

// No exec unit may run anything matching the boundary list.
@id("infra.exec.boundary")
forbid (
    principal == Principal::"reconcile",
    action == Action::"exec",
    resource
)
when {
    context.cmd like "*python -m http.server*" ||
    context.cmd like "*python3 -m http.server*" ||
    context.cmd like "*nc -l*" ||
    context.cmd like "*socat TCP-LISTEN*" ||
    context.cmd like "*postgres *" ||
    context.cmd like "*mysqld*" ||
    context.cmd like "*mongod*" ||
    context.cmd like "*redis-server*"
};

// Nothing may write outside the host's declared sandbox.
@id("infra.file.sandbox")
forbid (
    principal == Principal::"reconcile",
    action == Action::"file",
    resource
)
when {
    !(context.path like "/Users/metadusa/*" ||
      context.path like "/opt/tmig/*" ||
      context.path like "/tmp/tmig-*")
};
