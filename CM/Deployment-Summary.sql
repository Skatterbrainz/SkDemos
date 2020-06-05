SELECT
	COALESCE(PackageName,AssignmentName) AS DeploymentName,
	PackageID,
	CollectionID,
	CollectionName,
	CollectionType,
	Success,
	Failed,
	InProgress,
	Unknown,
	Other,
	SummarizationTime
FROM (
	SELECT DISTINCT TOP 100 PERCENT
		ds.PackageID, pkg.Name AS PackageName, ds.AssignmentID, asg.AssignmentName, ds.CollectionID,
		ds.CollectionName,
		case
			when dbo.v_Collection.CollectionType = 2 then 'Device'
			else 'User' end as CollectionType,
		ds.NumberTotal AS Total,
		ds.NumberSuccess AS Success, ds.NumberErrors AS Failed, ds.NumberInProgress AS InProgress,
		ds.NumberOther AS Other, ds.NumberUnknown AS Unknown, ds.SummarizationTime
	FROM
		v_DeploymentSummary AS ds INNER JOIN
		v_Collection ON ds.CollectionID = dbo.v_Collection.CollectionID LEFT OUTER JOIN
		v_CIAssignment AS asg ON ds.AssignmentID = asg.AssignmentID LEFT OUTER JOIN
		v_Package AS pkg ON ds.PackageID = pkg.PackageID
		--WHERE (ds.NumberErrors > 0)
	ORDER BY PackageName, asg.AssignmentName) AS T1
ORDER BY DeploymentName