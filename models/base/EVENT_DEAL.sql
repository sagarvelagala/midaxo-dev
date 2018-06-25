with
  dealcreate as (
    select
      null as contact_id,
      a.company_id as company_id,
      a.createdate::timestamp_ntz as eventdate,
      'deal_created' as eventtype,
      'na' as eventaction,
      a.owner_id::varchar as eventsource
    from {{ref('DEAL')}} a
    where a.company_id is not null
  ),
  dealclose as(
    select
       null as contact_id,
       b.company_id as company_id,
       b.closedate::timestamp_ntz as eventdate,
       'deal_closed' as event_type,
       case
         when contains(lower(b.pipeline_stage), 'won') then 'won'
         else 'lost'
       end as event_action,
       b.owner_id::varchar as event_source
     from {{ref('DEAL')}} b
     where contains(lower(b.pipeline_stage), 'closed')
       and b.company_id is not null
       and to_date(b.closedate) <= current_date
  )

select * from dealcreate
union
select * from dealclose
