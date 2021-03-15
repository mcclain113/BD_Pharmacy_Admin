WITH marseq ("ordid", "Date-Time Start of Administrationcte", "rankcte" )as (
    select  DISTINCT

        mar.ORDER_MED_ID "ORDID",
        mar.TAKEN_TIME "Date-Time Start of Administrationcte",
        DENSE_RANK() OVER (PARTITION BY mar.ORDER_MED_ID ORDER BY mar.TAKEN_TIME)  "RANK"

    from MAR_ADMIN_INFO mar
             left outer join ORDER_STATUS ord
                             ON mar.ORDER_MED_ID = ord.ORDER_ID

    WHERE ord.CONTACT_TYPE_C = '7' AND mar.MAR_ACTION_C IN (1))




SELECT DISTINCT
              --ROW_NUMBER() OVER (PARTITION BY maradmin.ORDER_MED_ID ORDER BY ord.CONTACT_NUMBER) "RANK"
    case when pathsp.HOSPITAL_AREA_ID is not null then fac.LOC_NAME
         else 'NULL' end "Facility Name"

              ,maradmin.MAR_ENC_CSN "Patient Encounter Number"
              ,case when maradmin.MAR_ENC_CSN is not null then pat.PAT_ID
                    else  'NULL' end "Patient ID"
              ,case when pat.PAT_ID is not null then patname.PAT_NAME
                    else 'NULL' end "Patient Name"

              ,case when patname.SEX_C = '1' then cast('F' as char)
                    when patname.SEX_C = '2' then cast('M' as char)
                    when patname.SEX_C = '3' then cast('U' as char)
                    else 'O' end "Gender"

              ,format (patname.BIRTH_DATE, 'yyyy-MM-dd') "Date of Birth"

              ,case when maradmin.MAR_ENC_CSN is not null then pat.PAT_ID
                    else  'NULL' end "Patient ID"

              ,format (pat.HOSP_ADMSN_TIME,'yyyy-MM-dd hh:mm:ss') "Admission Date-Time"
              ,format (pat.HOSP_DISCHRG_TIME, 'yyyy-MM-dd hh:mm:ss') "Discharge Date-Time"

              ,case when pathsp.DEPARTMENT_ID is not null then dept.DEPARTMENT_NAME
                    else 'NULL' end "Patient Census Location"
    /*,case when pathsp.ROOM_ID is not null then ptroom.ROOM_NAME
        else 'NULL' end "Patient Census Room"*/
              ,case when pathsp.BED_ID is not null then bed.BED_LABEL
                    else 'NULL' end "Patient Census Bed"

              ,cast(maradmin.ORDER_MED_ID as varchar(100)) "Prescription Number"

              ,case when (maradmin.TAKEN_TIME = marseq.[Date-Time Start of Administrationcte]) AND (maradmin.ORDER_MED_ID = marseq.ordid) then cast(marseq.rankcte as varchar)
                    when (maradmin.TAKEN_TIME <> marseq.[Date-Time Start of Administrationcte]) AND (maradmin.ORDER_MED_ID <> marseq.ordid) then 'NULL'
                    else 'x' end "Administration Sequence"

              ,ordermed.MEDICATION_ID "Drug Ingredient Number"
              ,cast(maradmin.ORDER_MED_ID as varchar(100)) "Order Placer Number"

              ,format (maradmin.TAKEN_TIME,'yyyy-MM-dd hh:mm:ss') "Date-Time Start of Administration"
              --Administration Code Identifier needed; different from drug ingredient number?

              ,ordermed.DESCRIPTION "Administered Drug Description"
              ,CAST (maradmin.SIG AS numeric) "Administered Amount"
              ,case when maradmin.DOSE_UNIT_C is not null then medunit.NAME
                    else 'NULL' end "Administered Units"

              ,case when maradmin.ROUTE_C is not null then medrt.NAME
                    else 'NULL' end "Route of Administration"

              ,case when maradmin.MAR_ACTION_C = '1' then cast ('CP' as char)
                    when maradmin.MAR_ACTION_C = '3' then cast ('RE' as char)
                    when maradmin.MAR_ACTION_C in (2, 4, 5, 10, 11, 98, 99) then cast('NA' as char)
                    when maradmin.MAR_ACTION_C in (8, 16) then cast('PA' as char)
                    else 'NULL' end "Completion Status"
              --need to account for infusion actions (6 New Bag, 7 Restarted, 9 Rate Change, 12 Bolus, 14 Rate Verify, 15 See Alternative, 100 Due)

              ,maradmin.USER_ID "Administering Provider ID"
              ,case when maradmin.USER_ID is not null then users.NAME
                    else 'NULL' end "Administering Provider Name"

from MAR_ADMIN_INFO maradmin
         left outer join PAT_ENC pat
                         on maradmin.MAR_ENC_CSN = pat.PAT_ENC_CSN_ID
         left outer join ORDER_MED ordermed
                         on maradmin.ORDER_MED_ID = ordermed.ORDER_MED_ID
         left outer join CLARITY_EMP users
                         on maradmin.USER_ID = users.USER_ID
         left outer join PATIENT patname
                         on pat.PAT_ID = patname.PAT_ID
         left outer join ZC_MED_UNIT medunit
                         on maradmin.DOSE_UNIT_C = medunit.DISP_QTYUNIT_C
         left outer join ZC_ADMIN_ROUTE medrt
                         on maradmin.ROUTE_C = medrt.MED_ROUTE_C
         left outer join ZC_SEX sex
                         on patname.SEX_C = sex.RCPT_MEM_SEX_C
         left outer join PAT_ENC_HSP pathsp
                         on pathsp.PAT_ID = patname.PAT_ID
         left outer join CLARITY_DEP dept
                         on pathsp.DEPARTMENT_ID = dept.DEPARTMENT_ID
/*left outer join ED_ROOM_INFO ptroom
	on pathsp.ROOM_ID = ptroom.ROOM_ID*/
         left outer join CLARITY_BED bed
                         on pathsp.BED_ID = bed.BED_ID
         left outer join CLARITY_LOC fac
                         on pathsp.HOSPITAL_AREA_ID = FAC.LOC_ID
         left outer join marseq
                         on marseq.ordid = ordermed.ORDER_MED_ID
         left outer join ORDER_STATUS ord
                         ON maradmin.ORDER_MED_ID = ord.ORDER_ID

WHERE pat.HOSP_ADMSN_TIME <= CURRENT_TIMESTAMP
  and ord.CONTACT_TYPE_C = '7' AND maradmin.MAR_ACTION_C IN (1)
  AND (case when (maradmin.TAKEN_TIME = marseq.[Date-Time Start of Administrationcte]) AND (maradmin.ORDER_MED_ID = marseq.ordid) then cast(marseq.rankcte as varchar)
            when (maradmin.TAKEN_TIME <> marseq.[Date-Time Start of Administrationcte]) AND (maradmin.ORDER_MED_ID <> marseq.ordid) then 'NULL'
            else 'x' end) <> 'x'

ORDER BY
    "Prescription Number", "Administration Sequence"