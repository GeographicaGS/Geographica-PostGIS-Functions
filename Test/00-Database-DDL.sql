-- Database for function testing
-- To be run inside Docker

create database test;

\c test

create extension postgis;

\i ../Vector.sql

\i ../Geometries.sql

create schema import;

