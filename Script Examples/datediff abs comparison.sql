/* looking at date difference vs abs val datediff */


select * from
(
select incidentdimvw.id, incidentdimvw.CreatedDate, incidentdimvw.ResolvedDate
	,datedifff = DATEDIFF(minute, incidentdimvw.CreatedDate, incidentdimvw.ResolvedDate)
	,datedifff2 = DATEDIFF(minute, incidentdimvw.ResolvedDate, incidentdimvw.CreatedDate)
	,abs_datediff = abs(DATEDIFF(minute, incidentdimvw.CreatedDate, incidentdimvw.ResolvedDate))
	,tierqueue_incidenttierqueuesid
	,IncidentTierQueuesvw.incidenttierqueuesvalue
from incidentdimvw
	join IncidentTierQueuesvw on incidentdimvw.tierqueue_incidenttierqueuesid = incidenttierqueuesvw.incidenttierqueuesid
where ResolvedDate between '2017-07-07' and '2017-08-01'
)
x
where datedifff <> abs_datediff
