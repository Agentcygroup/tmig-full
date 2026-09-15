// forecasting domain

@id("forecasting.op.forecast")
permit (principal, action == Action::"forecast", resource)
when { context.domain == "forecasting" };

@id("forecasting.op.backtest")
permit (principal, action == Action::"backtest", resource)
when { context.domain == "forecasting" };
