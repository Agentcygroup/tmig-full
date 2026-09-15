// symbolic domain

@id("symbolic.op.unify")
permit (principal, action == Action::"unify", resource)
when { context.domain == "symbolic" };

@id("symbolic.op.prove")
permit (principal, action == Action::"prove", resource)
when { context.domain == "symbolic" };
