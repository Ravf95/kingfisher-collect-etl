create schema if not exists ocds;

create table if not exists ocds.data
(
    data       jsonb,
    release_id text,
    ocid       text,
    id         bigserial not null
);

create index if not exists ix_data_1a2253436964eea9
    on ocds.data (release_id);

create index if not exists ix_data_fbe00273b81f8a04
    on ocds.data (release_id, ocid);


create table if not exists ocds.procurement
(
    release_date                          timestamp,
    ocid                                  text,
    tender_id                             text,
    characteristics                       jsonb,
    tender_amount                         numeric,
    budget_amount                         numeric,
    budget_currency                       text,
    tender_currency                       text,
    tender_date_published                 timestamp,
    planning_estimated_date               timestamp,
    tender_enquiryperiod_start_date       timestamp,
    tender_enquiryperiod_end_date         timestamp,
    tender_tenderperiod_end_date          timestamp,
    tender_tenderperiod_start_date        timestamp,
    tender_procurementmethoddetails       text,
    buyer_name                            text,
    buyer_id                              text,
    tender_bidopening_date                timestamp,
    tender_awardcriteria_details          text,
    tender_status                         text,
    tender_status_details                 text,
    tender_title                          text,
    tender_mainprocurementcategorydetails text,
    tender_numberoftenderers              text,
    analyzed                              boolean,
    number_of_awards                      integer,
    framework_agreement                   boolean,
    electronic_auction                    boolean,
    budget                                jsonb,
    documents                             jsonb,
    tender_numberofenquiries              integer,
    url                                   text,
    id                                    bigserial not null
        constraint procurement_pk
            primary key,
    data_id                               bigint
);

create table if not exists ocds.parties
(
    ocid                    text,
    party_id                text,
    name                    text,
    contact_point_email     text,
    contact_point_name      text,
    contact_point_telephone text,
    contact_point_fax       text,
    roles                   jsonb,
    entity_level            text,
    entity_entity_type      text,
    entity_type             text,
    supplier_type           text,
    address_country          text,
    address_locality        text,
    address_region          text,
    address_street          text,
    id                      bigserial not null
        constraint parties_pk
            primary key,
    data_id                 bigint
);

create table if not exists ocds.award
(
    ocid          text,
    award_id      text,
    date          timestamp,
    amount        numeric,
    currency      text,
    status        text,
    status_details        text,
    supplier_id   text,
    supplier_name text,
    documents     jsonb,
    buyer_id      text,
    buyer_name    text,
    id            bigserial not null
        constraint award_pk
            primary key,
    data_id       bigint
);

create table if not exists ocds.contract
(
    ocid             text,
    contract_id      text,
    award_id         text,
    date_signed      timestamp,
    amount           numeric,
    currency         text,
    status           text,
    status_details           text,
    duration_in_days numeric,
    start_date       timestamp,
    end_date         timestamp,
    budget           jsonb,
    documents        jsonb,
    id               bigserial not null
        constraint contract_pk
            primary key,
    data_id          bigint
);

create table if not exists ocds.tender_items
(
    ocid                       text,
    item_id                    text,
    description                text,
    classification_id          text,
    classification_description text,
    quantity                   numeric,
    unit_name                  text,
    unit_price                 numeric,
    unit_price_currency        text,
    attributes                 jsonb,
    lot                        text,
    id                         bigserial not null
        constraint tender_items_pk
            primary key,
    data_id                    bigint
);

create table if not exists ocds.award_items
(
    ocid                       text,
    award_id                   text,
    item_id                    text,
    description                text,
    classification_id          text,
    classification_description text,
    quantity                   numeric,
    unit_name                  text,
    unit_price                 numeric,
    unit_price_currency        text,
    attributes                 jsonb,
    lot                        text,
    id                         bigserial not null
        constraint award_items_pk
            primary key,
    data_id                    bigint
);

create table if not exists ocds.second_stage_invitations
(
    ocid                                  text,
    invitations_id                        text,
    id                                    bigserial not null,
    title                                 text,
    status                                text,
    award_criteria                        text,
    award_criteriadetails                 text,
    submission_methoddetails              text,
    status_details                        text,
    numberofnotifiedsuppliers             numeric,
    mainprocurementcategorydetails        text,
    date_published                        timestamp,
    amount                                numeric,
    currency                              text,
    submission_period_start_date          timestamp,
    submission_period_end_date            timestamp,
    award_period_start_date               timestamp,
    award_period_end_date                 timestamp,
    numberofenquiries                     numeric,
    procurementmethod                     text,
    procurementmethoddetails              text,
    numberofsubmitters                    numeric,
    framework_agreement                   boolean,
    electronic_auction                    boolean,
    buyer_id                              text,
    buyer_name                            text,
    bidopening_date                       timestamp,
    clarification_meetings_date           timestamp,
    characteristics                       text,
    documents                             jsonb,
    data_id                               bigint,
    url                                   text,
    constraint second_stage_invitations_pk PRIMARY KEY (id)
);

create table if not exists ocds.second_stage_invitations_items
(
    ocid                                 text,
    invitations_id                       text,
    id                                   bigserial not null,
    item_id                              text,
    description                          text,
    classification_id                    text,
    classification_description           text,
    quantity                             numeric,
    unit_name                            text,
    unit_price                           numeric,
    unit_price_currency                  text,
    attributes                           jsonb,
    lot                                  text,
    data_id                              bigint,
    constraint second_stage_invitations_items_pk PRIMARY KEY (id)
);

CREATE MATERIALIZED VIEW IF NOT EXISTS ocds.unique_suppliers AS
(
SELECT DISTINCT parties.name                                  AS name,
                replace(party_id, 'PY-RUC-'::text, ''::text) AS ruc,
                regexp_replace(parties.contact_point_telephone, '[^0-9]+'::text,
                               ''::text, 'g'::text)                                      AS telephone,
                parties.contact_point_name         AS contact_point,
                parties.address_country       AS pais,
                parties.address_region     AS departamento,
                parties.address_locality   AS ciudad,
                parties.address_street     AS direccion
FROM ocds.parties as parties
WHERE NOT parties.roles ? 'buyer'::text
  AND NOT parties.roles ? 'procuringEntity'::text
  AND NOT parties.roles ? 'payer'::text
  AND parties.party_id ~~ 'PY-RUC-%'::text );

alter table ocds.procurement add column if not exists tender_procurementmethod text;
alter table ocds.procurement add column if not exists second_stage boolean;
