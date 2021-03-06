with 
  events as (
    select 
      a.eventdate,
      a.company_id,
      a.contact_id,
      a.event_type,
      a.event_action,
      a.event_source,
      case
        when a.event_type in ('form','chat') then 'inbound'
        when a.event_type in ('sales_email','sales_call','meeting') then 'outbound'
        when a.event_owner_campaign_url ilike '%demo follow-up%' then 'inbound'
        when a.event_owner_campaign_url ilike '%webinar%' then 'inbound'
        --when a.event_type in ('marketing_email') then 'marketing'
        else 'other'
      end as event_category,
      a.company_event_no,
      a.contact_event_no
    from MIDAXO.DEV.EVENT_TIMELINE a
    where a.company_event_no = 1 or a.contact_event_no = 1
  ),

  company as (
    select
      c.id as company_id,
      c.property_country as country,
      c.property_is_icp as icp,
      c.property_icp_score as icp_score
    from raw.hubspot.company c
  )  

select
to_date(e.eventdate) as eventdate,
e.event_type,
e.event_action,
e.event_source,
e.event_category,
c.country,
case 
  when  icp_score is null then 'non-icp'
  else icp_score
end as icp,
sum(case when e.company_event_no = 1 then 1 else 0 end) as new_account_conversion,
sum(case when e.contact_event_no = 1 then 1 else 0 end) as new_contact_conversion
from events e
left join company c
  on c.company_id = e.company_id
where last_day(eventdate,'month') > dateadd('month',-15,last_day(current_date,'month'))
group by eventdate, e.event_type, e.event_action, e.event_source, e.event_category, c.country, c.icp_score
