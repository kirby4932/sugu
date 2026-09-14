create table AppState
(
    auto_app_state_id int auto_increment
        primary key,
    details           text null,
    state             text null
);

create index idx_appstate_lookup
    on AppState (state(128), details(128));

create table Application
(
    auto_app_id int auto_increment
        primary key,
    name        text   null,
    app_id      bigint null,
    constraint app_id
        unique (app_id)
);

create index idx_application_name
    on Application (name(768));

create table Status
(
    auto_status_id int auto_increment
        primary key,
    type           text null,
    constraint type
        unique (type) using hash
);

create table Type
(
    auto_type_id int auto_increment
        primary key,
    type         text null
);

create index idx_type_type
    on Type (type(768));

create table User
(
    auto_user_id int auto_increment
        primary key,
    username     text   null,
    user_id      bigint null,
    constraint user_id
        unique (user_id)
);

create table Activity
(
    auto_activity_id  int auto_increment
        primary key,
    auto_app_id       int          null,
    auto_user_id      int          null,
    auto_status_id    int          null,
    auto_app_state_id int          null,
    auto_type_id      int          null,
    starttime         timestamp    null,
    endtime           timestamp    null,
    party_id          varchar(255) null,
    party_size        int          null,
    party_max         int          null,
    constraint Activity_ibfk_1
        foreign key (auto_app_id) references Application (auto_app_id),
    constraint Activity_ibfk_2
        foreign key (auto_user_id) references User (auto_user_id),
    constraint Activity_ibfk_3
        foreign key (auto_status_id) references Status (auto_status_id),
    constraint Activity_ibfk_4
        foreign key (auto_app_state_id) references AppState (auto_app_state_id),
    constraint Activity_ibfk_5
        foreign key (auto_type_id) references Type (auto_type_id)
);

create index idx_activity_app_user
    on Activity (auto_app_id, auto_user_id);

create index auto_app_state_id
    on Activity (auto_app_state_id);

create index auto_status_id
    on Activity (auto_status_id);

create index auto_user_id
    on Activity (auto_user_id);

create index idx_activity_listening_lookup
    on Activity (auto_type_id, auto_app_id, auto_user_id, starttime, endtime, auto_app_state_id);

create index idx_activity_playing_lookup
    on Activity (auto_type_id, auto_user_id, auto_app_id, starttime);

create index idx_user_username
    on User (username(768));


