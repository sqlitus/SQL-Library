/* parameter default value query - Last 13 full Fiscal Weeks */

select
	 Last13WeekMonday = DATEADD(dd,  0, DATEADD(ww, DATEDIFF(ww, 0, DATEADD(dd, -1, CURRENT_TIMESTAMP)) - 13, 0))
	 , LastWeekMonday = DATEADD(dd,  0, DATEADD(ww, DATEDIFF(ww, 0, DATEADD(dd, -1, CURRENT_TIMESTAMP)) - 1, 0))
	 , LastWeekSunday = DATEADD(dd,  6, DATEADD(ww, DATEDIFF(ww, 0, DATEADD(dd, -1, CURRENT_TIMESTAMP)) - 1, 0))
	 
