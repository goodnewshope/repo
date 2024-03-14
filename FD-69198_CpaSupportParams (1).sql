SELECT DISTINCT TOP 1000 t.taskid,
                         de.NAME                                   AS
                         docketEntryName,
                         de.computedduedate,
                         det.NAME                                  AS
                         docketEntryType,
                         de.docketentryid,
                         de.docketentrytypeid,
                         t.NAME                                    AS docketName
                         ,
                         t.notes
                         AS docketTaskNotes,
                         t.completiondate                          AS
                         docketCompletionDate,
                         t.matterid,
                         m.title                                   AS
                         matterTitle,
                         t.activityid,
                         t.activityname,
                         t.type                                    AS taskType,
                         t.subtype                                 AS
                         taskSubType,
                         m.countryname,
                         m.hostmatterno                            AS matterNo,
                         m.serialnumber                            AS serialNo,
                         m.fmtserialno                             AS
                         fmtSerialNo,
                         m.creatororgid,
                         m.mattertypeid,
                         t.verificationdate                        AS
                         docketVerificationDate,
                         t.abandoneddate                           AS
                         docketAbandonedDate,
                         td.registrationdate                       AS
                         dbRegistrationDate,
                         td.registrationno                         AS
                         registrationNumber,
                         a.notes                                   AS
                         activityComments,
                         a.code                                    AS
                         activityCode,
                         Isnull(tem.iskeytemplate, 0)              AS keyTask,
                         t.immutable,
                         t.isprototype                             AS
                         prototypeTask,
                         m.stageid,
                         s.description                             AS
                         matterStatus,
                         p.patentno                                AS
                         patentNumber,
                         (SELECT TOP 1 CASE
                                         WHEN orgprofile.opid IS NOT NULL THEN
                                         orgprofile.orgname
                                         WHEN personprofile.ppid IS NOT NULL
                                       THEN Rtrim(
                                         Rtrim(COALESCE(personprofile.fname, N''
                                         ) + N' ' +
                                             COALESCE(
                                         personprofile.mname,
                                         N''))
                                         + N' ' + COALESCE(personprofile.lname,
                                         N''))
                                         ELSE N''
                                       END
                          FROM   matterparticipant
                                 LEFT OUTER JOIN personprofile
                                              ON matterparticipant.contactid =
                                                 personprofile.ppid
                                 LEFT OUTER JOIN orgprofile
                                              ON matterparticipant.contactid =
                                                 orgprofile.opid
                          WHERE  matterparticipant.matterid = m.matterid
                                 AND matterparticipant.roleid =
                                     (SELECT
                                     dispmatsrchroleid
                                                                 FROM
                                     orgpreference
                                                                 WHERE
                                     orgid = m.creatororgid)
                          ORDER  BY matterparticipant.roleorderno) AS
                         matterEntityName,
                         (SELECT TOP 1 COALESCE(matterno, N'')
                          FROM   matterparticipant mp
                          WHERE  mp.matterid = m.matterid
                                 AND mp.roleid = (SELECT dispmatsrchroleid
                                                  FROM   orgpreference
                                                  WHERE  orgid = m.creatororgid)
                          ORDER  BY roleorderno)                   AS
                         matterEntityNumber,
                         (SELECT issuedate
                          FROM   (SELECT matterid,
                                         issuedate
                                  FROM   patent
                                  UNION
                                  SELECT matterid,
                                         issuedate
                                  FROM   plantvariety) AS CombinedData
                          WHERE  matterid = t.matterid)            AS
                         dbIssueDate
FROM   task t
       INNER JOIN matter m
               ON t.matterid = m.matterid
       INNER JOIN activity a
               ON a.activityid = t.activityid
       INNER JOIN docketentry de
               ON t.taskid = de.taskid
       INNER JOIN docketentrytype det
               ON de.docketentrytypeid = det.docketentrytypeid
       INNER JOIN stage s
               ON s.stageid = m.stageid
       LEFT JOIN template tem
              ON t.createdfromtemplateid = tem.templateid
       LEFT JOIN trademark td
              ON t.matterid = td.matterid
       LEFT JOIN patent p
              ON t.matterid = p.matterid
       CROSS apply (SELECT activity.activityid,
                           userrelatedcontact.userid,
                           activity.code
                    FROM   userrelatedcontact
                           INNER JOIN matterparticipant
                                   ON userrelatedcontact.contactid =
                                      matterparticipant.contactid
                           INNER JOIN activity
                                   ON matterparticipant.matterid =
                                      activity.matterid
                                      AND ( activity.isprivate = 0
                                             OR userrelatedcontact.orgid =
                                                activity.orgid )
                    WHERE  activity.activityid = t.activityid
                           AND userrelatedcontact.userid = 633
                    UNION
                    SELECT activity.activityid,
                           userrelatedcontact.userid,
                           activity.code
                    FROM   userrelatedcontact
                           LEFT JOIN personprofile
                                  ON userrelatedcontact.contactid =
                                     personprofile.ppid
                           INNER JOIN activity
                                   ON ( activity.orgid =
                                        userrelatedcontact.orgid
                                         OR ( activity.orgid =
                                              personprofile.ppownerorgid
                                              AND activity.isprivate = 0 ) )
                    WHERE  activity.matterid IS NULL
                           AND activity.activityid = t.activityid
                           AND userrelatedcontact.userid = 633) userActIds
       CROSS apply (SELECT TOP 1 opid
                    FROM   vworglistformatter v
                    WHERE  v.matterid = m.matterid
                           AND v.opid IN ( 39964,
43410,
44800,
45254,
50204,
52714,
56712 )) orgListForMatter
WHERE  m.isdeleted = 0
       AND m.creatororgid = 3292
       AND de.computedduedate >= '03/13/2010'
       AND de.computedduedate < '03/13/2024'
       AND de.docketentrytypeid IN ( 1,3,2)
ORDER  BY computedduedate ASC 