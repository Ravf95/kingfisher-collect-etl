

delete from ocds.award where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

delete from ocds.award_items where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

delete from ocds.tender_items where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

delete from ocds.contract where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

delete from ocds.parties where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

delete from ocds.procurement where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

delete from ocds.second_stage_invitations where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

delete from ocds.second_stage_invitations_items where data_id in (
select a.data_id from ocds.procurement a
join ocds.procurement b on a.ocid = b.ocid and a.id < b.id);

refresh materialized view ocds.unique_suppliers;

create table if not exists ocds.precios_pre_pandemia as (
    select avg(ai.unit_price)             as promedio,
           ai.classification_id,
           ai.attributes -> 1 ->> 'value' as presentacion,
           ai.unit_name,
           ai.unit_price_currency
    from ocds.award_items as ai
             join ocds.procurement as t on t.ocid = ai.ocid
    where t.tender_date_published < '2020-03-01'
    group by ai.classification_id, ai.attributes -> 1 ->> 'value', ai.unit_name, ai.unit_price_currency
);

 delete from ocds.data;
