# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
psql socki_development

ALTER SCHEMA public OWNER TO socki;
GRANT ALL ON SCHEMA public TO socki;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO socki;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO socki;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO socki;
\q

psql socki_test

repeat


Discipline
  └─ Season
       └─ Competition
            └─ Category
                 ├─ Shiajo (live area)
                 ├─ Match
                 └─ Competitor (registered in this category)