Subject: FullTextSearch proc causing high CPU load – proposal to improve

Hi [Manager's Name],

I wanted to highlight a recurring performance issue we've been seeing with the stored procedure called FullTextSearch. It's consistently showing up as one of the most resource-heavy operations on the server.

When I check the currently running top CPU-consuming queries, about 8 out of the top 10 are different sessions running this procedure. Individually, each execution looks quick, just a few milliseconds on average. But in aggregate, this one procedure is responsible for over 75 percent of the total CPU usage at times.

The core issue seems to be how the keyword search is handled. The procedure includes a WHERE clause with a pattern like ros.keywords LIKE '%keyword%'. That column is a concatenation of around 10 fields, including things like insurance claim number, insurance company name, VIN, repair order number, and several others.

Because the search starts with a wildcard, SQL Server can't use indexes effectively, and that leads to full scans. This isn’t a big issue for smaller repairers, because of the join to tblWorkerRepairFacility, which filters the data. But for users tied to many facilities, the search can take over a minute to complete.

Interestingly, when a third input parameter called status_id is supplied in addition to user_id and keyword, even for large repairers, the performance is much better. The query typically finishes in 6 to 7 seconds, which suggests there's a way to guide the plan generation or reduce the data early on.

Another issue is the keyword input field itself. It's completely open-ended, and I’ve seen values like “Hi Y’all due to some...” being passed in. That kind of freeform text increases the unpredictability of query patterns and adds unnecessary processing load.

From what I’ve observed, most users are searching using specific fields like insurance claim number, VIN, or repair order number. So, I’d like to propose simplifying the logic by focusing the search on just one or two of these fields directly. This would avoid the need for broad keyword scans and would allow us to leverage indexes properly.

I believe making this change could significantly reduce CPU usage, especially during peak times, and improve the responsiveness of the overall system. I’m happy to discuss this further or walk through the numbers if helpful.

Thanks,
