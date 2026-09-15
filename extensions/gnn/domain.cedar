// gnn domain

@id("gnn.op.message_pass")
permit (principal, action == Action::"message_pass", resource)
when { context.domain == "gnn" };

@id("gnn.op.aggregate")
permit (principal, action == Action::"aggregate", resource)
when { context.domain == "gnn" };
