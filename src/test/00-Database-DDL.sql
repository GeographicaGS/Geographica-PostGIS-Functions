-- Creates the test database

\c postgres

create database test;

\c test

create extension postgis;

begin;

create schema import;

commit;
