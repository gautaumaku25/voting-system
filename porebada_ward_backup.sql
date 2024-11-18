--
-- PostgreSQL database dump
--

-- Dumped from database version 17.1
-- Dumped by pg_dump version 17.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- Name: update_llg_summary(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_llg_summary() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN PERFORM dblink_connect('llg_conn', 'host=localhost dbname=hiri_llg user=postgres password=Philly22061998@@@'); PERFORM dblink_exec('llg_conn', format('UPDATE llg_summary SET total_population = %s, total_households = %s, ward_count = %s, last_updated = CURRENT_TIMESTAMP', (SELECT COALESCE(SUM(population), 0) FROM wards), (SELECT COALESCE(SUM(households), 0) FROM wards), (SELECT COUNT(*) FROM wards) ) ); PERFORM dblink_disconnect('llg_conn'); RETURN NEW; END; $$;


ALTER FUNCTION public.update_llg_summary() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: porebada_east_female; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_east_female (
    seq integer,
    electoral_id character varying(10),
    name character varying(100),
    gender character(1),
    location character varying(100),
    occupation character varying(50),
    dob text
);


ALTER TABLE public.porebada_east_female OWNER TO postgres;

--
-- Name: porebada_east_male; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_east_male (
    seq integer,
    electoral_id character varying(10),
    name character varying(100),
    gender character(1),
    location character varying(100),
    occupation character varying(50),
    dob text
);


ALTER TABLE public.porebada_east_male OWNER TO postgres;

--
-- Name: porebada_west_male_female; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_west_male_female (
    seq integer,
    electoral_id character varying(10),
    name character varying(100),
    gender character(1),
    location character varying(100),
    occupation character varying(50),
    dob text
);


ALTER TABLE public.porebada_west_male_female OWNER TO postgres;

--
-- Name: porebada_ward_demographics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.porebada_ward_demographics AS
 WITH combined_data AS (
         SELECT 'east'::text AS ward_id,
            porebada_east_female.gender,
            (porebada_east_female.dob)::date AS dob,
            porebada_east_female.location
           FROM public.porebada_east_female
        UNION ALL
         SELECT 'east'::text AS ward_id,
            porebada_east_male.gender,
            (porebada_east_male.dob)::date AS dob,
            porebada_east_male.location
           FROM public.porebada_east_male
        UNION ALL
         SELECT 'west'::text AS ward_id,
            porebada_west_male_female.gender,
            (porebada_west_male_female.dob)::date AS dob,
            porebada_west_male_female.location
           FROM public.porebada_west_male_female
        )
 SELECT ward_id,
    count(*) AS total_population,
    count(
        CASE
            WHEN (gender = 'M'::bpchar) THEN 1
            ELSE NULL::integer
        END) AS male_population,
    count(
        CASE
            WHEN (gender = 'F'::bpchar) THEN 1
            ELSE NULL::integer
        END) AS female_population,
    count(
        CASE
            WHEN (EXTRACT(year FROM age((to_date('15-Nov-2024'::text, 'DD-Mon-YYYY'::text))::timestamp with time zone, (dob)::timestamp with time zone)) < (15)::numeric) THEN 1
            ELSE NULL::integer
        END) AS age_0_14,
    count(
        CASE
            WHEN ((EXTRACT(year FROM age((to_date('15-Nov-2024'::text, 'DD-Mon-YYYY'::text))::timestamp with time zone, (dob)::timestamp with time zone)) >= (15)::numeric) AND (EXTRACT(year FROM age((to_date('15-Nov-2024'::text, 'DD-Mon-YYYY'::text))::timestamp with time zone, (dob)::timestamp with time zone)) <= (64)::numeric)) THEN 1
            ELSE NULL::integer
        END) AS age_15_64,
    count(
        CASE
            WHEN (EXTRACT(year FROM age((to_date('15-Nov-2024'::text, 'DD-Mon-YYYY'::text))::timestamp with time zone, (dob)::timestamp with time zone)) >= (65)::numeric) THEN 1
            ELSE NULL::integer
        END) AS age_65_plus,
    count(DISTINCT location) AS areas,
    0 AS household_count,
    0.0 AS avg_household_size,
    0.0 AS population_density,
    to_date('15-Nov-2024'::text, 'DD-Mon-YYYY'::text) AS last_census_date
   FROM combined_data
  GROUP BY ward_id;


ALTER VIEW public.porebada_ward_demographics OWNER TO postgres;

--
-- Name: porebada_ward_economics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_ward_economics (
    ward_id integer NOT NULL,
    primary_economic_activity character varying(100),
    employment_rate numeric(5,2),
    avg_household_income numeric(10,2),
    poverty_rate numeric(5,2),
    small_businesses_count integer,
    market_centers_count integer
);


ALTER TABLE public.porebada_ward_economics OWNER TO postgres;

--
-- Name: porebada_ward_education; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_ward_education (
    ward_id integer NOT NULL,
    elementary_schools integer,
    high_schools integer,
    vocational_centers integer,
    total_students integer,
    teacher_count integer,
    literacy_rate numeric(5,2),
    school_attendance_rate numeric(5,2)
);


ALTER TABLE public.porebada_ward_education OWNER TO postgres;

--
-- Name: porebada_ward_geography; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_ward_geography (
    ward_id integer NOT NULL,
    latitude numeric(10,8),
    longitude numeric(11,8),
    total_area_sqkm numeric(10,2),
    terrain_type character varying(50),
    elevation_meters numeric(7,2),
    boundary_geojson json
);


ALTER TABLE public.porebada_ward_geography OWNER TO postgres;

--
-- Name: porebada_ward_health; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_ward_health (
    ward_id integer NOT NULL,
    health_centers integer,
    aid_posts integer,
    medical_staff_count integer,
    vaccination_rate numeric(5,2),
    maternal_mortality_rate numeric(5,2),
    infant_mortality_rate numeric(5,2),
    life_expectancy numeric(5,2)
);


ALTER TABLE public.porebada_ward_health OWNER TO postgres;

--
-- Name: porebada_ward_infrastructure; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.porebada_ward_infrastructure (
    ward_id integer NOT NULL,
    road_length_km numeric(10,2),
    paved_roads_percent numeric(5,2),
    water_access_percent numeric(5,2),
    electricity_access_percent numeric(5,2),
    internet_coverage_percent numeric(5,2),
    public_buildings_count integer
);


ALTER TABLE public.porebada_ward_infrastructure OWNER TO postgres;

--
-- Data for Name: porebada_east_female; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_east_female (seq, electoral_id, name, gender, location, occupation, dob) FROM stdin;
1	20217356	Again Arua Konio	F	POREBADA EAST	Household Duties	07-Jun-2002
2	20125728	Ahuta Muduka	F	POREBADA EAST	Pastor	06-May-1970
3	20217357	Aipo Jacklyn	F	POREBADA EAST	Household Duties	10-Oct-1990
4	20217358	Aisi Gari	F	POREBADA EAST	Household Duties	27-Dec-2002
5	20131408	Akia Kevau	F	POREBADA EAST	Household Duties	15-May-1960
6	20217359	Ako Kaia	F	POREBADA EAST	Self Employed	07-Jan-2000
7	20131279	Ako Vagi	F	POREBADA EAST	Household Duties	07-Dec-1997
8	20003414	ALAN DUAHI MATA	F	POREBADA EAST	Worker	15-May-1974
9	20131273	Anai Maria	F	POREBADA EAST	Household Duties	21-Apr-1999
10	20123350	Anai Arua REGINA	F	POREBADA EAST	Student	02-Jul-1994
11	20217363	Aniani Kari	F	POREBADA EAST	Household Duties	03-Dec-2000
12	20094417	Aniani Kevau	F	POREBADA EAST	Household Duties	06-Nov-1962
13	20094933	Aniani Mele	F	POREBADA EAST	Self Employed	15-Feb-1985
14	20064265	Aoae Agnes	F	POREBADA EAST	Household Duties	17-May-1972
15	20004232	ARAIDI ALICE	F	POREBADA EAST	Household Duties	21-Apr-1974
16	20005083	ARAIDI ELI	F	POREBADA EAST	Household Duties	14-Oct-1969
17	20004231	ARAIDI LOGEA	F	POREBADA EAST	Household Duties	10-Nov-1975
18	20123351	ARAIDI PORE	F	POREBADA EAST	Household Duties	11-May-1974
19	20217365	Araidi jnr Naomi	F	POREBADA EAST	Household Duties	04-Feb-2001
20	20124114	Arere Arere Asi	F	POREBADA EAST	Household Duties	13-Dec-1981
21	20131286	Arere Baia	F	POREBADA EAST	Household Duties	18-Nov-1992
22	20123352	Arere Boni	F	POREBADA EAST	Household Duties	24-Feb-1968
23	20090241	Arere Doreka	F	POREBADA EAST	Household Duties	01-Jan-1972
24	20124863	Arere Genevieve	F	POREBADA EAST	Household Duties	12-Sep-1964
25	20009080	ARERE GIMANA	F	POREBADA EAST	Unemployed	01-Jan-1992
26	20092793	Arere Henao Hebou	F	POREBADA EAST	Household Duties	01-Jan-1969
27	20005075	ARERE KAIA	F	POREBADA EAST	Unemployed	29-Nov-1971
28	20083676	Arere Kaia	F	POREBADA EAST	Unemployed	01-Jan-1987
29	20087422	Arere Kaia Mea	F	POREBADA EAST	Self Employed	12-Nov-1981
30	20008309	ARERE KILA	F	POREBADA EAST	Student	01-Jan-1992
31	20089712	Arere Kila Mea	F	POREBADA EAST	Secretary	22-Jun-1971
32	20090440	Arere Kumuku	F	POREBADA EAST	Subsistence Farmer	18-Jul-1988
33	20090278	Arere Laka Mea	F	POREBADA EAST	Worker	13-Jun-1980
34	20131282	Arere Lucy	F	POREBADA EAST	Journalist	29-Nov-1991
35	20054290	Arere Mary	F	POREBADA EAST	Teacher	05-Sep-1970
36	20076737	Arere Mea	F	POREBADA EAST	Household Duties	02-Apr-1967
37	20131283	Arere Rosemary	F	POREBADA EAST	Worker	26-Sep-1989
38	20131284	Arere Salona	F	POREBADA EAST	Worker	17-Jan-1994
39	20067970	Arere Sioro	F	POREBADA EAST	Household Duties	26-Aug-1961
40	20217367	Arere Dimere Karoho	F	POREBADA EAST	Household Duties	02-Jun-2003
41	20092796	Arere Hitolo Kaia	F	POREBADA EAST	Store Keeper	29-Nov-1971
42	20090456	Arere Hitolo Morea	F	POREBADA EAST	Subsistence Farmer	02-Feb-1983
43	20090454	Arere Hitoo Lohia	F	POREBADA EAST	Household Duties	27-Sep-1976
44	20022699	Arere Vagi Mea	F	POREBADA EAST	Household Duties	13-Dec-1990
45	20064687	Aria Shirley	F	POREBADA EAST	Household Duties	10-Aug-1974
46	20217369	Arua Boio	F	POREBADA EAST	Household Duties	25-Jun-1962
47	20008347	ARUA DAIRI MOMORU	F	POREBADA EAST	Household Duties	01-Jan-1970
48	20092298	Arua Elizabeth	F	POREBADA EAST	Household Duties	27-Jul-1984
49	20092784	Arua Esther	F	POREBADA EAST	Clerk	01-Jan-1968
50	9920130614	Arua Gabae	F	POREBADA EAST	Household Duties	16-Jul-1997
51	20009591	ARUA GEUA MAREVA	F	POREBADA EAST	Student	22-Jan-1988
52	20131373	Arua Hedaro	F	POREBADA EAST	Household Duties	26-Sep-1996
53	20058664	Arua Heni	F	POREBADA EAST	Household Duties	06-May-1969
54	20090497	Arua Kaia	F	POREBADA EAST	Household Duties	22-Feb-1964
55	20131344	Arua Kaia	F	POREBADA EAST	Household Duties	15-Jul-1998
56	20004691	ARUA KONIO	F	POREBADA EAST	Household Duties	01-Jan-1966
57	20008349	ARUA KONIO BARU	F	POREBADA EAST	Unemployed	01-Jan-1985
58	20003897	ARUA MAIRI	F	POREBADA EAST	Unemployed	01-Jan-1971
59	20008320	ARUA MEA	F	POREBADA EAST	Unemployed	02-Apr-1967
60	20123360	ARUA MERE	F	POREBADA EAST	Unemployed	26-Jan-1966
61	20124117	Arua Morea Sere	F	POREBADA EAST	Household Duties	18-Dec-1964
62	20123358	Arua Motu Morea	F	POREBADA EAST	Self Employed	27-Aug-1958
63	20131322	Arua Muraka	F	POREBADA EAST	Household Duties	16-Apr-1967
64	20124119	Arua Vele Ruta	F	POREBADA EAST	Self Employed	01-Jan-1970
65	20076602	Arua  Riu Morea	F	POREBADA EAST	Household Duties	12-Dec-1958
66	20031930	Arua Arere Naomi	F	POREBADA EAST	Household Duties	01-Jan-1980
67	20078730	Arua Auani Keruma	F	POREBADA EAST	Household Duties	18-Mar-1964
68	20004211	ARUA AUDA KARI	F	POREBADA EAST	Worker	10-Oct-1984
69	20003900	ARUA B GEUA	F	POREBADA EAST	Household Duties	01-Jan-1971
70	20031798	Arua Igo Geua	F	POREBADA EAST	Household Duties	05-Nov-1986
71	20008324	ARUA KARUA GEUA	F	POREBADA EAST	Household Duties	01-Jan-1971
72	20033619	Arua Karua Kari	F	POREBADA EAST	Household Duties	04-Nov-1967
73	20067579	Arua Koani Muraka	F	POREBADA EAST	Household Duties	16-Apr-1967
74	20004175	ARUA LAHUI LOGEA	F	POREBADA EAST	Sales Women	09-Jun-1993
75	20079162	Arua Lahui Ranu	F	POREBADA EAST	Household Duties	21-Jul-1971
76	20008325	ARUA SAMA HEAGI	F	POREBADA EAST	Student	01-Jan-1991
77	20033582	Arua Siage Maria	F	POREBADA EAST	Household Duties	13-Jul-1976
78	20092696	Arua Tara Sere	F	POREBADA EAST	Household Duties	26-Aug-1946
79	20094408	Arua Tau Jenny	F	POREBADA EAST	Household Duties	10-Jun-1968
80	20007261	ARUA TAUNAO BAIA	F	POREBADA EAST	Household Duties	18-Jul-1985
81	20124880	Asi Asi	F	POREBADA EAST	Household Duties	15-Mar-1988
82	20131310	Asi Auda	F	POREBADA EAST	Household Duties	27-Nov-1986
83	20130939	Asi Geua	F	POREBADA EAST	Household Duties	28-Aug-1997
84	20126023	Asi Kopi	F	POREBADA EAST	Self Employed	23-Sep-1948
85	20217372	Asi Tara	F	POREBADA EAST	Household Duties	05-Jul-1999
86	20007768	ASI WINNIE	F	POREBADA EAST	Worker	01-Jan-1988
87	20064253	Asi Arere Mauri	F	POREBADA EAST	Household Duties	10-Dec-1962
88	20079106	Asi Gau Bisi	F	POREBADA EAST	Household Duties	26-Sep-1986
89	20079123	Asi Heni Idau	F	POREBADA EAST	Household Duties	05-Sep-1952
90	20003602	ASI ISAIAH KERUMA	F	POREBADA EAST	Student	21-Jul-1993
91	20004615	ASI REI BOIO	F	POREBADA EAST	Household Duties	03-Nov-1988
92	20076728	Asi Rei Henao	F	POREBADA EAST	Self Employed	04-Jul-1981
93	20079179	Asi Seri Henao	F	POREBADA EAST	Household Duties	14-Jul-1959
94	20217373	Asi Virobo Lucy	F	POREBADA EAST	Household Duties	28-Apr-2004
95	20072956	Atara Kevau	F	POREBADA EAST	Household Duties	04-Nov-1973
96	20087405	Aua Daera	F	POREBADA EAST	Household Duties	12-Feb-1968
97	20131401	Aua Maggie Puro	F	POREBADA EAST	Household Duties	04-Aug-1975
98	20217374	Aua Mele	F	POREBADA EAST	Household Duties	27-Apr-1987
99	20072521	Aua Ruta	F	POREBADA EAST	Household Duties	01-Jan-1975
100	20076610	Aua Kevau Tara	F	POREBADA EAST	Household Duties	03-Nov-1973
101	20094530	Auani Dani	F	POREBADA EAST	Teacher	02-Aug-1962
102	20131422	Aubau Elisa	F	POREBADA EAST	Household Duties	01-Jan-1996
103	20069560	Audabi Igo	F	POREBADA EAST	Self Employed	16-May-1985
104	20092621	Audabi Kovea Hua	F	POREBADA EAST	Household Duties	03-May-1970
105	20124813	Awo Esma	F	POREBADA EAST	Household Duties	29-Sep-1983
106	20217376	Barry Aule	F	POREBADA EAST	Student	06-Apr-2004
107	20217377	Baru Boio	F	POREBADA EAST	Student	04-Jan-2001
108	20130909	Baru Dia	F	POREBADA EAST	Security	29-Jan-1977
109	20217378	Baru Dorugu	F	POREBADA EAST	Household Duties	25-Apr-1994
110	20124121	Baru Helai Raka	F	POREBADA EAST	Secretary	09-May-1963
111	20072538	Baru Kaia	F	POREBADA EAST	Household Duties	25-Mar-1945
112	20090431	Baru Sere Gabe	F	POREBADA EAST	Worker	17-Jul-1982
113	20217379	Baru Tolo	F	POREBADA EAST	Worker	02-Feb-1996
114	20094345	Baru Arere Idau	F	POREBADA EAST	Household Duties	02-Jan-2000
115	20062510	Baru Hitolo Konio	F	POREBADA EAST	Self Employed	26-Nov-1986
116	20076532	Baru Tau Dobi	F	POREBADA EAST	Household Duties	07-Aug-1957
117	20072883	Bedani Inara	F	POREBADA EAST	Store Keeper	01-Jan-1983
118	20004689	BEMU RANU	F	POREBADA EAST	Household Duties	16-Jul-1964
119	20061921	Bemu Hitolo Baia	F	POREBADA EAST	Self Employed	01-Jan-1976
120	20064673	Bemu Hitolo Udukapu	F	POREBADA EAST	Household Duties	01-Jan-1958
121	20005043	BEN STAGES BUTU	F	POREBADA EAST	Household Duties	01-Dec-1993
122	20131402	Bikei Talebo	F	POREBADA EAST	Student	09-Apr-1997
123	20023226	Bodibo Kemo	F	POREBADA EAST	Household Duties	19-Jan-1983
124	20217381	Bodibo Lesi	F	POREBADA EAST	Student	29-May-2001
125	20064947	Bodibo Morea	F	POREBADA EAST	Self Employed	03-May-1975
126	20064488	Bodibo Tae	F	POREBADA EAST	Self Employed	03-Sep-1978
127	20130918	Bodibo Viora	F	POREBADA EAST	Household Duties	11-Jun-1997
128	20003870	BODIBO JOHN GEUA	F	POREBADA EAST	Household Duties	31-Oct-1986
129	20003942	BODIBO JOHN ASI VIORA	F	POREBADA EAST	Household Duties	08-Jul-1984
130	20094449	Bodibo Taumaku Baia	F	POREBADA EAST	Self Employed	18-Dec-1988
131	20217382	Boe Bedi	F	POREBADA EAST	Household Duties	20-Apr-1999
132	20004709	BOE ELISA	F	POREBADA EAST	Household Duties	21-Jul-1993
133	20123368	BOE Geua	F	POREBADA EAST	Household Duties	04-Nov-1981
134	20217383	Boe Gou	F	POREBADA EAST	Household Duties	01-Aug-2003
135	20125792	Boe Lulu	F	POREBADA EAST	Household Duties	23-Dec-1995
136	20081514	Boe Melani	F	POREBADA EAST	Self Employed	15-Mar-1977
137	20008589	BOE ROSE	F	POREBADA EAST	Household Duties	01-Jan-1991
138	20002805	BUA NAO	F	POREBADA EAST	Household Duties	06-Aug-1988
139	20081409	Bua Asi Mary	F	POREBADA EAST	Household Duties	01-Jan-1986
140	20009444	BUA KOITA TAU	F	POREBADA EAST	Household Duties	07-Nov-1992
141	20124876	Buruka Naomi	F	POREBADA EAST	Pastor	25-Apr-1957
142	20131358	Busina Dairi	F	POREBADA EAST	Household Duties	29-Apr-1995
143	20078625	Busina Dogodo	F	POREBADA EAST	Household Duties	29-Jan-1970
144	20005973	BUSINA DOREKA	F	POREBADA EAST	Teacher	17-Dec-1992
145	20004198	BUSINA HEAGI	F	POREBADA EAST	Self Employed	17-Nov-1987
146	20007258	BUSINA DOURA GEUA	F	POREBADA EAST	Household Duties	13-Aug-1993
147	20004706	BUSINA DOURA MAIA	F	POREBADA EAST	Household Duties	02-Dec-1975
148	20075991	Busina Pune Heagi	F	POREBADA EAST	Household Duties	30-Jun-1987
149	20007260	BUSINA TABE BOGE SISIA	F	POREBADA EAST	Household Duties	24-Mar-1992
150	20005972	BUSINA TABE DALAS TESSIE	F	POREBADA EAST	Household Duties	05-Nov-1993
151	20025754	Busina Tabe Kaia	F	POREBADA EAST	Household Duties	08-Nov-1978
152	20006073	BUSINA TABE VIBERTY	F	POREBADA EAST	Worker	07-Feb-1988
153	20076012	Charlie Momoru	F	POREBADA EAST	Household Duties	20-Oct-1973
154	20131432	Cletus Florence	F	POREBADA EAST	Household Duties	02-Dec-1978
155	20131323	Collin Margaret	F	POREBADA EAST	Household Duties	05-Jan-1993
156	20076523	Dabara Girigi	F	POREBADA EAST	Household Duties	27-Aug-1960
157	20031398	Dabara Homoka Maggi	F	POREBADA EAST	Household Duties	09-Sep-1986
158	20130752	Daera Bede	F	POREBADA EAST	Household Duties	14-Feb-1982
159	20089789	Daera Henao	F	POREBADA EAST	Household Duties	01-Jan-1957
160	20124971	Dairi Boio	F	POREBADA EAST	Household Duties	17-Apr-1997
161	20124125	Dairi Igo Geua	F	POREBADA EAST	Household Duties	04-Jun-1984
162	20067978	Dairi Vada	F	POREBADA EAST	Household Duties	21-May-1980
163	20076579	Dairi Winner	F	POREBADA EAST	Household Duties	01-Jan-1984
164	20217389	Dairi Gau Bede	F	POREBADA EAST	Household Duties	08-Sep-1996
165	20085484	Dairi Gau Igua	F	POREBADA EAST	Household Duties	11-Apr-1971
166	20217390	Dairi Gau Keruma	F	POREBADA EAST	Household Duties	20-May-1999
167	20130979	Daure Konio	F	POREBADA EAST	Household Duties	04-Mar-1986
168	20130931	Davai Auase	F	POREBADA EAST	Household Duties	17-Jun-1971
169	20069661	David Emma Konji	F	POREBADA EAST	Self Employed	01-Jan-1976
170	20090414	David Logea	F	POREBADA EAST	Worker	10-Aug-1970
171	20131153	David Mere	F	POREBADA EAST	Household Duties	25-Aug-1998
172	20124126	David Morea Regina	F	POREBADA EAST	Household Duties	12-Sep-1993
173	20004606	DAVID HARRY HEKOI	F	POREBADA EAST	Household Duties	04-Jul-1990
174	20087691	David Harry Mea	F	POREBADA EAST	Household Duties	20-May-1978
175	20009509	DAVID MOREA HEAGI	F	POREBADA EAST	Self Employed	23-Jul-1993
176	20076517	Delena Boni	F	POREBADA EAST	Household Duties	14-Aug-1963
177	20009078	DIKANA MOREA	F	POREBADA EAST	Unemployed	01-Jan-1972
178	20124128	Dimere Arere Naomi	F	POREBADA EAST	Household Duties	01-Aug-1966
179	20217392	Dimere Arua	F	POREBADA EAST	Household Duties	10-Sep-1999
180	20125722	Dimere Henao	F	POREBADA EAST	Household Duties	08-Apr-1994
181	20003597	DIMERE KIDU	F	POREBADA EAST	Unemployed	01-Jan-1975
182	20123382	DIMERE MARY MEA	F	POREBADA EAST	Unemployed	23-Nov-1994
183	20123383	DIMERE NAOMI MEA	F	POREBADA EAST	Unemployed	12-Dec-1991
184	20131288	Dimere Ruth	F	POREBADA EAST	Worker	14-Jul-1988
185	20064672	Dimere Aria Henao	F	POREBADA EAST	Household Duties	25-Sep-1955
186	20131120	Dimere Arua Boio	F	POREBADA EAST	Household Duties	16-Jun-1980
187	20033840	Dimere Morea Kari	F	POREBADA EAST	Household Duties	31-May-1967
188	20064291	Dina Idau	F	POREBADA EAST	Household Duties	28-Oct-1970
189	20036009	Dorido Henry Lucy	F	POREBADA EAST	Household Duties	01-Jan-1989
190	20081403	Doura Hegora	F	POREBADA EAST	Self Employed	26-Jun-1974
191	20124872	Doura Kaia	F	POREBADA EAST	Household Duties	24-Mar-1947
192	20076477	Doura Raka	F	POREBADA EAST	Household Duties	02-Jul-1980
193	20217395	Doura Taia	F	POREBADA EAST	Household Duties	24-Apr-2003
194	20084067	Doura Dimere Vagi	F	POREBADA EAST	Household Duties	06-Nov-1955
195	20033056	Doura Mea Geua	F	POREBADA EAST	Household Duties	01-Jan-1952
196	20079046	Doura Tabe Geua	F	POREBADA EAST	Household Duties	09-May-1953
197	20067899	Duahi Mary	F	POREBADA EAST	Household Duties	02-Jan-1967
198	20094506	Ebo Kovea Hekoi	F	POREBADA EAST	Self Employed	01-Jan-1962
199	20078635	Edea Asi	F	POREBADA EAST	Self Employed	04-Apr-1986
200	20079001	Edea Manoka	F	POREBADA EAST	Household Duties	30-Sep-1982
201	20130749	Edoni Cherylea	F	POREBADA EAST	Household Duties	21-Mar-1999
202	20005025	EGI VAGIA MANOKA	F	POREBADA EAST	Self Employed	20-Oct-1959
203	20124130	Eguta Auani Maria	F	POREBADA EAST	Household Duties	15-May-1953
204	20004625	EHERO KAVIA	F	POREBADA EAST	Worker	29-Jan-1987
205	20124979	Elly Helen	F	POREBADA EAST	Household Duties	21-Feb-1997
206	20003338	EMMANUEL UME KERUMA	F	POREBADA EAST	Worker	18-Oct-1977
207	20022703	Fave Elisa	F	POREBADA EAST	Household Duties	23-Mar-1993
208	20009079	FRANCIS TAITA	F	POREBADA EAST	Unemployed	17-Apr-1992
209	20005145	FRANSIS KWAIPO	F	POREBADA EAST	Self Employed	29-Oct-1993
210	20124131	Gaba Siono Idau	F	POREBADA EAST	Household Duties	18-Aug-1956
211	20227562	Gahusi Bole	F	POREBADA EAST	Household Duties	14-Jun-2001
212	20069270	Gahusi Dairi	F	POREBADA EAST	Self Employed	25-Nov-1988
213	20006131	GAHUSI MARIJULIEANN	F	POREBADA EAST	Student	10-Feb-1992
214	20069535	Gahusi Mary	F	POREBADA EAST	Household Duties	06-Jul-1970
215	20092278	Gahusi Gahusi Kaia	F	POREBADA EAST	Household Duties	06-Jun-1962
216	20124841	Gali Konio	F	POREBADA EAST	Student	27-May-1994
217	20227563	Gari Dika	F	POREBADA EAST	Household Duties	09-Dec-1995
218	20124133	Gari Igo Raka	F	POREBADA EAST	Household Duties	13-Jun-1988
219	20130922	Gari Keruma	F	POREBADA EAST	Household Duties	23-Mar-1999
220	20227564	Gari Lucy	F	POREBADA EAST	Household Duties	19-Mar-2000
221	20227565	Gari Mea	F	POREBADA EAST	Household Duties	25-May-2002
222	20003516	GARI MOREA LOHIA	F	POREBADA EAST	Unemployed	01-Jan-1973
223	20003517	GARI MOREA MOEKA	F	POREBADA EAST	Unemployed	01-Jan-1992
224	20047885	Gari Helai Maria	F	POREBADA EAST	Household Duties	01-Jan-1942
225	20004187	GARI MOREA KONIO	F	POREBADA EAST	Self Employed	16-Mar-1992
226	20075984	Gau Avere N	F	POREBADA EAST	Self Employed	05-May-1982
227	20009252	GAU BAGARA PETER	F	POREBADA EAST	Worker	07-Mar-1981
228	20009592	GAU DINA PETER	F	POREBADA EAST	Worker	03-Dec-1990
229	20090476	Gau Dobi	F	POREBADA EAST	Banker	28-Oct-1977
230	20123388	GAU Dogena	F	POREBADA EAST	Household Duties	28-Oct-1990
231	20131315	Gau Erue	F	POREBADA EAST	Not Specified	27-Nov-1962
232	20003522	GAU HANE	F	POREBADA EAST	Unemployed	01-Jan-1960
233	20076570	Gau Haro	F	POREBADA EAST	Household Duties	01-Jan-1955
234	20008743	GAU HITOLO MOREA	F	POREBADA EAST	Banker	01-Jan-1974
235	20123390	GAU HITOLO PETER	F	POREBADA EAST	Worker	14-Sep-1985
236	20008734	GAU HITOLO VAGI	F	POREBADA EAST	Worker	16-May-1988
237	20003505	GAU HOI	F	POREBADA EAST	Unemployed	01-Jan-1974
238	20092723	Gau Kaia Sisia	F	POREBADA EAST	Not Specified	21-Mar-1964
239	20008980	GAU KARI PETER	F	POREBADA EAST	Clerk	04-Jun-1979
240	20069552	Gau Keruma	F	POREBADA EAST	Household Duties	01-Jan-1962
241	20072563	Gau Kori	F	POREBADA EAST	Household Duties	04-May-1967
242	20124819	Gau Mona	F	POREBADA EAST	Household Duties	27-Jan-1995
243	20003587	GAU MOREA ARERE	F	POREBADA EAST	Household Duties	04-Dec-1970
244	20064292	Gau Rose Mea	F	POREBADA EAST	Household Duties	22-Jun-2003
245	20123386	Gau Sibo	F	POREBADA EAST	Household Duties	01-Mar-1967
246	20023233	Gau Theresa	F	POREBADA EAST	Worker	05-Mar-1988
247	20008977	GAU VABURI MOREA	F	POREBADA EAST	Clerk	01-Jan-1980
248	20031360	Gau  Lohia Hane	F	POREBADA EAST	Self Employed	01-Jan-1974
249	20006048	GAU HELAI KAYSI	F	POREBADA EAST	Household Duties	26-Apr-1978
250	20069666	Gau Irua Boio	F	POREBADA EAST	Self Employed	01-Jan-1958
251	20034635	Gau Kokoro Henao	F	POREBADA EAST	Household Duties	17-Jun-1952
252	20008600	GAU MOREA BOIO	F	POREBADA EAST	Student	15-Nov-1993
253	20227567	Gaudi Gorogo	F	POREBADA EAST	Household Duties	29-Aug-2002
254	20227568	Gaudi Hekoi	F	POREBADA EAST	Household Duties	12-Jan-1991
255	20197942	Gaudi Keruma	F	POREBADA EAST	Household Duties	05-May-2000
256	20197940	Gaudi Manoka	F	POREBADA EAST	Household Duties	08-Oct-1996
257	20022408	Gaudi Nou	F	POREBADA EAST	Household Duties	02-Jul-1993
258	20131307	Gaudi Tarube	F	POREBADA EAST	Household Duties	15-Nov-1956
259	20092873	Gavera Daure	F	POREBADA EAST	Self Employed	01-Jan-1980
260	20123393	GAVERA DIKA	F	POREBADA EAST	Unemployed	26-Aug-1987
261	20197961	Gavera Ivon	F	POREBADA EAST	Household Duties	06-May-1992
262	20003508	GAVERA JOSEPHINE	F	POREBADA EAST	Unemployed	01-Jan-1980
263	20062444	Gavera Kali	F	POREBADA EAST	Subsistence Farmer	21-Mar-1982
264	20062423	Gavera Sarah	F	POREBADA EAST	Self Employed	13-Jan-1984
265	20005065	GAVERA GOROGO ASI	F	POREBADA EAST	Household Duties	09-Jul-1989
266	20131145	Gege Dobi	F	POREBADA EAST	Household Duties	16-Mar-1996
267	20076404	Gege Geua	F	POREBADA EAST	Household Duties	01-Jan-1982
268	20227573	Gemona Nelly	F	POREBADA EAST	Household Duties	22-Jun-2000
269	20124977	George Victoria	F	POREBADA EAST	Household Duties	19-May-1981
270	20094539	George Merabo Geua	F	POREBADA EAST	Household Duties	07-Aug-1982
271	20003401	GEUA REI NEBIRA	F	POREBADA EAST	Self Employed	04-Aug-1988
272	20072946	Gima Boni	F	POREBADA EAST	Subsistence Farmer	04-Apr-1987
273	20197938	Goasa Geua	F	POREBADA EAST	Household Duties	03-Apr-1998
274	20003612	GOASA LAHUI	F	POREBADA EAST	Unemployed	09-Feb-1987
275	20197937	Goasa Mata Manea	F	POREBADA EAST	Student	24-Jan-1997
276	20083650	Goata Anna Kila	F	POREBADA EAST	Banker	28-Feb-1968
277	20227575	Goata Arere	F	POREBADA EAST	Self Employed	12-Aug-1999
278	20062435	Goata Daina	F	POREBADA EAST	Household Duties	15-Nov-1963
279	20130912	Goata Idau	F	POREBADA EAST	Worker	20-May-1995
280	20079015	Goata Magi Geua	F	POREBADA EAST	Student	04-Mar-1988
281	20004196	GOATA ISAIAH KONE	F	POREBADA EAST	Household Duties	04-Jun-1970
282	20227579	Goda Magi	F	POREBADA EAST	Household Duties	14-Aug-1993
283	20227580	Golo Velda	F	POREBADA EAST	Household Duties	01-Mar-1994
284	20227582	Gorogo Dogena	F	POREBADA EAST	Household Duties	11-Aug-1996
285	20078623	Gorogo Gau	F	POREBADA EAST	Household Duties	30-Apr-1962
286	20004674	GOROGO HEKOI	F	POREBADA EAST	Unemployed	01-Jan-1978
287	20051173	Gorogo Helen	F	POREBADA EAST	Household Duties	25-Nov-1980
288	20131355	Gorogo Kari	F	POREBADA EAST	Student	08-Jul-1995
289	20227585	Gorogo Kiki	F	POREBADA EAST	Household Duties	17-Feb-2001
290	20124139	Gorogo Koani Koani	F	POREBADA EAST	Household Duties	02-Jan-1974
291	20072948	Gorogo Kone	F	POREBADA EAST	Typist	20-Sep-1964
292	20124140	Gorogo Lahui Naomi	F	POREBADA EAST	Household Duties	20-May-1981
293	20124141	Gorogo Lohia Henao	F	POREBADA EAST	Household Duties	21-Jun-1983
294	20124142	Gorogo Lohia Kori	F	POREBADA EAST	Household Duties	29-May-1990
295	20004675	GOROGO MARAGA	F	POREBADA EAST	Household Duties	01-Jan-1993
296	20131423	Gorogo Maraga	F	POREBADA EAST	Household Duties	30-May-1994
297	20131320	Gorogo Riu	F	POREBADA EAST	Household Duties	15-Nov-1978
298	20227586	Gorogo Seri	F	POREBADA EAST	Student	23-Oct-2001
299	20131278	Gorogo Sisia	F	POREBADA EAST	Student	31-May-1998
300	20003956	GOROGO TAITA S	F	POREBADA EAST	Household Duties	12-Aug-1983
301	20094576	Gorogo Arere Itapo	F	POREBADA EAST	Household Duties	29-Dec-1967
302	20083549	Gorogo Gahusi Geua	F	POREBADA EAST	Household Duties	01-Jan-1950
303	20094465	Gorogo Gari Kaia	F	POREBADA EAST	Household Duties	06-Oct-1982
304	20090246	Gorogo Koani Kari	F	POREBADA EAST	Household Duties	07-May-1973
305	20035401	Gorogo Lahui Manoka	F	POREBADA EAST	Household Duties	01-Jan-1974
306	20067586	Gorogo Morea Karoho	F	POREBADA EAST	Household Duties	01-Jan-1958
307	20054181	Gorogo Morea Koani	F	POREBADA EAST	Household Duties	02-Oct-1973
308	20004692	GOROHU KARI	F	POREBADA EAST	Household Duties	21-Jul-1982
309	20067904	Guba Henao	F	POREBADA EAST	Household Duties	16-Jun-1967
310	20002939	GUBA JULIE	F	POREBADA EAST	Household Duties	25-Apr-1985
311	20064761	Guba Kaia	F	POREBADA EAST	Household Duties	19-May-1974
312	20130750	Guba Maria	F	POREBADA EAST	Household Duties	06-Nov-1957
313	20022409	Guba Vavine	F	POREBADA EAST	Household Duties	26-Aug-1983
314	20094582	Guba Arua Vaburi	F	POREBADA EAST	Household Duties	30-Jan-1964
315	20047707	Gudia Gau Hane	F	POREBADA EAST	Household Duties	02-Sep-1970
316	20033009	Gudia Veri Hane	F	POREBADA EAST	Household Duties	04-Oct-1968
317	20089761	Gure Geua	F	POREBADA EAST	Household Duties	01-Jan-1954
318	20090438	Gure Lesi	F	POREBADA EAST	Household Duties	27-May-1957
319	20031412	Gure Inara Nou	F	POREBADA EAST	Household Duties	08-Feb-1965
320	20005125	HAHE GARIA	F	POREBADA EAST	Unemployed	01-Jan-1973
321	20123402	HANE Daure	F	POREBADA EAST	Unemployed	01-Jan-1993
322	20123401	Hane Gau	F	POREBADA EAST	Unemployed	01-Jan-1963
323	20005158	HANE HITOLO	F	POREBADA EAST	Unemployed	01-Jan-1965
324	20130754	Hane Hitolo	F	POREBADA EAST	Household Duties	01-Jan-1961
325	20123403	Hane Idau	F	POREBADA EAST	Household Duties	01-Jan-1974
326	20032059	Hane Merabo Hitolo	F	POREBADA EAST	Household Duties	01-Jan-1983
327	20124144	Hao Toua Kiki	F	POREBADA EAST	Household Duties	05-Apr-1964
328	20131115	Hare Margaret	F	POREBADA EAST	Teacher	17-Oct-1977
329	20094554	Harry Biru	F	POREBADA EAST	Self Employed	11-Mar-1978
330	20124145	Harry Gari Rose	F	POREBADA EAST	Household Duties	16-Apr-1975
331	20094541	Harry Mea	F	POREBADA EAST	Self Employed	04-Jul-1979
332	20094927	Harry Naomi	F	POREBADA EAST	Self Employed	18-May-1976
333	20084069	Havata Kari	F	POREBADA EAST	Student	01-Apr-1989
334	20084068	Havata Kevau	F	POREBADA EAST	Unemployed	10-Sep-1965
335	20124146	Havata Lohia Jean	F	POREBADA EAST	Self Employed	04-Jan-1991
336	20078624	Havata Manu	F	POREBADA EAST	Self Employed	04-May-1985
337	20123405	HAVATA PORE	F	POREBADA EAST	Household Duties	26-Dec-1971
338	20003405	HAVATA LOHIA ROSE	F	POREBADA EAST	Self Employed	24-Jul-1992
339	20083661	Heagi Bau	F	POREBADA EAST	Household Duties	15-Aug-1963
340	20130954	Heagi Dairi	F	POREBADA EAST	Household Duties	02-Jun-1991
341	20092863	Heagi Gari Arua	F	POREBADA EAST	Household Duties	01-Aug-1945
342	20033062	Heagi Gwada	F	POREBADA EAST	Household Duties	01-Jan-1983
343	20072542	Heagi Hedaro	F	POREBADA EAST	Household Duties	01-Jan-1940
344	20123411	HEAGI Hedaro	F	POREBADA EAST	Unemployed	24-Feb-1991
345	20004161	HEAGI HITOLO	F	POREBADA EAST	Unemployed	17-May-1989
346	20092728	Heagi Hua	F	POREBADA EAST	Household Duties	12-Apr-1973
347	20059209	Heagi Kaia	F	POREBADA EAST	Household Duties	16-Aug-1962
348	20076475	Heagi Kari	F	POREBADA EAST	Household Duties	12-Sep-1977
349	20131375	Heagi Keruma	F	POREBADA EAST	Not Specified	05-Jan-1997
350	20123408	Heagi Konio	F	POREBADA EAST	Household Duties	10-Dec-1980
351	20227593	Heagi Maba	F	POREBADA EAST	Household Duties	23-Jan-2001
352	20131374	Heagi Mala	F	POREBADA EAST	Worker	18-Jun-1993
353	20079026	Heagi Pore	F	POREBADA EAST	Self Employed	23-Dec-1962
354	20123410	Heagi Raka	F	POREBADA EAST	Self Employed	25-Apr-1980
355	20005103	HEAGI BUSINA LEANN	F	POREBADA EAST	Store Keeper	10-Oct-1989
356	20006827	HEAGI GOROGO DOBI	F	POREBADA EAST	Household Duties	03-Dec-1977
357	20022388	Heagi Gorogo Geua	F	POREBADA EAST	Household Duties	07-Sep-1982
358	20054310	Heagi Heagi Idau	F	POREBADA EAST	Household Duties	06-Jul-1985
359	20064678	Heagi Heagi Rebeka	F	POREBADA EAST	Household Duties	01-Jan-1968
360	20033061	Heagi Isaiah Muraka	F	POREBADA EAST	Household Duties	04-Nov-1980
361	20081401	Heagi Riu Mareva	F	POREBADA EAST	Household Duties	11-Mar-1981
362	20061881	Heagi Tabe Koura	F	POREBADA EAST	Household Duties	16-Sep-1982
363	20130756	Heau Bua	F	POREBADA EAST	Household Duties	25-Dec-1995
364	20076436	Heau Henao	F	POREBADA EAST	Household Duties	01-Jan-1974
365	20076429	Heau Kaia	F	POREBADA EAST	Household Duties	30-Sep-1980
366	20227596	Heau Karoho	F	POREBADA EAST	Household Duties	06-Dec-1996
367	20079082	Heau Heau Loa	F	POREBADA EAST	Self Employed	30-Apr-1964
368	20072876	Heau Vagi Loa	F	POREBADA EAST	Self Employed	30-Sep-1983
369	20123413	Hegora Koura	F	POREBADA EAST	Household Duties	16-Dec-1979
370	20094477	Helai Geua	F	POREBADA EAST	Subsistence Farmer	25-Apr-1936
371	20130615	Helai Henao	F	POREBADA EAST	Household Duties	15-Jun-1998
372	20054267	Helai Jenny	F	POREBADA EAST	Household Duties	28-May-1980
373	20054508	Helai Kore	F	POREBADA EAST	Household Duties	01-Jan-1958
374	20123414	HELAI Loa	F	POREBADA EAST	Unemployed	06-Nov-1990
375	20131136	Helai Mauri	F	POREBADA EAST	Household Duties	19-Jan-1990
376	20054201	Helai Muri	F	POREBADA EAST	Household Duties	01-Jan-1945
377	20025278	Helai Lohia Geua	F	POREBADA EAST	Household Duties	01-Jan-1940
378	20092300	Helai Lohia Kori	F	POREBADA EAST	Household Duties	01-Jan-1956
379	20090480	Helai Oda Kaia	F	POREBADA EAST	Household Duties	04-Jun-1975
380	20131295	Henao Toutu	F	POREBADA EAST	Household Duties	27-Nov-1973
381	20081433	Hendry Tau Jessie	F	POREBADA EAST	Household Duties	12-Nov-1967
382	20009253	HENI BELINDA TARUBE	F	POREBADA EAST	Teacher	23-Mar-1973
383	20130635	Heni Ori	F	POREBADA EAST	Household Duties	09-Nov-1997
384	20227598	Heni Seri R	F	POREBADA EAST	Household Duties	12-Jun-1968
385	9920130600	Heni Sibona	F	POREBADA EAST	Household Duties	04-Nov-1992
386	20064308	Heni Sivari	F	POREBADA EAST	Household Duties	05-May-1976
387	20092296	Heni Viora	F	POREBADA EAST	Household Duties	12-Feb-1961
388	20025275	Heni Sisia Lahui	F	POREBADA EAST	Household Duties	07-Sep-1977
389	20059218	Heni Toua Morea	F	POREBADA EAST	Self Employed	09-Feb-1987
390	20124976	Henry Gege	F	POREBADA EAST	Household Duties	30-Oct-1995
391	20072933	Henry Maimu	F	POREBADA EAST	Household Duties	25-Jun-1975
392	20067969	Hera Gari	F	POREBADA EAST	Household Duties	02-Sep-1947
393	20123417	Hera Heagi	F	POREBADA EAST	Household Duties	23-Nov-1968
394	20227599	Hibo Patricia	F	POREBADA EAST	Household Duties	13-Mar-1994
395	20081530	Hila Tessi	F	POREBADA EAST	Self Employed	01-Dec-1981
396	20131155	Hitolo Asiamui	F	POREBADA EAST	Household Duties	06-Apr-1994
397	20131407	Hitolo Boio	F	POREBADA EAST	Household Duties	13-Nov-1996
398	20123418	Hitolo Bony	F	POREBADA EAST	Subsistence Farmer	11-Jun-1987
399	20197959	Hitolo Geua	F	POREBADA EAST	Subsistence Farmer	14-Sep-1998
400	20054265	Hitolo Hekoi	F	POREBADA EAST	Household Duties	01-Dec-1964
401	20090266	Hitolo Heni	F	POREBADA EAST	Teacher	03-Jan-1979
402	20130757	Hitolo Igo	F	POREBADA EAST	Household Duties	08-Aug-1995
403	20008712	HITOLO JACKY	F	POREBADA EAST	Unemployed	01-Jan-1977
404	20081388	Hitolo Kaia	F	POREBADA EAST	Household Duties	18-Nov-1975
405	20227601	Hitolo Kecie	F	POREBADA EAST	Household Duties	05-Aug-1997
406	20056771	Hitolo Keruma	F	POREBADA EAST	Household Duties	27-May-1985
407	20076447	Hitolo Kopi	F	POREBADA EAST	Household Duties	14-Dec-1971
408	20124874	Hitolo Manoka	F	POREBADA EAST	Household Duties	14-Sep-1976
409	20083576	Hitolo Maria	F	POREBADA EAST	Household Duties	26-Sep-1969
410	20227602	Hitolo Mary	F	POREBADA EAST	Household Duties	09-May-2003
411	20005013	HITOLO MEA	F	POREBADA EAST	Farm worker	01-Jan-1992
412	20069534	Hitolo Michelle M	F	POREBADA EAST	Household Duties	23-Jul-1975
413	20124152	Hitolo Morea Keruma	F	POREBADA EAST	Clerk	14-Jul-1972
414	20131156	Hitolo Riku	F	POREBADA EAST	Household Duties	08-Sep-1996
415	20227604	Hitolo Toto	F	POREBADA EAST	Household Duties	22-Jun-1996
416	20227605	Hitolo Vani Tausala	F	POREBADA EAST	Household Duties	16-Oct-1989
417	20227607	Hitolo Arere Arere	F	POREBADA EAST	Worker	23-Feb-1996
418	20227608	Hitolo Lohia Keruma	F	POREBADA EAST	Household Duties	31-Dec-2000
419	20031935	Hitolo Morea Arua	F	POREBADA EAST	Household Duties	01-Jan-1975
420	20005057	HITOLO RIU AVIA	F	POREBADA EAST	Not Specified	20-Sep-1991
421	20005190	HITOLO RIU DULCIE	F	POREBADA EAST	Household Duties	02-Nov-1993
422	20036025	Hitolo Vele Tola	F	POREBADA EAST	Household Duties	08-Sep-1989
423	20081130	Homoka Igua	F	POREBADA EAST	Household Duties	18-Aug-1950
424	20123424	Homoka Keruma	F	POREBADA EAST	Household Duties	22-Aug-1973
425	20061834	Homoka Hure Idau	F	POREBADA EAST	Household Duties	01-Jan-1948
426	20069562	Homoka Hure Kaia	F	POREBADA EAST	Household Duties	16-Sep-1948
427	20033058	Homoka Hure Sisia	F	POREBADA EAST	Household Duties	01-Jan-1962
428	20123425	HOOPER BIANCA	F	POREBADA EAST	Household Duties	20-Jul-1993
429	20227611	Hopper Asi	F	POREBADA EAST	Household Duties	11-Feb-1996
430	20227612	Hopper Helen	F	POREBADA EAST	Household Duties	01-Feb-2000
431	20227613	Hopper Kari	F	POREBADA EAST	Household Duties	22-Aug-2001
432	20227614	Hure Gege	F	POREBADA EAST	Household Duties	01-Jan-2000
433	20059058	Iageti Geua	F	POREBADA EAST	Self Employed	29-Mar-1980
434	20078739	Idau Asiani	F	POREBADA EAST	Self Employed	02-Nov-1954
435	20130959	Idau Ranu	F	POREBADA EAST	Household Duties	29-Jul-1995
436	20123426	Iga Kila Koita	F	POREBADA EAST	Household Duties	01-Jan-1958
437	20003952	IGA RAKA	F	POREBADA EAST	Household Duties	01-Jan-1985
438	20131128	Igo Anna	F	POREBADA EAST	Student	10-Dec-1997
439	20227615	Igo Arere	F	POREBADA EAST	Household Duties	08-Jul-2003
440	20078637	Igo Asi	F	POREBADA EAST	Household Duties	28-Sep-1956
441	20227616	Igo Audrey	F	POREBADA EAST	Household Duties	08-Aug-1996
442	20130943	Igo Duhi	F	POREBADA EAST	Student	10-Mar-1995
443	20124157	Igo Eguta Mary	F	POREBADA EAST	Self Employed	18-Dec-1986
444	20227641	Igo Gau	F	POREBADA EAST	Household Duties	13-Apr-1982
445	20083614	Igo Gau Morea	F	POREBADA EAST	Unemployed	19-Jul-1959
446	20124158	Igo Gau Ranu	F	POREBADA EAST	Household Duties	11-Jan-1976
447	20131127	Igo Geua	F	POREBADA EAST	Worker	14-Aug-1995
448	20123430	IGO GEUA MOREA	F	POREBADA EAST	Household Duties	23-Nov-1949
449	20227642	Igo Hebou	F	POREBADA EAST	Household Duties	22-May-1993
450	20197952	Igo Idau	F	POREBADA EAST	Household Duties	23-Aug-1996
451	20092353	Igo Maba	F	POREBADA EAST	Household Duties	27-Sep-1952
452	20124161	Igo Pautani Geua	F	POREBADA EAST	Household Duties	23-Feb-1973
453	20124928	Igo Pore	F	POREBADA EAST	Household Duties	29-Dec-1993
454	20131147	Igo Ruth	F	POREBADA EAST	Household Duties	02-May-1996
455	20131416	Igo Vaburi	F	POREBADA EAST	Household Duties	05-Jun-1995
456	20030943	Igo  Pautani Dairi	F	POREBADA EAST	Household Duties	01-Jan-1974
457	20007219	IGO ARUA NOI	F	POREBADA EAST	Clerk	07-Jan-1991
458	20092677	Igo Arua Oala	F	POREBADA EAST	Student	14-Oct-1984
459	20092785	Igo Baru Loa	F	POREBADA EAST	Clerk	23-Dec-1975
460	20090324	Igo Bemu Asi	F	POREBADA EAST	Subsistence Farmer	14-Oct-1972
461	20002526	IGO GAU BONI	F	POREBADA EAST	Household Duties	07-Sep-1990
462	20004236	IGO GAU MARY	F	POREBADA EAST	Teacher	24-Sep-1989
463	20072979	Igo Gau Morea	F	POREBADA EAST	Household Duties	06-Jan-1973
464	20003881	IGO HENI KONIO	F	POREBADA EAST	Household Duties	09-Jun-1992
465	20094457	Igo Lahui Dina	F	POREBADA EAST	Self Employed	19-Oct-1963
466	20031873	Igo Lahui Henao	F	POREBADA EAST	Household Duties	21-Jul-1951
467	20004575	IGO TOUA GEUA	F	POREBADA EAST	Unemployed	05-Jul-1993
468	20083606	Igo Vagi Keruma	F	POREBADA EAST	Household Duties	17-Sep-1963
469	20035426	Igo Varuko Henao	F	POREBADA EAST	Household Duties	19-Oct-1959
470	20131350	Ika'Ini Aiva	F	POREBADA EAST	Pastor	13-Jun-1962
471	20022379	Ikau Mea	F	POREBADA EAST	Household Duties	28-Aug-1991
472	20003651	ILAGI SARAH HITOLO	F	POREBADA EAST	Worker	05-Feb-1994
473	20090326	Inara Geua	F	POREBADA EAST	Secretary	07-Dec-1975
474	20004581	IOBI MANOKA	F	POREBADA EAST	Household Duties	30-Jun-1989
475	20227646	Ipi Kari	F	POREBADA EAST	Household Duties	10-Nov-1999
476	20131332	Irua Haro	F	POREBADA EAST	Household Duties	01-Jul-1957
477	20123431	Irua Helen	F	POREBADA EAST	Self Employed	01-Jan-1981
478	20123434	IRUA KUKUNA	F	POREBADA EAST	Unemployed	01-Jan-1992
479	20123435	IRUA MARIE	F	POREBADA EAST	Unemployed	01-Jan-1987
480	20123432	Irua Morea	F	POREBADA EAST	Self Employed	07-Dec-1978
481	20124983	Iruna Geva	F	POREBADA EAST	Household Duties	24-Oct-1974
482	20092598	Iruna Gorogo	F	POREBADA EAST	Household Duties	02-Mar-1973
483	20123436	IRUNA HITOLO	F	POREBADA EAST	Household Duties	15-Jul-1987
484	20003893	IRUNA GAU HITOLO	F	POREBADA EAST	Household Duties	15-Jul-1981
485	20227647	Isaiah Cassandra	F	POREBADA EAST	Household Duties	02-Apr-2000
486	20062538	Isaiah Gwen Vagi	F	POREBADA EAST	Household Duties	05-May-1950
487	20227648	Isaiah Henao	F	POREBADA EAST	Household Duties	24-Jun-2000
488	20227649	Isaiah Kari	F	POREBADA EAST	Household Duties	27-Dec-1997
489	20131393	Isaiah Mea	F	POREBADA EAST	Household Duties	25-Feb-1994
490	20059463	Isaiah Muraka Lohia	F	POREBADA EAST	Self Employed	23-Sep-1980
491	20227650	Isaiah Rose	F	POREBADA EAST	Household Duties	08-Jun-2001
492	20019020	Isaiah Suta	F	POREBADA EAST	Household Duties	10-Sep-1980
493	20005176	ISAIAH GOATA MEA	F	POREBADA EAST	Student	25-Feb-1994
494	20003529	ISAIAH KOANI HOI	F	POREBADA EAST	Household Duties	15-Mar-1967
495	20003287	ISAIAH PETER GEUA	F	POREBADA EAST	Household Duties	22-Oct-1992
496	20078718	Isaiah Vagi Geua	F	POREBADA EAST	Household Duties	28-Apr-1946
497	20227653	Ivan Dimere	F	POREBADA EAST	Household Duties	20-Jun-2000
498	20022371	Ivele Logea	F	POREBADA EAST	Household Duties	23-Jun-1988
499	20131316	Jack Deborah	F	POREBADA EAST	Unemployed	29-Jul-1994
500	20079003	Jack Dobi	F	POREBADA EAST	Student	21-Apr-1986
501	20131313	Jack Eunice	F	POREBADA EAST	Student	19-Dec-1995
502	20007466	JACK LAHUI DOBI	F	POREBADA EAST	Household Duties	21-Apr-1986
503	20076450	Jack Lohia Kaia	F	POREBADA EAST	Teacher	24-Apr-1986
504	20003357	JACK LOHIA RAKA	F	POREBADA EAST	Household Duties	12-Jul-1993
505	20072872	Jerry Taumaku Kone	F	POREBADA EAST	Household Duties	30-May-1986
506	20092364	Jim Hebou	F	POREBADA EAST	Teacher	25-Aug-1987
507	20092365	Jim Taumaku	F	POREBADA EAST	Household Duties	17-Feb-1980
508	20032470	Jimm Boni	F	POREBADA EAST	Household Duties	01-Jan-1978
509	20009475	JIMMY LOHIA GEUA	F	POREBADA EAST	Clerk	07-Jun-1992
510	20227655	Job Mune	F	POREBADA EAST	Pastor	15-Apr-1985
511	20006506	JOE HILARY	F	POREBADA EAST	Student	04-Aug-1991
512	20006823	JOE LISA	F	POREBADA EAST	Self Employed	01-Jan-1985
513	20092701	Joe Norah	F	POREBADA EAST	Household Duties	01-Jan-1987
514	20031980	Joe Dairi Abby	F	POREBADA EAST	Household Duties	05-May-1985
515	20031820	Joe Dairi Geua	F	POREBADA EAST	Household Duties	20-Jun-1955
516	20227656	Joe Mahuta Asi	F	POREBADA EAST	Student	12-Jul-2003
517	20227657	John Bonama	F	POREBADA EAST	Student	17-Mar-2002
518	20227658	John Eunice	F	POREBADA EAST	Worker	12-Jun-2000
519	20124164	John Helai Laurei	F	POREBADA EAST	Household Duties	16-Nov-1938
520	20005104	JOHN HENAO	F	POREBADA EAST	Household Duties	13-Jul-1989
521	20004563	JOHN KAIA	F	POREBADA EAST	Clerk	10-Jan-1991
522	20009479	JOHN SARA	F	POREBADA EAST	Student	01-Jan-1993
523	20131294	John Yvonne	F	POREBADA EAST	Worker	01-Jun-1997
524	20003288	JOHN HEAGI MARY	F	POREBADA EAST	Household Duties	01-Jan-2000
525	20227662	John Seba Loa	F	POREBADA EAST	Household Duties	08-Feb-2002
526	20131429	Josaiah Miriam	F	POREBADA EAST	Household Duties	28-Feb-1997
527	20123440	Josiah Toutu	F	POREBADA EAST	Household Duties	05-Nov-1983
528	20047100	Jules Vasiri Judy	F	POREBADA EAST	Household Duties	24-Jul-1972
529	20131348	Kaboro Samantha	F	POREBADA EAST	Accountant	10-Jan-1989
530	20092611	Kaika Beso	F	POREBADA EAST	Household Duties	01-Jan-1949
531	20227663	Kairi Racheal	F	POREBADA EAST	Household Duties	10-Aug-1987
532	20008236	KALAU DENYSE	F	POREBADA EAST	Student	01-Jan-1989
533	20007896	KALAU NEBIRA	F	POREBADA EAST	Worker	01-Jan-1981
534	20131341	Kamali Morea	F	POREBADA EAST	Household Duties	30-Apr-1967
535	20123441	KAMILO DUIVA HITOLO	F	POREBADA EAST	Household Duties	16-Feb-1979
536	20047104	Kapuna Gau Tessie	F	POREBADA EAST	Household Duties	26-Apr-1978
537	20083644	Kari Kovae Dairi	F	POREBADA EAST	Unemployed	11-May-1956
538	20131314	Karo Ruby	F	POREBADA EAST	Worker	08-May-1989
539	20090242	Karoho Boio	F	POREBADA EAST	Household Duties	31-Oct-1985
540	20124165	Karoho Igo Mere	F	POREBADA EAST	Household Duties	15-Apr-1982
541	20003417	KAROHO MOREA HENAO	F	POREBADA EAST	Household Duties	18-Apr-1991
542	20094533	Karua Bisi	F	POREBADA EAST	Unemployed	08-Jan-1985
543	20009426	KARUA DAIRI	F	POREBADA EAST	Unemployed	05-Jun-1964
544	20064554	Karua Elisa	F	POREBADA EAST	Self Employed	09-Sep-1987
545	20131301	Karua Idau Sisia	F	POREBADA EAST	Household Duties	22-Nov-1998
546	20123443	Karua Konio Maisy	F	POREBADA EAST	Teacher	19-Aug-1980
547	20054251	Karua Rakatania	F	POREBADA EAST	Household Duties	25-Sep-1955
548	20092803	Katawara Baru Nancy Helen	F	POREBADA EAST	Household Duties	14-Sep-1957
549	20076535	Kauna Henao	F	POREBADA EAST	Household Duties	30-Dec-1959
550	20131321	Kauna Raraga	F	POREBADA EAST	Household Duties	29-Jul-1994
551	20227666	Keke Kalo	F	POREBADA EAST	Household Duties	03-Jul-1995
552	20036797	Kema Karukaru Pala	F	POREBADA EAST	Household Duties	02-Nov-1965
553	20085480	Keni Kila	F	POREBADA EAST	Unemployed	05-Nov-1986
554	20083920	Keni Konio	F	POREBADA EAST	Unemployed	03-May-1973
555	20090328	Keni Morea	F	POREBADA EAST	Household Duties	17-Oct-1965
556	20003657	KENI KOITA IRU	F	POREBADA EAST	Household Duties	20-Mar-1980
557	20009489	KENI KOITA IRU	F	POREBADA EAST	Self Employed	01-Jan-1989
558	20009569	KENI KOITA MURAKA	F	POREBADA EAST	Household Duties	19-Oct-1992
559	20227671	Kenny Ruth	F	POREBADA EAST	Household Duties	27-Dec-1999
560	20227672	Kere Onu	F	POREBADA EAST	Household Duties	22-May-1997
561	20131129	Kevau Gabae	F	POREBADA EAST	Student	22-Sep-1997
562	20094445	Kila Aiva	F	POREBADA EAST	Household Duties	08-Jan-1987
563	20125735	Kila Guma	F	POREBADA EAST	Household Duties	16-Feb-1993
564	20009451	KILA GWENI	F	POREBADA EAST	Worker	07-Oct-1990
565	20131421	Kila Jenifer	F	POREBADA EAST	Student	30-Oct-1998
566	20083596	Kila Maria	F	POREBADA EAST	Household Duties	15-Sep-1984
567	20123445	Kila Marina	F	POREBADA EAST	Household Duties	01-Jan-1945
568	20130982	Kila Mea	F	POREBADA EAST	Household Duties	07-Oct-1982
569	20004501	KILA LAKA KALA	F	POREBADA EAST	Household Duties	25-May-1990
570	20004169	KILA VAGI GWEN	F	POREBADA EAST	Household Duties	10-Oct-1990
571	20227676	Kimsy Priscilla	F	POREBADA EAST	Household Duties	09-Aug-1992
572	20005172	KIRAKAI JULIE KIRAKAI	F	POREBADA EAST	Worker	11-Jun-1973
573	20124878	Kiri Lucy	F	POREBADA EAST	Household Duties	11-May-1975
574	20227677	Koani Ann Cecillia	F	POREBADA EAST	Baby Sitter	01-Jan-2001
575	20124170	Koani Buruka Idau	F	POREBADA EAST	Self Employed	10-Jan-1980
576	20131431	Koani Esther	F	POREBADA EAST	Household Duties	09-Jun-1996
577	20008719	KOANI GEUA GOROGO	F	POREBADA EAST	Not Specified	01-Jan-1967
578	20227678	Koani Hane	F	POREBADA EAST	Household Duties	23-Dec-2001
579	20022377	Koani Henao	F	POREBADA EAST	Household Duties	01-Aug-1993
580	20081377	Koani Idau	F	POREBADA EAST	Secretary	03-Jun-1962
581	20005055	KOANI KAIA	F	POREBADA EAST	Unemployed	01-Jul-1991
582	20092716	Koani Kaia	F	POREBADA EAST	Worker	10-Sep-1965
583	20023652	Koani Kari	F	POREBADA EAST	Household Duties	04-May-1951
584	20227679	Koani Liei	F	POREBADA EAST	Household Duties	05-Jul-2002
585	20130610	Koani Loa	F	POREBADA EAST	Household Duties	07-Jul-1996
586	20094352	Koani Maraga	F	POREBADA EAST	Household Duties	01-Jan-1956
587	20009556	KOANI DIMERE BONNIE	F	POREBADA EAST	Worker	01-Sep-1993
588	20002520	KOANI DIMERE ESTER	F	POREBADA EAST	Household Duties	09-Jun-1986
589	20059068	Koani Gau Maia	F	POREBADA EAST	Household Duties	01-Jan-1968
590	20064682	Koani Gorogo Homoka	F	POREBADA EAST	Household Duties	06-Jul-1952
591	20072942	Koani Morea Geua	F	POREBADA EAST	Household Duties	14-Oct-1963
592	20003646	KOANI OVIA IDAU	F	POREBADA EAST	Household Duties	08-Feb-1990
593	20033014	Koani Riu Boio	F	POREBADA EAST	Household Duties	01-Jan-1974
594	20004204	KOANI SAM IGA	F	POREBADA EAST	Household Duties	20-May-1991
595	20092595	Kohu Marina	F	POREBADA EAST	Self Employed	09-Jun-1985
596	20124172	Koita Dimere Koko	F	POREBADA EAST	Household Duties	06-Jun-1965
597	20085485	Koita Gege	F	POREBADA EAST	Unemployed	02-Jan-2000
598	20124173	Koita Igo Nao	F	POREBADA EAST	Household Duties	01-Jan-1954
599	20087710	Koita Shirley	F	POREBADA EAST	Self Employed	05-May-1975
600	20087368	Koita Lahui Kovea	F	POREBADA EAST	Self Employed	03-Aug-1982
601	20031306	Kokoro Kaia	F	POREBADA EAST	Household Duties	31-Aug-1982
602	20227681	Kokoro Loa	F	POREBADA EAST	Household Duties	05-Oct-1998
603	20090444	Kokoro Homoka Kaia	F	POREBADA EAST	Self Employed	05-May-1985
604	20005073	KOMBERIVE HEAGI M	F	POREBADA EAST	Security	04-Jan-1954
605	20064247	Kone Lilagi	F	POREBADA EAST	Household Duties	02-Jan-2000
606	20083729	Kopi Dairi	F	POREBADA EAST	Self Employed	08-Jul-1970
607	20005020	KOROGO KOANI RIU	F	POREBADA EAST	Household Duties	15-Nov-1978
608	20076587	Koru Igo Boio	F	POREBADA EAST	Household Duties	01-Jan-1979
609	20124174	Kovae Gari Geua	F	POREBADA EAST	Subsistence Farmer	29-Aug-1953
610	20227682	Kovae Vaburi Elizabeth	F	POREBADA EAST	Student	09-Jun-2003
611	20034605	Kovae Seri Ranu	F	POREBADA EAST	Household Duties	30-Oct-1982
612	20032554	Kovea Kovea Mebo	F	POREBADA EAST	Household Duties	15-Jan-1983
613	20032594	Kwapena Gege	F	POREBADA EAST	Clerk	25-Nov-1960
614	20034298	Kwapena Hatini	F	POREBADA EAST	Household Duties	27-May-1989
615	20227684	Labie Cathy	F	POREBADA EAST	Household Duties	02-May-1986
616	20083950	Lahui Anna	F	POREBADA EAST	Household Duties	07-May-1956
617	20227685	Lahui Dobi	F	POREBADA EAST	Household Duties	03-Sep-2002
618	20090439	Lahui Geua	F	POREBADA EAST	Household Duties	18-May-1950
619	20130923	Lahui Geua	F	POREBADA EAST	Student	28-Feb-1998
620	20083603	Lahui Kaia	F	POREBADA EAST	Household Duties	01-Jan-1952
621	20003586	LAHUI KAU	F	POREBADA EAST	Household Duties	09-Jul-1982
622	20227688	Lahui Keruma	F	POREBADA EAST	Household Duties	21-Jan-1998
623	20076556	Lahui Logea	F	POREBADA EAST	Self Employed	13-Mar-1989
624	20124176	Lahui Momoru Arere	F	POREBADA EAST	Household Duties	09-Sep-1985
625	20124175	Lahui Momoru Vaburi	F	POREBADA EAST	Household Duties	01-Jan-1986
626	20227689	Lahui Morea	F	POREBADA EAST	Student	03-Oct-1999
627	20076598	Lahui Morea Henao	F	POREBADA EAST	Self Employed	08-Jul-1972
628	20067881	Lahui Nou	F	POREBADA EAST	Household Duties	01-Jan-1964
629	20005471	LAHUI TETEI	F	POREBADA EAST	Unemployed	01-Jan-1975
630	20081535	Lahui Unice	F	POREBADA EAST	Household Duties	20-Jan-2000
631	20009417	LAHUI MOMORU KONIO	F	POREBADA EAST	Self Employed	06-Jun-1992
632	20059418	Lahui Morea Mary	F	POREBADA EAST	Household Duties	01-Jan-1942
633	20003400	LAKA VABURI KILA	F	POREBADA EAST	Household Duties	24-Oct-1982
634	20197939	Lancan Naomy	F	POREBADA EAST	Student	24-Feb-1998
635	20227694	Len Maggie	F	POREBADA EAST	Student	21-Mar-2001
636	20197948	Lohai Baia	F	POREBADA EAST	Household Duties	26-Dec-1981
637	20083566	Lohia Boio	F	POREBADA EAST	Self Employed	01-Jan-1986
638	20009493	LOHIA CAROLYNNE	F	POREBADA EAST	Household Duties	09-Sep-1968
639	20005028	LOHIA CHRISTINE	F	POREBADA EAST	Worker	01-Jan-1973
640	20197950	Lohia Dadi	F	POREBADA EAST	Household Duties	15-Jun-1986
641	20008567	LOHIA DAIRI ODA	F	POREBADA EAST	Unemployed	01-Jan-1990
642	20008569	LOHIA DORE	F	POREBADA EAST	Unemployed	01-Jan-1980
643	20197951	Lohia Elizabeth	F	POREBADA EAST	Household Duties	07-Jul-1987
644	20227695	Lohia Elsie	F	POREBADA EAST	Household Duties	10-Nov-1999
645	20124969	Lohia Gabae Arua	F	POREBADA EAST	Household Duties	25-Nov-1963
646	20005152	LOHIA GAHUNA	F	POREBADA EAST	Household Duties	02-Jan-1989
647	20227696	Lohia Garia	F	POREBADA EAST	Student	01-Mar-2001
648	20124974	Lohia Gege	F	POREBADA EAST	Household Duties	21-Feb-1998
649	20227697	Lohia Gregoryanna	F	POREBADA EAST	Household Duties	10-Jul-2003
650	20076100	Lohia Kaia	F	POREBADA EAST	Household Duties	01-Jan-1986
651	20227698	Lohia Kaia	F	POREBADA EAST	Household Duties	24-May-2002
652	20005026	LOHIA LOHIA ARUA	F	POREBADA EAST	Worker	01-Jan-1973
653	20031432	Lohia Morea	F	POREBADA EAST	Household Duties	12-Nov-1972
654	20197949	Lohia Raronga JNR	F	POREBADA EAST	Household Duties	13-May-1998
655	20083602	Lohia Ruth	F	POREBADA EAST	Self Employed	16-Dec-1976
656	20092734	Lohia Dairi Kaia	F	POREBADA EAST	Household Duties	28-Dec-1971
657	20076456	Lohia Goata Kaia	F	POREBADA EAST	Self Employed	01-Jan-1949
658	20227703	Lohia Gorogo Boio	F	POREBADA EAST	Household Duties	22-Mar-2003
659	20227704	Lohia Gorogo Muraka	F	POREBADA EAST	Housegirl	02-Dec-1999
660	20078727	Lohia Havata Asi	F	POREBADA EAST	Household Duties	01-Jan-1957
661	20076546	Lohia Havata Hitolo	F	POREBADA EAST	Self Employed	01-Jan-1952
662	20062493	Lohia Hitolo Hitolo	F	POREBADA EAST	Student	13-Dec-1986
663	20076016	Lohia Igo Muraka	F	POREBADA EAST	Household Duties	12-Aug-1956
664	20002916	LOHIA ISAIAH PORE	F	POREBADA EAST	Household Duties	21-Feb-1990
665	20054256	Lohia Jerry Arua	F	POREBADA EAST	Security	02-Jan-1978
666	20083709	Lohia L Rakatani	F	POREBADA EAST	Household Duties	02-Jun-1944
667	20227708	Lohia Lohia Geua	F	POREBADA EAST	Security	14-May-1997
668	20081594	Lohia Lohia Loa	F	POREBADA EAST	Household Duties	14-Sep-1946
669	20008964	LOHIA MEA IDAU	F	POREBADA EAST	Worker	04-Dec-1976
670	20009461	LOHIA MOREA VALI LOI	F	POREBADA EAST	Clerk	31-Dec-1967
671	20007599	LOHIA MOREA DAIRI LOA	F	POREBADA EAST	Household Duties	22-May-1990
672	20033017	Lohia Peter Loa	F	POREBADA EAST	Household Duties	01-Jan-1987
673	20069539	Lohia Philip Bessie	F	POREBADA EAST	Household Duties	01-Jan-1947
674	20090397	Lohia Pune Kari	F	POREBADA EAST	Household Duties	17-May-1974
675	20004186	LOHIA VARUKO KARI	F	POREBADA EAST	Household Duties	19-Oct-1974
676	20106220	Lohia Vasiri Gahuna	F	POREBADA EAST	Household Duties	26-Dec-1989
677	20033824	Lohia Vasiri Kaia	F	POREBADA EAST	Household Duties	15-Mar-1980
678	20079181	Lohia Vasiri Liz	F	POREBADA EAST	Household Duties	01-Jan-1976
679	20069533	Lohia Vele Boio	F	POREBADA EAST	Household Duties	09-Jan-1982
680	20197946	Louise Elizabeth	F	POREBADA EAST	Student	25-Jun-2000
681	20227712	Loulai Arua	F	POREBADA EAST	Household Duties	12-Feb-2002
682	20131133	Loulai Henao	F	POREBADA EAST	Household Duties	08-Sep-1995
683	20123460	LOULAI KILA	F	POREBADA EAST	Household Duties	08-Aug-1992
684	20123458	Loulai Theresa	F	POREBADA EAST	Household Duties	21-Jul-1989
685	20003890	LOULAI HAVATA LESSY	F	POREBADA EAST	Household Duties	16-Aug-1982
686	20079053	Maba Ebo	F	POREBADA EAST	Household Duties	01-Jan-1962
687	20083953	Maba Kedea	F	POREBADA EAST	Unemployed	18-Oct-1976
688	20090239	Mabata Dabara Hebou	F	POREBADA EAST	Household Duties	19-May-1975
689	20059071	Mahuta Loa Clare	F	POREBADA EAST	Clerk	13-Oct-1956
690	20092737	Mahuta Raraga	F	POREBADA EAST	Subsistence Farmer	06-Jun-1983
691	20062495	Mahuta Stanley Boio	F	POREBADA EAST	Household Duties	05-Sep-1979
692	20227717	Maia Henao	F	POREBADA EAST	Household Duties	18-Aug-1963
693	20131281	Maiani Oape	F	POREBADA EAST	Teacher	17-Nov-1984
694	20067877	Maima Vagi	F	POREBADA EAST	Household Duties	30-Apr-1974
695	20092704	Maino Agnes	F	POREBADA EAST	Household Duties	05-May-1951
696	20008739	MANU GEUA	F	POREBADA EAST	Unemployed	09-May-1989
697	20054321	Manu Mauri	F	POREBADA EAST	Household Duties	07-Apr-1973
698	20130966	Maraga Enai	F	POREBADA EAST	Student	22-Apr-1997
699	20123462	Maraga Muraka	F	POREBADA EAST	Worker	28-Jan-1984
700	20031979	Marai Igo Sape	F	POREBADA EAST	Household Duties	28-Aug-1962
701	20035393	Mariga Eguta Kila	F	POREBADA EAST	Household Duties	01-Jan-1980
702	20092371	Marita Noelyn	F	POREBADA EAST	Self Employed	08-Aug-1984
703	20054511	Maro Barbra	F	POREBADA EAST	Teacher	02-Jun-1965
704	20131112	Maso Hore	F	POREBADA EAST	Worker	01-Jan-1979
705	20130634	Mataio Heni	F	POREBADA EAST	Household Duties	26-Sep-1996
706	20227718	Mataio Iru Maureen	F	POREBADA EAST	Household Duties	02-Jun-1965
707	20227719	Mataio Jessie	F	POREBADA EAST	Household Duties	26-Apr-2000
708	20057201	Mataio Mauri	F	POREBADA EAST	Household Duties	17-Feb-1956
709	20081558	Mataio Mere	F	POREBADA EAST	Household Duties	16-May-1947
710	20227720	Mataio Solange	F	POREBADA EAST	Household Duties	26-Jun-1998
711	20072353	Matui Judicka	F	POREBADA EAST	Household Duties	14-Sep-1975
712	20092705	Mauri Morea	F	POREBADA EAST	Household Duties	01-Jan-1980
713	20031394	Mauri Igo Bede	F	POREBADA EAST	Household Duties	01-Jan-1969
714	20227721	Mea Bede	F	POREBADA EAST	Student	26-Jan-2003
715	20227723	Mea Dika	F	POREBADA EAST	Household Duties	19-Apr-2002
716	20227724	Mea Doru	F	POREBADA EAST	Household Duties	19-Nov-1999
717	20227725	Mea Esther	F	POREBADA EAST	Household Duties	06-Jun-1991
718	20007594	MEA GEUA	F	POREBADA EAST	Household Duties	01-Jan-1988
719	20007597	MEA GEUA	F	POREBADA EAST	Unemployed	01-Jan-1974
720	20227726	Mea Helai	F	POREBADA EAST	Student	24-Jul-2002
721	20130933	Mea Jolly	F	POREBADA EAST	Worker	12-Jan-1994
722	20003961	MEA JOY BOGE	F	POREBADA EAST	Household Duties	24-Apr-1956
723	20008969	MEA LOHIA	F	POREBADA EAST	Worker	01-Jan-1976
724	20092391	Mea Maria	F	POREBADA EAST	Self Employed	08-Mar-1965
725	20124185	Mea Morea Kokoro Hitolo	F	POREBADA EAST	Household Duties	26-Apr-1989
726	20087439	Mea Busina Kopi	F	POREBADA EAST	Household Duties	27-Jul-1966
727	20034639	Mea Koani Dai	F	POREBADA EAST	Household Duties	07-May-1981
728	20004603	MEA MOREA GEUA	F	POREBADA EAST	Household Duties	20-Dec-1988
729	20003332	MEA TAUMAKU Nao	F	POREBADA EAST	Household Duties	28-Oct-1993
730	20003399	MEA TAUMAKU RAI	F	POREBADA EAST	Household Duties	07-Oct-1985
731	20031928	Mea Vagi Morea	F	POREBADA EAST	Household Duties	\N
732	20031294	Mea Vagi Rama	F	POREBADA EAST	Household Duties	18-Feb-1981
733	20130915	Meposon Esther	F	POREBADA EAST	Household Duties	09-Jun-1986
734	20054515	Merabo Hitolo Heis	F	POREBADA EAST	Self Employed	01-Jan-1965
735	20123468	MERABO VERONICA	F	POREBADA EAST	Unemployed	21-Feb-1992
736	20123469	MERABO YVONNE	F	POREBADA EAST	Student	10-Jun-1994
737	20002915	MERABO GOROGO KARI	F	POREBADA EAST	Household Duties	19-Feb-1980
738	20094459	Merabo Vagi Gege	F	POREBADA EAST	Household Duties	30-Oct-1976
739	20083579	Mere Raka	F	POREBADA EAST	Student	20-Apr-1989
740	20124188	Michael Arua Rose	F	POREBADA EAST	Household Duties	05-Jul-1977
741	20227734	Micky Geua	F	POREBADA EAST	Household Duties	12-Feb-1998
742	20227735	Mika Alice	F	POREBADA EAST	Household Duties	19-May-1983
743	20083683	Miria Jacqueline Taita	F	POREBADA EAST	Self Employed	20-Mar-1981
744	20083608	Miria Naomi	F	POREBADA EAST	Self Employed	24-Oct-1984
745	20083679	Miria Arere Bede	F	POREBADA EAST	Household Duties	24-Nov-1952
746	20083672	Miria Gari Heni	F	POREBADA EAST	Household Duties	21-Oct-1975
747	20005588	MISIKARAM ALICE TESSIE	F	POREBADA EAST	Unemployed	01-Jan-1989
748	20007459	MISIKARAM DAMARISH	F	POREBADA EAST	Unemployed	01-Jan-1985
749	20007460	MISIKARAM KORRIE NAOMI	F	POREBADA EAST	Unemployed	01-Jan-1984
750	20090429	Moeka Hitolo	F	POREBADA EAST	Self Employed	27-Apr-1989
751	20007130	MOEKA MOREA	F	POREBADA EAST	Household Duties	28-Oct-1984
752	20124189	Moeka Morea Muraka	F	POREBADA EAST	Household Duties	01-Jan-1930
753	20032580	Moeka Gari Rama	F	POREBADA EAST	Household Duties	31-May-1973
754	20007591	MOI BOIO	F	POREBADA EAST	Unemployed	25-Jul-1991
755	20131417	Moirere Mere	F	POREBADA EAST	Household Duties	01-Jan-1995
756	20033108	Momo Keruma	F	POREBADA EAST	Household Duties	11-May-1962
757	20124190	Momoru Doura Geua	F	POREBADA EAST	Pastor	28-Aug-1974
758	20067957	Momoru Fave  Arua	F	POREBADA EAST	Household Duties	01-Jan-1962
759	20123471	Momoru Geua	F	POREBADA EAST	Household Duties	01-Jan-1972
760	20058875	Momoru Kari	F	POREBADA EAST	Self Employed	21-Apr-1979
761	20125797	Momoru Kari	F	POREBADA EAST	Household Duties	16-Jul-1996
762	20005515	MOMORU KEVAU	F	POREBADA EAST	Household Duties	01-Jan-1989
763	20227736	Momoru Kori	F	POREBADA EAST	Household Duties	17-Apr-2002
764	20124191	Momoru Tarupa Arua	F	POREBADA EAST	Household Duties	10-Aug-1940
765	20003426	MOMORU SAM GARIA	F	POREBADA EAST	Household Duties	23-Jan-1985
766	20083664	Momoru Tarupa Kaia	F	POREBADA EAST	Household Duties	01-Jan-1939
767	20227737	Mora Lisa Jerry	F	POREBADA EAST	Household Duties	04-Apr-2002
768	20124194	Morea Arua Tara Geua	F	POREBADA EAST	Clerk	18-Jan-1980
769	20050657	Morea B Doriga	F	POREBADA EAST	Household Duties	29-Aug-1997
770	20083571	Morea Bede	F	POREBADA EAST	Household Duties	23-Jun-1964
771	20130733	Morea Biru	F	POREBADA EAST	Household Duties	16-Dec-1995
772	20130751	Morea Boni	F	POREBADA EAST	Worker	04-Dec-1992
773	20130985	Morea Eli	F	POREBADA EAST	Not Specified	24-Aug-1993
774	20131293	Morea Elisa	F	POREBADA EAST	Household Duties	24-Nov-1991
775	20227741	Morea Elizabeth	F	POREBADA EAST	Household Duties	12-Jun-1997
776	20076577	Morea Gari	F	POREBADA EAST	Self Employed	01-Jan-1985
777	20090325	Morea Garia	F	POREBADA EAST	Household Duties	01-Jan-1952
778	20124877	Morea Garia	F	POREBADA EAST	Worker	03-Dec-1980
779	20033116	Morea Gau	F	POREBADA EAST	Household Duties	01-Jan-1984
780	20227742	Morea Gege	F	POREBADA EAST	Student	18-May-2001
781	20123485	Morea Geua	F	POREBADA EAST	Self Employed	19-Aug-1970
782	20197957	Morea Geua	F	POREBADA EAST	Student	30-Aug-1999
783	20062534	Morea Geua Henao	F	POREBADA EAST	Household Duties	28-Aug-1955
784	20092376	Morea Glenyse	F	POREBADA EAST	Administrator	20-Dec-1969
785	20076549	Morea Gorogo	F	POREBADA EAST	Household Duties	07-Oct-1968
786	20090339	Morea Hane	F	POREBADA EAST	Household Duties	08-Nov-1977
787	20124197	Morea Heagi Geua	F	POREBADA EAST	Household Duties	02-Jul-1976
788	20129892	Morea Hebou	F	POREBADA EAST	Household Duties	02-Jan-1988
789	20003392	MOREA IAPEIWA	F	POREBADA EAST	Household Duties	04-Dec-1981
790	20125788	Morea Igo	F	POREBADA EAST	Security	29-Apr-1993
791	20007757	MOREA KERUMA	F	POREBADA EAST	Unemployed	26-Dec-1992
792	20059397	Morea Keruma	F	POREBADA EAST	Household Duties	01-Jan-1972
793	20130732	Morea Keruma	F	POREBADA EAST	Household Duties	26-Dec-1993
794	20227746	Morea Koani	F	POREBADA EAST	Household Duties	08-Dec-2001
795	20131343	Morea Kone	F	POREBADA EAST	Household Duties	01-Apr-1971
796	20078742	Morea Lulu	F	POREBADA EAST	Household Duties	20-Aug-1978
797	20227748	Morea Maggie	F	POREBADA EAST	Household Duties	07-Dec-1997
798	20005816	MOREA MARIA	F	POREBADA EAST	Unemployed	13-Apr-1990
799	20079130	Morea Mauri	F	POREBADA EAST	Household Duties	01-Jan-1973
800	20124200	Morea Mea Geua	F	POREBADA EAST	Clerk	17-Dec-1980
801	20124203	Morea Oda Shirley Hitolo	F	POREBADA EAST	Household Duties	10-Jan-1980
802	20123480	Morea Raka	F	POREBADA EAST	Worker	03-Dec-1973
803	20123483	MOREA Ravu Alewa	F	POREBADA EAST	Household Duties	28-Sep-1969
804	20085750	Morea Sisia Virobo	F	POREBADA EAST	Household Duties	27-Jul-1962
805	20089868	Morea Tanito	F	POREBADA EAST	Household Duties	23-Sep-1985
806	20094436	Morea  Homoka Kaia	F	POREBADA EAST	Household Duties	24-Jun-1961
807	20092341	Morea  Vagi Kaia	F	POREBADA EAST	Banker	27-Aug-1975
808	20064560	Morea Arere Henao	F	POREBADA EAST	Self Employed	20-Mar-1988
809	20227750	Morea Arua Geua	F	POREBADA EAST	Student	03-Dec-1999
810	20032582	Morea Arua Mauri	F	POREBADA EAST	Household Duties	01-Jan-1963
811	20002519	MOREA ASI ASIANI	F	POREBADA EAST	Household Duties	12-Dec-1981
812	20079022	Morea Auani Taia	F	POREBADA EAST	Household Duties	10-Sep-1962
813	20019015	Morea Baru Geua	F	POREBADA EAST	Household Duties	09-Nov-1986
814	20079188	Morea Baru Gorogo	F	POREBADA EAST	Household Duties	22-Jun-1973
815	20069549	Morea Baru Idau	F	POREBADA EAST	Self Employed	06-Feb-1947
816	20067974	Morea Baru Lilly	F	POREBADA EAST	Household Duties	08-Nov-1980
817	20007598	MOREA DAIRI RENAGI	F	POREBADA EAST	Sister	29-Apr-1968
818	20003344	MOREA DOGO KOITA HENAO	F	POREBADA EAST	Household Duties	17-Aug-1951
819	20058886	Morea Gau Dobi	F	POREBADA EAST	Household Duties	27-Jan-1977
820	20079132	Morea Gorogoi Geua	F	POREBADA EAST	Household Duties	01-Jan-1979
821	20227754	Morea Havata Taia	F	POREBADA EAST	Student	04-Feb-2004
822	20081418	Morea Heau Karoho	F	POREBADA EAST	Household Duties	22-May-1973
823	20090272	Morea Hitolo Hhenao	F	POREBADA EAST	Household Duties	03-Jan-1953
824	20064500	Morea Homoka Geua	F	POREBADA EAST	Household Duties	01-Aug-1945
825	20081141	Morea Igo Bede	F	POREBADA EAST	Household Duties	05-Jun-1964
826	20032488	Morea Igo Dobi	F	POREBADA EAST	Worker	09-Mar-1980
827	20035503	Morea Igo Eunice	F	POREBADA EAST	Household Duties	05-Jun-1987
828	20005187	MOREA IGO GEUA	F	POREBADA EAST	Self Employed	20-Nov-1989
829	20032181	Morea Igo Hekoi	F	POREBADA EAST	Worker	02-Jun-1960
830	20030944	Morea Igo Sisia	F	POREBADA EAST	Household Duties	02-Nov-1982
831	20003625	MOREA ISAIAH KONIO	F	POREBADA EAST	Student	17-Mar-1994
832	20034302	Morea Koi Eunice	F	POREBADA EAST	Household Duties	18-Nov-1981
833	20003510	MOREA LAHUI BOGE	F	POREBADA EAST	Household Duties	14-Jan-1993
834	20076590	Morea Lahui Gwen	F	POREBADA EAST	Household Duties	01-Jan-1983
835	20076605	Morea Lahui Henao	F	POREBADA EAST	Household Duties	06-Jan-1980
836	20003511	MOREA LAHUI MAURI	F	POREBADA EAST	Household Duties	21-Jan-1989
837	20031796	Morea Lohia Garia	F	POREBADA EAST	Household Duties	01-Jan-1988
838	20059213	Morea Maba Ranu	F	POREBADA EAST	Household Duties	01-Jan-1947
839	20007581	MOREA ODA HENAO	F	POREBADA EAST	Unemployed	03-Nov-1992
840	20003348	MOREA PAKO BUA	F	POREBADA EAST	Household Duties	24-Aug-1969
841	20025495	Morea Riu Lulu	F	POREBADA EAST	Household Duties	20-Aug-1978
842	20004505	MOREA TAUMAKU ELISA	F	POREBADA EAST	Self Employed	21-Nov-1994
843	20032497	Morea Taumaku Mea	F	POREBADA EAST	Household Duties	03-Jun-1987
844	20089765	Morea Toea Heni	F	POREBADA EAST	Household Duties	03-Sep-1953
845	20092868	Morea Vagi Kaia	F	POREBADA EAST	Household Duties	19-Mar-1969
846	20008742	MORESI MARIA	F	POREBADA EAST	Unemployed	01-Jan-1991
847	20123486	Morris Dogena	F	POREBADA EAST	Household Duties	25-Jun-1985
848	20067892	Morris Tan Lilly	F	POREBADA EAST	Household Duties	29-Aug-1973
849	20058873	Moses Mahuta Heagi	F	POREBADA EAST	Household Duties	16-Sep-1984
850	20227759	Murray Kevau	F	POREBADA EAST	Household Duties	11-Nov-1994
851	20227760	Naime Auda	F	POREBADA EAST	Household Duties	02-Oct-1974
852	20130967	Naime Igo	F	POREBADA EAST	Household Duties	17-Aug-1994
853	20076544	Nama Nuga	F	POREBADA EAST	Household Duties	16-Sep-1965
854	20094427	Nanai Idau	F	POREBADA EAST	Household Duties	25-Jan-1972
855	20130746	Neises Hebou	F	POREBADA EAST	Household Duties	13-Jan-1996
856	20006539	NEISESI RAKA	F	POREBADA EAST	Household Duties	27-Jan-1991
857	20058856	Nohokau Kaia	F	POREBADA EAST	Household Duties	13-Sep-1968
858	20022686	Nohokau Lohia Manoka	F	POREBADA EAST	Household Duties	25-Jan-1992
859	20130950	Nono Arua	F	POREBADA EAST	Household Duties	17-Jul-1958
860	20092287	Nono Kovea Gohuke	F	POREBADA EAST	Household Duties	01-Jan-1980
861	20124207	Nou Arere Jenny	F	POREBADA EAST	Household Duties	06-Apr-1983
862	20022369	Nuia Jean	F	POREBADA EAST	Household Duties	22-Sep-1975
863	20008962	ODA ANUVE	F	POREBADA EAST	Unemployed	12-Sep-1987
864	20022349	Oda Boio	F	POREBADA EAST	Household Duties	20-Dec-1992
865	20007989	ODA BOIO VAGI	F	POREBADA EAST	Not Specified	01-Jan-1987
866	20131300	Oda Cinta	F	POREBADA EAST	Household Duties	10-Aug-1987
867	20131324	Oda Haoda	F	POREBADA EAST	Household Duties	18-Jun-1996
868	20022353	Oda Hitolo Gure	F	POREBADA EAST	Self Employed	30-Jul-1993
869	20123399	Oda Iru	F	POREBADA EAST	Unemployed	19-Mar-1992
870	20007990	ODA KAIA	F	POREBADA EAST	Not Specified	01-Jan-1976
871	20085495	Oda Kaia	F	POREBADA EAST	Household Duties	01-Jan-1966
872	20078733	Oda Kaia Hitolo	F	POREBADA EAST	Household Duties	24-Mar-1947
873	20123499	Oda Maria	F	POREBADA EAST	Secretary	10-May-1956
874	20197941	Oda Tiru	F	POREBADA EAST	Student	07-Oct-1997
875	20227762	Oda Baru Geua	F	POREBADA EAST	Student	04-Apr-2004
876	20090340	Oda Rei Kaia	F	POREBADA EAST	Self Employed	13-May-1988
877	20078721	Oda Vagi Kaia	F	POREBADA EAST	Household Duties	13-Mar-1965
878	20090469	Olive Mary	F	POREBADA EAST	Household Duties	01-Jan-1980
879	20131135	Onne Vanesa	F	POREBADA EAST	Household Duties	28-Dec-1973
880	20004503	OVA GOASA HOI	F	POREBADA EAST	Household Duties	12-Oct-1990
881	20090341	Ovia Mea	F	POREBADA EAST	Household Duties	27-Aug-1970
882	20085746	Pako Biru	F	POREBADA EAST	Household Duties	24-Jul-1972
883	20008973	PAKO BOIO GAU	F	POREBADA EAST	Household Duties	11-Jun-1965
884	20076486	Pako Hitolo	F	POREBADA EAST	Household Duties	01-Jan-1975
885	20124814	Pako Kaia	F	POREBADA EAST	Subsistence Farmer	15-Apr-1997
886	20008972	PAKO MARIA GAU	F	POREBADA EAST	Household Duties	12-Jan-1957
887	20009250	PAKO MEA GAU	F	POREBADA EAST	Household Duties	01-Jan-1960
888	20034378	Pako Peter Naomi	F	POREBADA EAST	Household Duties	13-May-1983
889	20009066	PALA BAGARA	F	POREBADA EAST	Unemployed	01-Jan-1968
890	20123503	Pala GEGE	F	POREBADA EAST	Self Employed	03-Oct-1993
891	20005018	PALA SUSSIE	F	POREBADA EAST	Pastor	26-Apr-1988
892	20076474	Pala Vagi	F	POREBADA EAST	Household Duties	16-Oct-1966
893	20131326	Paska Roselyn	F	POREBADA EAST	Household Duties	02-Feb-1987
894	20227766	Patterson Marcellla	F	POREBADA EAST	Worker	04-Oct-2000
895	20090255	Pautani Dogena	F	POREBADA EAST	Self Employed	23-May-1957
896	20023635	Pautani Kaia Igo	F	POREBADA EAST	Household Duties	07-Oct-1981
897	20079186	Pautani Igo Keruma	F	POREBADA EAST	Household Duties	15-Jun-1959
898	20076514	Peter Biru Heita	F	POREBADA EAST	Household Duties	27-Oct-1966
899	20197955	PETER Dina	F	POREBADA EAST	Subsistence Farmer	08-Oct-1998
900	20130734	Peter Dinah	F	POREBADA EAST	Student	02-Oct-1997
901	20131126	Peter Gabae	F	POREBADA EAST	Household Duties	24-Nov-1994
902	20227767	Peter Geua	F	POREBADA EAST	Household Duties	09-Nov-2000
903	20227768	Peter Loa	F	POREBADA EAST	Household Duties	10-Dec-1996
904	20023647	Peter Theresa	F	POREBADA EAST	Teacher	31-Jul-1977
905	20227769	Peter Vagi	F	POREBADA EAST	Household Duties	23-Aug-2000
906	20072978	Peter Busina Naomi	F	POREBADA EAST	Household Duties	11-Nov-1966
907	20227770	Peter Duahi Gau	F	POREBADA EAST	Household Duties	14-Dec-2002
908	20032471	Peter Goata Keruma	F	POREBADA EAST	Household Duties	05-May-1975
909	20227771	Peter Rakatani Gabae	F	POREBADA EAST	Student	24-Nov-1995
910	20227772	Peter Rakatani Kaia	F	POREBADA EAST	Student	25-Nov-1998
911	20075995	Peter Vagi Gau	F	POREBADA EAST	Subsistence Farmer	20-Oct-1983
912	20124925	Petroff Keruma	F	POREBADA EAST	Household Duties	03-Feb-1997
913	20227774	Philip Dia	F	POREBADA EAST	Household Duties	01-Jan-1989
914	20059478	Pilu Katty	F	POREBADA EAST	Household Duties	13-Sep-1974
915	20062428	Pilu Rachel	F	POREBADA EAST	Household Duties	15-Jun-1982
916	20062502	Pilu Raka	F	POREBADA EAST	Self Employed	07-Sep-1984
917	20227776	Pouna Gia	F	POREBADA EAST	Household Duties	23-Apr-1974
918	20227777	Pukari Kone	F	POREBADA EAST	Household Duties	01-Feb-2003
919	20076018	Pune Busina Geua	F	POREBADA EAST	Clerk	06-May-1966
920	20089860	Pune Koani Dobi	F	POREBADA EAST	Pastor	14-Jul-1963
921	20088167	Pune Morea Karoho	F	POREBADA EAST	Household Duties	06-Aug-1971
922	20090332	Raka Nao	F	POREBADA EAST	Subsistence Farmer	20-Sep-1989
923	20094545	Raka Igo Dika	F	POREBADA EAST	Household Duties	01-Jan-1966
924	20130738	Rakatani Boio	F	POREBADA EAST	Household Duties	29-Jun-1981
925	20059402	Rakatani Sioro	F	POREBADA EAST	Household Duties	01-Jan-1980
926	20227778	Rakatani Sue	F	POREBADA EAST	Student	20-Dec-2001
927	20090418	Rakatani Arua Boio	F	POREBADA EAST	Household Duties	05-Mar-1975
928	20089791	Rakatani Arua Kari	F	POREBADA EAST	Self Employed	12-Apr-1979
929	20007325	RAKATANI DUAHI BOGE	F	POREBADA EAST	Self Employed	11-Sep-1975
930	20083646	Rakatani Gorogo Morea	F	POREBADA EAST	Self Employed	03-Dec-1974
931	20081489	Raki Geno	F	POREBADA EAST	Household Duties	10-Jun-1970
932	20081485	Rarama Renagi	F	POREBADA EAST	Household Duties	01-Dec-1942
933	20227779	Raymond Hitolo	F	POREBADA EAST	Student	30-May-1999
934	20227780	Raymond Igo	F	POREBADA EAST	Student	28-Feb-2001
935	20227781	Raymond Kaia	F	POREBADA EAST	Student	07-Apr-2002
936	20003627	RAYMOND ARUA MAURI	F	POREBADA EAST	Household Duties	12-Jun-1989
937	20130727	Rea Kari	F	POREBADA EAST	Household Duties	30-Jul-1977
938	20124214	Rei Busina Doko	F	POREBADA EAST	Household Duties	25-Mar-1977
939	20227782	Rei Iru	F	POREBADA EAST	Household Duties	27-Feb-2003
940	20045846	Rei Tarube	F	POREBADA EAST	Subsistence Farmer	01-Jan-1980
941	20092610	Rei Udu	F	POREBADA EAST	Household Duties	01-Aug-1967
942	20081133	Rei Doura Sisia	F	POREBADA EAST	Household Duties	21-Apr-1973
943	20003943	REI GAHUSI HAODA	F	POREBADA EAST	Household Duties	02-Oct-1975
944	20059420	Rei Havata Asi	F	POREBADA EAST	Household Duties	23-Oct-1957
945	20004150	REI HENI SISIA	F	POREBADA EAST	Household Duties	14-Nov-1988
946	20197958	Riu Arere	F	POREBADA EAST	Worker	10-Jan-2000
947	20227784	Riu Clare	F	POREBADA EAST	Household Duties	16-Oct-1989
948	20227785	Riu Gari	F	POREBADA EAST	Household Duties	29-Sep-2003
949	20197960	Riu Garia	F	POREBADA EAST	Household Duties	31-Aug-1999
950	20078744	Riu Kila	F	POREBADA EAST	Subsistence Farmer	29-Oct-1979
951	20083938	Riu Morea	F	POREBADA EAST	Typist	09-Oct-1965
952	20227786	Riu Sisia	F	POREBADA EAST	Household Duties	18-May-2000
953	20005056	RIU GAU MERKYN	F	POREBADA EAST	Household Duties	20-Apr-1990
954	20031367	Riu Hitolo Rose	F	POREBADA EAST	Student	23-Feb-1987
955	20054476	Riu Morea Hebou	F	POREBADA EAST	Household Duties	02-Feb-1958
956	20032612	Riu Morea Vaburi	F	POREBADA EAST	Student	19-Nov-1988
957	20064691	Robert Lahui	F	POREBADA EAST	Self Employed	16-Apr-1972
958	20123489	ROCKY Todoi	F	POREBADA EAST	Unemployed	01-Jan-1978
959	20092384	Saini Hebou	F	POREBADA EAST	Household Duties	04-Mar-1982
960	20124858	Sale Auau	F	POREBADA EAST	Household Duties	02-May-1981
961	20081374	Sale Mary	F	POREBADA EAST	Household Duties	05-May-1975
962	20227787	Sam Eli	F	POREBADA EAST	Self Employed	03-Jan-1980
963	20007756	SAMA HEAGI	F	POREBADA EAST	Unemployed	01-Jan-1991
964	20124856	Samuel Barbra	F	POREBADA EAST	Household Duties	01-Aug-1989
965	20005505	SEGORE TAU	F	POREBADA EAST	Household Duties	29-Aug-1983
966	20090451	Segore Taumaku	F	POREBADA EAST	Household Duties	01-Jan-1978
967	20009164	SEPA KARI	F	POREBADA EAST	Villager	07-Jun-1969
968	20123491	Seri Biru	F	POREBADA EAST	Household Duties	09-Oct-1984
969	20227792	Seri Dobi	F	POREBADA EAST	Student	13-Feb-2004
970	20083636	Seri Geua	F	POREBADA EAST	Unemployed	09-Sep-1988
971	20227793	Seri Geua	F	POREBADA EAST	Household Duties	30-Jun-2001
972	20087446	Seri Maria	F	POREBADA EAST	Self Employed	22-Feb-1984
973	20124220	Seri Mea Geua	F	POREBADA EAST	Secretary	11-Jan-1975
974	20092869	Seri Taumaku Sibo	F	POREBADA EAST	Self Employed	10-Aug-1987
975	20085344	Siage Geua	F	POREBADA EAST	Unemployed	14-Jun-1964
976	20072943	Simon Jessica	F	POREBADA EAST	Household Duties	01-Jan-1981
977	20123495	Simon Norma	F	POREBADA EAST	Household Duties	03-Aug-1977
978	20083674	Simon Sioro	F	POREBADA EAST	Unemployed	03-Mar-1952
979	20033109	Simon Heni Geua	F	POREBADA EAST	Worker	01-Jan-1974
980	20003963	Simon Vagi Eva	F	POREBADA EAST	Household Duties	16-Jan-1982
981	20079045	Simon Vagi Henao	F	POREBADA EAST	Secretary	25-Jun-1976
982	20124866	Sione Abigail	F	POREBADA EAST	Student	21-Mar-1998
983	20227798	Sioni Kila	F	POREBADA EAST	Worker	23-Dec-1997
984	20227799	Sioni Vagi	F	POREBADA EAST	Household Duties	03-Dec-2001
985	20031863	Sioni Gorogo Keruma	F	POREBADA EAST	Household Duties	29-Aug-1987
986	20083544	Sioni Taumaku Kaia	F	POREBADA EAST	Household Duties	16-May-1970
987	20130745	Sipma Emily	F	POREBADA EAST	Household Duties	12-May-1983
988	20006518	SISIA AVURU	F	POREBADA EAST	Worker	03-Feb-1967
989	20227800	Sisia Dairi	F	POREBADA EAST	Household Duties	04-Apr-2000
990	20227801	Sisia Fei	F	POREBADA EAST	Household Duties	09-Aug-1986
991	20227803	Sisia Konio	F	POREBADA EAST	Self Employed	26-Dec-1985
992	20123498	SOGE BOIO LEN	F	POREBADA EAST	Household Duties	07-Jun-1992
993	20033607	Soge Koi	F	POREBADA EAST	Household Duties	21-Feb-1968
994	20007589	SOGE MOREA ARUA	F	POREBADA EAST	Worker	09-Nov-1967
995	20005060	SOGORE KONU	F	POREBADA EAST	Accountant	02-Aug-1985
996	20009563	STANLEY MARITA HITOLO	F	POREBADA EAST	Student	12-Jul-1993
997	20130929	Steven Koi	F	POREBADA EAST	Student	02-Apr-1999
998	20131382	Steven Lohia	F	POREBADA EAST	Clerk	17-Jul-1989
999	20227807	Steven Nathaly	F	POREBADA EAST	Student	07-Dec-2003
1000	20227810	Suckling Roselyn	F	POREBADA EAST	Student	04-Aug-2001
1001	20004509	T PUNE SHARON	F	POREBADA EAST	Household Duties	08-Oct-1986
1002	20083656	Tabe Arua	F	POREBADA EAST	Household Duties	01-Aug-1958
1003	20124222	Tabe Dairi Sisia	F	POREBADA EAST	Household Duties	20-Oct-1965
1004	20094925	Tabe Kaia	F	POREBADA EAST	Household Duties	02-Nov-1954
1005	20130729	Tabe Koi	F	POREBADA EAST	Household Duties	24-May-1958
1006	20005584	TABE VABURI	F	POREBADA EAST	Household Duties	01-Jan-1989
1007	20081434	Tabe Isaiah Hekure	F	POREBADA EAST	Household Duties	02-Dec-1962
1008	20083662	Tabe Koani Hane	F	POREBADA EAST	Teacher	31-May-1976
1009	20008735	TABE MEA AUDA	F	POREBADA EAST	Household Duties	10-May-1990
1010	20058972	Tapa Keruma	F	POREBADA EAST	Household Duties	31-Oct-1979
1011	20092820	Tapa Agi Vealo	F	POREBADA EAST	Household Duties	05-Jun-1981
1012	20227811	Tara Beverly	F	POREBADA EAST	Clerk	21-Aug-1969
1013	20227812	Tara Henao	F	POREBADA EAST	Household Duties	18-Dec-1999
1014	9920124915	Tara Keruma	F	POREBADA EAST	Household Duties	01-Jul-1998
1015	20069298	Tara Lucy	F	POREBADA EAST	Household Duties	05-May-1970
1016	20092368	Tara Maiva	F	POREBADA EAST	Public Servant	17-Jan-1969
1017	20059464	Tara Heagi Tolo	F	POREBADA EAST	Household Duties	08-Nov-1977
1018	20003395	TARA HITOLO KAIA	F	POREBADA EAST	Household Duties	20-Jun-1981
1019	20081373	Tarube Dia	F	POREBADA EAST	Teacher	31-Jan-1979
1020	20123512	TARUBE GAUNA	F	POREBADA EAST	Unemployed	01-Mar-1976
1021	20079191	Tarube Idau	F	POREBADA EAST	Clerk	05-Jul-1983
1022	20227818	Tarupa Dairi	F	POREBADA EAST	Student	16-Dec-2000
1023	20008741	TARUPA MAXINE ARUA	F	POREBADA EAST	Household Duties	01-Jan-1990
1024	20227820	Tau Arua	F	POREBADA EAST	Household Duties	24-Oct-1999
1025	20131410	Tau Bertha	F	POREBADA EAST	Household Duties	06-Aug-1987
1026	20227821	Tau Dobi	F	POREBADA EAST	Household Duties	15-Mar-2004
1027	20123514	Tau Gunika	F	POREBADA EAST	Teacher	27-Nov-1988
1028	20124867	Tau Jessie	F	POREBADA EAST	Household Duties	12-Nov-1967
1029	20125798	Tau Kemo	F	POREBADA EAST	Household Duties	17-Mar-1998
1030	20125783	Tau Kore	F	POREBADA EAST	Household Duties	12-Jan-1981
1031	20131117	Tau Kukeri	F	POREBADA EAST	Household Duties	01-Jan-1952
1032	20003589	TAU SHILEY	F	POREBADA EAST	Unemployed	01-Jan-1985
1033	20227822	Tau Vaburi Gari	F	POREBADA EAST	Household Duties	08-Sep-2002
1034	20197943	Tauedea Morea	F	POREBADA EAST	Student	23-Sep-1995
1035	20005046	TAUEDEA MATAIO GEUA	F	POREBADA EAST	Household Duties	24-Apr-1991
1036	20003296	TAUEDEA MATAIO HEAGI	F	POREBADA EAST	Household Duties	14-Jul-1989
1037	20079039	Tauedea Morea Geua	F	POREBADA EAST	Household Duties	09-May-1967
1038	20090443	Tauedea Oda Mea	F	POREBADA EAST	Household Duties	29-Sep-1981
1039	20008726	TAUMAKU BAIA VAGI	F	POREBADA EAST	Unemployed	01-Jan-1989
1040	20197956	Taumaku Geua	F	POREBADA EAST	Household Duties	22-Jan-1998
1041	20092786	Taumaku Hane	F	POREBADA EAST	Household Duties	26-Jan-1969
1042	20092710	Taumaku Kaia	F	POREBADA EAST	Household Duties	20-May-1942
1043	20227826	Taumaku Rose	F	POREBADA EAST	Household Duties	14-Mar-2002
1044	20008586	TAUMAKU SERI MOREA	F	POREBADA EAST	Unemployed	01-Jan-1993
1045	20008604	TAUMAKU VABURI	F	POREBADA EAST	Unemployed	01-Jan-1993
1046	20003345	TAUMAKU DUAHI RAKA	F	POREBADA EAST	Household Duties	24-Nov-1960
1047	20076561	Taumaku Joe Mareva	F	POREBADA EAST	Household Duties	30-Jun-1982
1048	20032209	Taumaku Pune Mekeo	F	POREBADA EAST	Household Duties	15-Jun-1988
1049	20034135	Taumaku Tauedea Iru	F	POREBADA EAST	Household Duties	11-Feb-1985
1050	20068095	Taumaku Vaburi Mea	F	POREBADA EAST	Student	18-Jul-1988
1051	20227827	Taumaku Vaburi Nao	F	POREBADA EAST	Household Duties	17-Jul-1998
1052	20002817	TAUNAO KARI	F	POREBADA EAST	Household Duties	22-Nov-1986
1053	20003878	TAVA KARUA GIMA	F	POREBADA EAST	Store Keeper	04-Jul-1982
1054	20131298	Tavonga Beverly	F	POREBADA EAST	Worker	16-Feb-1991
1055	20124870	Tavonga Mea	F	POREBADA EAST	Household Duties	13-Dec-1956
1056	20124871	Tavonga Philomena	F	POREBADA EAST	Policewomen	19-May-1986
1057	20076008	Teina Heagi	F	POREBADA EAST	Household Duties	01-Jan-1960
1058	20227828	Temu Agnes	F	POREBADA EAST	Household Duties	20-Jan-1982
1059	20131319	Temu Alima	F	POREBADA EAST	Unemployed	15-Jun-1996
1060	20123348	Temu ANTONIA	F	POREBADA EAST	Worker	01-Jan-1976
1061	20123349	Temu IMELDA	F	POREBADA EAST	Unemployed	01-Jan-1988
1062	20064578	Temu Louisa	F	POREBADA EAST	Self Employed	30-May-1987
1063	20227830	Terry Henao	F	POREBADA EAST	Student	24-Dec-2002
1064	20130926	Terry Tekosi	F	POREBADA EAST	Student	17-Apr-1999
1065	20227831	Teteve Inai	F	POREBADA EAST	Household Duties	01-Jan-1996
1066	20131154	Timoti Morea	F	POREBADA EAST	Household Duties	23-Sep-1995
1067	20008570	TOEA DAI	F	POREBADA EAST	Household Duties	01-Jan-1981
1068	20227833	Toea Elly	F	POREBADA EAST	Worker	23-Apr-1984
1069	20123525	Toea Gwen	F	POREBADA EAST	Household Duties	24-Sep-1975
1070	20081407	Toea Hane	F	POREBADA EAST	Self Employed	12-Aug-1987
1071	20124223	Toea Hitolo Loa	F	POREBADA EAST	Household Duties	19-Mar-1973
1072	20123526	TOEA KAIA	F	POREBADA EAST	Household Duties	24-Jul-1988
1073	20007138	TOEA IOA HENI	F	POREBADA EAST	Household Duties	18-May-1994
1074	20033574	Toea Lahui Kaia	F	POREBADA EAST	Worker	04-May-1970
1075	20083952	Tolingling Vagi	F	POREBADA EAST	Household Duties	01-Jan-1987
1076	20083949	Tolingling Doura Eunice	F	POREBADA EAST	Household Duties	16-Feb-1961
1077	20031884	Tolinling Kaia	F	POREBADA EAST	Household Duties	22-Jul-1992
1078	20069281	Tolo Loa	F	POREBADA EAST	Household Duties	05-May-1974
1079	20227836	Tom Doriga	F	POREBADA EAST	Household Duties	23-Jul-1999
1080	20130735	Tom Eli	F	POREBADA EAST	Household Duties	08-Aug-1993
1081	20009163	TOM MAURI	F	POREBADA EAST	Unemployed	01-Jan-1980
1082	20051347	Tom Nancy	F	POREBADA EAST	Household Duties	29-Oct-1986
1083	20227837	Toni Mere	F	POREBADA EAST	Household Duties	03-Jun-2001
1084	20083641	Tonlinling Geua	F	POREBADA EAST	Household Duties	08-Jul-1979
1085	20130965	Tony Mea	F	POREBADA EAST	Student	27-Apr-1995
1086	20076463	Torea Laura	F	POREBADA EAST	Student	11-Dec-1988
1087	20062528	Toua Besi	F	POREBADA EAST	Self Employed	07-Aug-1981
1088	20131291	Toua Elisa	F	POREBADA EAST	Household Duties	25-Mar-1996
1089	20004607	TOUA MERIBA A	F	POREBADA EAST	Household Duties	27-Oct-1983
1090	20130743	Toua Morea	F	POREBADA EAST	Household Duties	28-Nov-1964
1091	20059061	Toua Rohi	F	POREBADA EAST	Self Employed	28-Mar-1985
1092	20004610	TOUA MEA GEUA	F	POREBADA EAST	Household Duties	07-Oct-1975
1093	20125739	Tuhiana Constance	F	POREBADA EAST	Worker	17-Sep-1980
1094	20227838	Ume Bonnie Priscilla	F	POREBADA EAST	Household Duties	08-Dec-2001
1095	20227839	Ume Eli	F	POREBADA EAST	Household Duties	16-Nov-1999
1096	20036691	Ure Vagi Louisa	F	POREBADA EAST	Household Duties	01-Jan-1970
1097	20083681	Vaburi Boio	F	POREBADA EAST	Self Employed	09-Jun-1980
1098	20094491	Vaburi Gari	F	POREBADA EAST	Clerk	08-Apr-1976
1099	20054261	Vaburi Geua	F	POREBADA EAST	Household Duties	17-Jan-1985
1100	20054266	Vaburi Hane	F	POREBADA EAST	Self Employed	22-Jul-1988
1101	20124851	Vaburi Henao	F	POREBADA EAST	Household Duties	27-Mar-1997
1102	20123530	Vaburi Hitolo	F	POREBADA EAST	Household Duties	07-May-1975
1103	20227841	Vaburi Imelda	F	POREBADA EAST	Student	07-Mar-2004
1104	20067962	Vaburi Iru	F	POREBADA EAST	Household Duties	04-Oct-1974
1105	20125734	Vaburi Kari	F	POREBADA EAST	Household Duties	28-Apr-1995
1106	20009062	VABURI KUKERI	F	POREBADA EAST	Unemployed	09-Apr-1986
1107	20123531	Vaburi Loa	F	POREBADA EAST	Subsistence Farmer	28-Jul-1985
1108	20227842	Vaburi Maria	F	POREBADA EAST	Household Duties	03-Sep-2000
1109	20130947	Vaburi Marina	F	POREBADA EAST	Household Duties	18-Jul-1994
1110	20130946	Vaburi Nao	F	POREBADA EAST	Household Duties	14-Oct-1996
1111	20227844	Vaburi Arere Kaia	F	POREBADA EAST	Student	03-Jan-2003
1112	20004182	VABURI LOHIA BEDE	F	POREBADA EAST	Household Duties	23-Mar-1993
1113	20032468	Vaburi Lohia Loa	F	POREBADA EAST	Household Duties	01-Jan-1987
1114	20018023	Vaburi Morea Morea	F	POREBADA EAST	Household Duties	29-Aug-1971
1115	20033543	Vaburi Vasiri Eva	F	POREBADA EAST	Household Duties	08-Apr-1985
1116	20123534	Vagi Boga Iru	F	POREBADA EAST	Worker	14-Jan-1985
1117	20039432	Vagi Caroline	F	POREBADA EAST	Household Duties	07-Jan-1969
1118	20130753	Vagi Daera	F	POREBADA EAST	Not Specified	04-Apr-1982
1119	20124864	Vagi Elizaberth	F	POREBADA EAST	Household Duties	10-Sep-1970
1120	20124224	Vagi Gau Boio	F	POREBADA EAST	Household Duties	27-Jul-1960
1121	20087685	Vagi Geua	F	POREBADA EAST	Household Duties	20-Feb-1950
1122	20008417	VAGI HENAO	F	POREBADA EAST	Unemployed	01-Jan-1984
1123	20227846	Vagi Henao	F	POREBADA EAST	Household Duties	07-Jun-1994
1124	20124225	Vagi Heni Lahui	F	POREBADA EAST	Self Employed	21-May-1992
1125	20083699	Vagi Hitolo	F	POREBADA EAST	Unemployed	16-May-1988
1126	20227848	Vagi Hua	F	POREBADA EAST	Household Duties	27-Sep-2000
1127	20227849	Vagi Idau	F	POREBADA EAST	Household Duties	23-Mar-2003
1128	20227850	Vagi Igo	F	POREBADA EAST	Household Duties	02-Jan-2001
1129	20008279	VAGI KAIA MOREA	F	POREBADA EAST	Unemployed	01-Jan-1974
1130	20123540	Vagi Keruma	F	POREBADA EAST	Household Duties	06-Aug-1956
1131	20130984	Vagi Lohia	F	POREBADA EAST	Household Duties	09-Oct-1962
1132	20123538	Vagi Maria	F	POREBADA EAST	Household Duties	16-Jun-1951
1133	20130983	Vagi Michelle	F	POREBADA EAST	Household Duties	16-Jun-1994
1134	20081415	Vagi Morea	F	POREBADA EAST	Household Duties	01-Jan-1971
1135	20075993	Vagi Nono Vaho	F	POREBADA EAST	Clerk	09-Sep-1961
1136	20124228	Vagi Pune Gau	F	POREBADA EAST	Household Duties	20-Aug-1985
1137	20124230	Vagi Pune Puro	F	POREBADA EAST	Household Duties	20-Jun-1969
1138	20227851	Vagi Raka	F	POREBADA EAST	Worker	05-Feb-1998
1139	20007980	VAGI SERE	F	POREBADA EAST	Unemployed	05-Jul-1991
1140	20033052	Vagi Akia Gata	F	POREBADA EAST	Household Duties	17-Oct-1982
1141	20031385	Vagi Arere Ranu	F	POREBADA EAST	Household Duties	07-Aug-1973
1142	20227853	Vagi Dimere Gorogo	F	POREBADA EAST	Household Duties	01-Jun-2000
1143	20092667	Vagi Gari Henao	F	POREBADA EAST	Pastor	30-May-1962
1144	20033593	Vagi Gau Doriga	F	POREBADA EAST	Clerk	01-Jan-1972
1145	20003350	VAGI IGO KILA	F	POREBADA EAST	Household Duties	21-Jul-1978
1146	20004202	VAGI IGO PORE	F	POREBADA EAST	Household Duties	29-Dec-1975
1147	20003530	VAGI KOANI HENAO	F	POREBADA EAST	Household Duties	25-Apr-1994
1148	20197925	Vagi Koani Kori	F	POREBADA EAST	Household Duties	27-May-1998
1149	20197924	Vagi Koani Nou Maia	F	POREBADA EAST	Household Duties	18-Jun-1996
1150	20005086	VAGI ODA ODA	F	POREBADA EAST	Household Duties	10-Aug-1987
1151	20073005	Vaguia Eapuna	F	POREBADA EAST	Household Duties	22-Apr-1982
1152	20123539	Vai Elizabeth	F	POREBADA EAST	Household Duties	18-Jun-1945
1153	20124233	Vaino Aua Igua	F	POREBADA EAST	Household Duties	27-Nov-1979
1154	20033059	Vali Antonia	F	POREBADA EAST	Teacher	\N
1155	20131318	Vanua Wari	F	POREBADA EAST	Household Duties	27-Jan-1998
1156	20227858	Varona Mairi	F	POREBADA EAST	Household Duties	20-Nov-1992
1157	20072567	Varubi Kaia	F	POREBADA EAST	Subsistence Farmer	22-Mar-1959
1158	20081427	Varubi Lucy	F	POREBADA EAST	Household Duties	11-Oct-1957
1159	20034644	Varubi Mea Boga	F	POREBADA EAST	Household Duties	01-Jan-1964
1160	20008405	VARUKO DAIRI	F	POREBADA EAST	Unemployed	01-Jan-1990
1161	20007975	VARUKO GEUA	F	POREBADA EAST	Unemployed	01-Jan-1985
1162	20002517	VARUKO HITOLO GEUA	F	POREBADA EAST	Self Employed	13-Jan-1982
1163	20031371	Varuko Hitolo Henao	F	POREBADA EAST	Household Duties	04-Feb-1986
1164	20094517	Varuko Igo Mea	F	POREBADA EAST	Household Duties	19-Jan-1990
1165	20094472	Varuko Vele Hane	F	POREBADA EAST	Household Duties	01-Jan-1953
1166	20123542	Vasiri Idau	F	POREBADA EAST	Household Duties	01-Jan-1960
1167	20123457	Vasiri Josephine	F	POREBADA EAST	Self Employed	08-Apr-1978
1168	20081372	Vasiri Manoka H	F	POREBADA EAST	Worker	18-Nov-1957
1169	20130964	Vasiri Mea	F	POREBADA EAST	Household Duties	21-Jul-1995
1170	20008240	VASIRI NELLY	F	POREBADA EAST	Unemployed	05-Mar-1971
1171	20007977	VASIRI RARANGO LOHIA	F	POREBADA EAST	Unemployed	01-Jan-1991
1172	20005019	VASIRI SARUFA MARY	F	POREBADA EAST	Household Duties	22-Oct-1970
1173	20081572	Vaso Lucy	F	POREBADA EAST	Household Duties	12-Mar-1980
1174	20081586	Vaso Melani	F	POREBADA EAST	Household Duties	03-Nov-1985
1175	20079117	Vele Guraga	F	POREBADA EAST	Household Duties	01-Jan-1966
1176	20123543	Vele Igo	F	POREBADA EAST	Household Duties	04-Dec-1987
1177	20123547	VELE JULIE	F	POREBADA EAST	Household Duties	05-Dec-1974
1178	20092725	Vele Kaia	F	POREBADA EAST	Self Employed	13-Mar-1985
1179	20131403	Vele Kari	F	POREBADA EAST	Household Duties	19-May-1994
1180	20085345	Vele Keruma	F	POREBADA EAST	Household Duties	23-Jan-1970
1181	20123548	VELE KEVAUD	F	POREBADA EAST	Household Duties	11-Apr-1973
1182	20007242	VELE LOGEA	F	POREBADA EAST	Household Duties	01-Jan-1988
1183	20227861	Vele Melanie	F	POREBADA EAST	Student	11-Jun-2000
1184	20072955	Vele Ruth	F	POREBADA EAST	Household Duties	01-Jan-1939
1185	20007244	VELE RUTH JR	F	POREBADA EAST	Unemployed	01-Jan-1989
1186	20092691	Vele Sega	F	POREBADA EAST	Household Duties	27-Jul-1975
1187	20124236	Vele Tara Kori	F	POREBADA EAST	Household Duties	31-Mar-1994
1188	20124237	Vele Tara Muraka	F	POREBADA EAST	Self Employed	14-Jun-1945
1189	20124238	Vele Tara Raka	F	POREBADA EAST	Household Duties	02-Jun-1979
1190	20003349	VELE ASI JOYCE	F	POREBADA EAST	Household Duties	11-Feb-1987
1191	20005054	VELE BUSINA ONSIN LEVA	F	POREBADA EAST	Household Duties	01-Jan-1992
1192	20005036	VELE BUSINA REBEKA MOREA	F	POREBADA EAST	Household Duties	10-Nov-1991
1193	20004160	VELE GARI GARI	F	POREBADA EAST	Household Duties	19-Sep-1991
1194	20092333	Vele Isaiah Geua	F	POREBADA EAST	Self Employed	11-Jun-1983
1195	20031437	Vele Lahui Vaburi	F	POREBADA EAST	Household Duties	04-Dec-1959
1196	20227863	Vele Martin Asi	F	POREBADA EAST	Worker	08-Mar-2000
1197	20006510	VELE TARA BOIO	F	POREBADA EAST	Household Duties	01-Jan-1993
1198	20092717	Verena Rose	F	POREBADA EAST	Household Duties	24-Apr-1983
1199	20004685	VINCENT OLI	F	POREBADA EAST	Household Duties	01-Mar-1991
1200	20036236	Waibunai Deisi	F	POREBADA EAST	Household Duties	01-Jan-1950
1201	20083609	Waike Dimere Ana	F	POREBADA EAST	Household Duties	01-Jan-1964
1202	20072571	Wakeya Dorcas	F	POREBADA EAST	Household Duties	26-Jun-1974
1203	20131277	Walo Manoka	F	POREBADA EAST	Household Duties	08-Sep-1972
1204	20067902	Wamala Kemo	F	POREBADA EAST	Household Duties	09-Jun-1956
1205	20130941	Waruru Alice	F	POREBADA EAST	Household Duties	10-Sep-1987
1206	20124241	Wau Wau Henao	F	POREBADA EAST	Self Employed	26-Feb-1986
1207	20124240	Wauwau Boio	F	POREBADA EAST	Household Duties	25-Feb-1993
1208	20062422	Willie Erue	F	POREBADA EAST	Self Employed	24-Oct-1982
1209	20007129	WILLIE GENO	F	POREBADA EAST	Unemployed	12-Jul-1994
1210	20227864	Willie Maraga	F	POREBADA EAST	Household Duties	14-Apr-1996
\.


--
-- Data for Name: porebada_east_male; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_east_male (seq, electoral_id, name, gender, location, occupation, dob) FROM stdin;
1	20003654	ABILOU KOANI INAI	M	POREBADA EAST	Student	01-Jan-1991
2	20018018	Ako Doura Vagi	M	POREBADA EAST	Self Employed	19-Jan-1991
3	20130987	Akoi Kelly	M	POREBADA EAST	Policeman	15-Mar-1979
4	20217360	Alfred Kala	M	POREBADA EAST	Fisherman	18-Jun-2000
5	20094905	Anai Gorogo	M	POREBADA EAST	Self Employed	09-Dec-1986
6	20217361	Anai Peter	M	POREBADA EAST	Fisherman	07-Jan-2001
7	20217362	Anai Raka	M	POREBADA EAST	Fisherman	12-Apr-2004
8	20131274	Anai Thomas	M	POREBADA EAST	Fisherman	25-Jan-1999
9	20095078	Aniani Arere	M	POREBADA EAST	Self Employed	08-Aug-1989
10	20095077	Aniani Arua	M	POREBADA EAST	Self Employed	05-Dec-1987
11	20130592	Aniani Peter	M	POREBADA EAST	Fisherman	05-Nov-1990
12	20003515	ANIANI ASI PETER	M	POREBADA EAST	Fisherman	01-Nov-1990
13	20031880	Aniani Teina Tom	M	POREBADA EAST	Clerk	01-Jan-1965
14	20025477	Aoae Paul	M	POREBADA EAST	Teacher	16-Feb-1963
15	20005081	ARAIDI ARAIDI	M	POREBADA EAST	Contractor	05-Dec-1977
16	20003972	ARAIDI DAIRI	M	POREBADA EAST	Unemployed	12-Mar-1971
17	20217364	Araidi Hera	M	POREBADA EAST	Unemployed	01-Dec-2003
18	20004529	ARAIDI MOREA RICHRD	M	POREBADA EAST	Driver	07-May-1967
19	20033113	Araidi Busina Busina	M	POREBADA EAST	Household Duties	01-Jan-1960
20	20003542	ARERE ARERE	M	POREBADA EAST	Student	01-Jan-1993
21	20089710	Arere Arere Mea	M	POREBADA EAST	Subsistence Farmer	13-Mar-1970
22	20095087	Arere Arua	M	POREBADA EAST	Self Employed	09-Oct-1979
23	20124115	Arere Arua Joe	M	POREBADA EAST	Self Employed	01-Jan-1938
24	20124862	Arere Asi	M	POREBADA EAST	Fisherman	17-Dec-1968
25	20088154	Arere Boio Mea	M	POREBADA EAST	Self Employed	02-Mar-1987
26	20094501	Arere Dairi	M	POREBADA EAST	Fisherman	14-Mar-1965
27	20094577	Arere Damani	M	POREBADA EAST	Self Employed	08-May-1973
28	20123353	Arere Dimere	M	POREBADA EAST	Self Employed	08-Nov-1967
29	20131280	Arere Gabriel	M	POREBADA EAST	Self Employed	10-Oct-1986
30	20088157	Arere Goasa Mea	M	POREBADA EAST	Electrician	05-Mar-1973
31	20005032	ARERE KOANI	M	POREBADA EAST	Student	07-Mar-1992
32	20129891	Arere Maba	M	POREBADA EAST	Student	27-Jul-1995
33	20008346	ARERE MEA	M	POREBADA EAST	Student	01-Jan-1993
34	20090423	Arere Mea Gari	M	POREBADA EAST	Self Employed	14-Sep-1949
35	20217366	Arere Miria Miko	M	POREBADA EAST	Fisherman	07-Aug-1994
36	20131285	Arere Morea	M	POREBADA EAST	Fisherman	15-Mar-1998
37	20054289	Arere Vaburi	M	POREBADA EAST	Salesman	19-Jan-1970
38	20003293	ARERE ASI AMOS	M	POREBADA EAST	Fisherman	23-Oct-1991
39	20056739	Arere Asi Isaiah	M	POREBADA EAST	Self Employed	18-Jul-1975
40	20092783	Arere Hitolo Gavera	M	POREBADA EAST	Subsistence Farmer	28-Dec-1980
41	20092279	Arere Hitolo Hitolo	M	POREBADA EAST	Security	18-Oct-1973
42	20217368	Arere Oda Vagi	M	POREBADA EAST	Not Specified	19-Jul-1994
43	20197926	Arere Taumaku Arua	M	POREBADA EAST	Subsistence Farmer	21-Jun-2000
44	20083708	Arere Taumaku Morea	M	POREBADA EAST	Pastor	07-Apr-1989
45	20079085	Arere Vagi Asi	M	POREBADA EAST	Self Employed	01-Jan-1987
46	20064293	Arere Vagi Heni	M	POREBADA EAST	Subsistence Farmer	16-Sep-1975
47	20023155	Arere Vagi Morea	M	POREBADA EAST	Student	29-Jul-1992
48	20064676	Aria Andrew	M	POREBADA EAST	Fitter	02-Oct-1978
49	20061841	Aria Angelo Miria	M	POREBADA EAST	Self Employed	25-Dec-1954
50	20059472	Aria Noel	M	POREBADA EAST	Student	08-Dec-1982
51	20083570	Arua Dimere	M	POREBADA EAST	Self Employed	01-Jan-1966
52	20217370	Arua Dimere	M	POREBADA EAST	Fisherman	07-Apr-2000
53	20217371	Arua Gau	M	POREBADA EAST	Student	01-Jul-2002
54	20004592	ARUA GOROGO	M	POREBADA EAST	Not Specified	14-Oct-1991
55	20078981	Arua Hasip	M	POREBADA EAST	Self Employed	12-Jul-1979
56	20123359	ARUA JACK	M	POREBADA EAST	Unemployed	29-Nov-1994
57	20092861	Arua John Morea	M	POREBADA EAST	Self Employed	01-Jan-1969
58	20083555	Arua Karua	M	POREBADA EAST	Self Employed	02-Aug-1973
59	20090499	Arua Keisy	M	POREBADA EAST	Subsistence Farmer	21-May-1987
60	20123356	Arua Kevau	M	POREBADA EAST	Banker	06-Jun-1968
61	20062433	Arua Loa Morea	M	POREBADA EAST	Fisherman	18-May-1973
62	20123357	Arua Maba	M	POREBADA EAST	Plumber	24-Oct-1973
63	20008413	ARUA MIKI	M	POREBADA EAST	Pastor	01-Jan-1973
64	20003894	ARUA MOREA	M	POREBADA EAST	Worker	01-Jan-1991
65	20003632	ARUA MOREA TARA	M	POREBADA EAST	Unemployed	24-Sep-1996
66	20131409	Arua Nohokau	M	POREBADA EAST	Fisherman	16-Jun-1991
67	20197930	Arua Pautani	M	POREBADA EAST	Student	29-Nov-1995
68	20124859	Arua Peter	M	POREBADA EAST	Fisherman	12-May-1982
69	20089709	Arua Rakatani Snr	M	POREBADA EAST	Self Employed	24-Nov-1948
70	20007922	ARUA RIU	M	POREBADA EAST	Student	01-Jan-1991
71	20007767	ARUA SAMA	M	POREBADA EAST	Doctor	01-Jan-1963
72	20007924	ARUA SIAGE	M	POREBADA EAST	Worker	01-Jan-1964
73	20087434	Arua Dairi Peter	M	POREBADA EAST	Self Employed	17-Apr-1983
74	20092805	Arua Dimere Gari	M	POREBADA EAST	Subsistence Farmer	08-Nov-1981
75	20006535	ARUA IGO NOHOKAU	M	POREBADA EAST	Unemployed	06-Jan-1991
76	20025276	Arua Igo Peter	M	POREBADA EAST	Not Specified	10-Nov-1984
77	20033077	Arua Karua Dimere	M	POREBADA EAST	Security	24-Feb-1978
78	20003531	ARUA MABA MOREA	M	POREBADA EAST	Salesman	11-Mar-1976
79	20079031	Arua Mea Gorogo	M	POREBADA EAST	Self Employed	01-Jan-1956
80	20094461	Arua Mea Lohia	M	POREBADA EAST	Self Employed	30-May-1964
81	20079038	Arua Morea Lohia	M	POREBADA EAST	Self Employed	20-Oct-1965
82	20092674	Arua Morea Vagi	M	POREBADA EAST	Subsistence Farmer	25-Sep-1958
83	20079184	Arua Riu Busina	M	POREBADA EAST	Self Employed	21-Jan-1980
84	20002541	ARUA RIU RIU	M	POREBADA EAST	Student	23-Nov-1992
85	20079190	Arua Riu Sioni	M	POREBADA EAST	Self Employed	04-Jun-1986
86	20092797	Arua Tarupa Koani	M	POREBADA EAST	Policeman	01-Jan-1970
87	20094566	Asi Aniani	M	POREBADA EAST	Self Employed	20-Apr-1956
88	20131308	Asi John	M	POREBADA EAST	Fisherman	05-Aug-1985
89	20131309	Asi Rakatani	M	POREBADA EAST	Fisherman	17-Jul-1989
90	20130938	Asi Vele	M	POREBADA EAST	Not Specified	26-Jun-1996
91	20059062	Asi Rei Busina	M	POREBADA EAST	Self Employed	06-Nov-1986
92	20062541	Asi Rei Lohia	M	POREBADA EAST	Self Employed	06-Nov-1986
93	20003624	AUA BEMU	M	POREBADA EAST	Fisherman	20-May-1980
94	20124120	Aua Heni Arua	M	POREBADA EAST	Self Employed	25-Jan-1985
95	20079124	Aua Lohia	M	POREBADA EAST	Clerk	14-Jun-1975
96	20079126	Aua Siai	M	POREBADA EAST	Self Employed	30-Aug-1977
97	20131109	Aua Tauedea	M	POREBADA EAST	Fisherman	06-Oct-1981
98	20090420	Aua Lohia Vele	M	POREBADA EAST	Security	15-Nov-1970
99	20090346	Auani Auani	M	POREBADA EAST	Salesman	15-Jan-1983
100	20090343	Auani Dairi	M	POREBADA EAST	Clerk	24-Nov-1946
101	20094580	Auani Lagani	M	POREBADA EAST	Self Employed	02-Jun-1986
102	20094527	Auani Mea	M	POREBADA EAST	Teacher	29-Sep-1957
103	20094538	Auani Robert	M	POREBADA EAST	Self Employed	29-May-1983
104	20007771	AUANI VABURI	M	POREBADA EAST	Subsistence Farmer	07-Feb-1989
105	20069646	Auani Lahui Jack	M	POREBADA EAST	Self Employed	25-May-1980
106	20064260	Auani Morea Rakatani	M	POREBADA EAST	Self Employed	01-Jan-1942
107	20123363	Audabi Hitolo	M	POREBADA EAST	Worker	01-Jun-1982
108	20123364	Audabi Mea	M	POREBADA EAST	Worker	01-Sep-1979
109	20007908	AWO CAMILO	M	POREBADA EAST	Unemployed	01-Jan-1990
110	20123365	AWO EDWARD	M	POREBADA EAST	Unemployed	01-Jan-1982
111	20007911	AWO ERNEST	M	POREBADA EAST	Unemployed	01-Jan-1958
112	20007886	AWO JOHN	M	POREBADA EAST	Unemployed	01-Jan-1986
113	20131328	Awo Joseph	M	POREBADA EAST	Fisherman	21-Oct-1988
114	20217375	Barry Anai	M	POREBADA EAST	Fisherman	17-Jan-2002
115	20129890	Baru Arere	M	POREBADA EAST	Student	27-Nov-1997
116	20081570	Baru Helai	M	POREBADA EAST	Doctor	28-Aug-1971
117	20131138	Baru Koani	M	POREBADA EAST	Worker	15-Apr-1970
118	20090338	Baru Lohia	M	POREBADA EAST	Self Employed	26-Jan-1974
119	20087376	Baru Dogo Morea	M	POREBADA EAST	Self Employed	06-Jan-1980
120	20092294	Baru Tolo Igo	M	POREBADA EAST	Pharmicist	21-Apr-1956
121	20217380	Baru Vagi Morea	M	POREBADA EAST	Unemployed	20-Jan-2002
122	20076508	Bedani Au	M	POREBADA EAST	Subsistence Farmer	03-Jul-1987
123	20072880	Bedani Gorogo	M	POREBADA EAST	Subsistence Farmer	23-Oct-1976
124	20003885	BEDANI PUNE	M	POREBADA EAST	Self Employed	12-Nov-1992
125	20072884	Bedani Tauedea	M	POREBADA EAST	Subsistence Farmer	25-Feb-1989
126	20123366	Bemu Hitolo	M	POREBADA EAST	Fisherman	22-Jul-1960
127	20131356	Bemu Raka	M	POREBADA EAST	Pastor	17-Sep-1971
128	20130747	Bemu Tauedea	M	POREBADA EAST	Fisherman	03-Dec-1994
129	20062431	Bemu Hitolo Joe	M	POREBADA EAST	Self Employed	15-Mar-1976
130	20064674	Bemu Hitolo Varona	M	POREBADA EAST	Self Employed	06-Jun-1967
131	20124122	Bodibo Virobo Morea	M	POREBADA EAST	Security	16-Aug-1982
132	20003397	BODIBO RAKATANI ANAI	M	POREBADA EAST	Self Employed	13-Oct-1991
133	20094453	Bodibo Taumaku Morea	M	POREBADA EAST	Self Employed	28-Jan-1978
134	20092860	Bodibo Taumaku Taumaku	M	POREBADA EAST	Self Employed	22-Mar-1985
135	20004164	BOE ALEX	M	POREBADA EAST	Self Employed	21-Jul-1993
136	20083547	Boe Dogodo	M	POREBADA EAST	Self Employed	15-Dec-1987
137	20083546	Boe Patrick	M	POREBADA EAST	Self Employed	05-Aug-1986
138	20081432	Boe Sam	M	POREBADA EAST	Self Employed	20-Apr-1985
139	20081423	Boe Ume	M	POREBADA EAST	Self Employed	27-May-1979
140	20051331	Bua Hitolo	M	POREBADA EAST	Self Employed	24-May-1970
141	20125718	Bua Parulu	M	POREBADA EAST	Fisherman	01-Jan-1993
142	20090252	Buruka Sioni	M	POREBADA EAST	Self Employed	27-Jan-1964
143	20217384	Busina Arua	M	POREBADA EAST	Student	19-Sep-2002
144	20009087	BUSINA BUSINA HEAGI	M	POREBADA EAST	Worker	01-Jan-1990
145	20090248	Busina David	M	POREBADA EAST	Public Servant	01-Jan-1947
146	20217385	Busina Dean	M	POREBADA EAST	Worker	02-Feb-1996
147	20217386	Busina Dimere	M	POREBADA EAST	Fisherman	29-Jul-2000
148	20125727	Busina Emmanuel	M	POREBADA EAST	Student	11-Apr-1998
149	20079021	Busina Gorogo	M	POREBADA EAST	Self Employed	18-May-1963
150	20123372	Busina Koani	M	POREBADA EAST	Self Employed	01-Jan-1972
151	20217387	Busina Lesly	M	POREBADA EAST	Fisherman	26-May-2002
152	20123373	Busina Mea	M	POREBADA EAST	Self Employed	14-Feb-1973
153	20123374	Busina Morea	M	POREBADA EAST	Self Employed	23-Oct-1967
154	20079112	Busina Moses	M	POREBADA EAST	Self Employed	08-Nov-1980
155	20131427	Busina Peter	M	POREBADA EAST	Villager	21-May-1994
156	20004695	BUSINA PETER GOATA	M	POREBADA EAST	Unemployed	01-Jan-1992
157	20123371	BUSINA Pune	M	POREBADA EAST	Student	09-Mar-1990
158	20009068	BUSINA RAKA	M	POREBADA EAST	Unemployed	01-Jan-1998
159	20003971	BUSINA TAUDEDEA	M	POREBADA EAST	Contractor	17-May-1991
735	20123464	MEA AUA	M	POREBADA EAST	Worker	06-Jun-1997
160	20004527	BUSINA MOREA ARAIDI SNR	M	POREBADA EAST	Unemployed	16-Jul-1937
161	20072901	Busina Morea Goata Gorogo	M	POREBADA EAST	Self Employed	01-Jan-1956
162	20090270	Busina Morea Mea	M	POREBADA EAST	Consultant	12-Dec-1953
163	20075994	Busina Morea Peter	M	POREBADA EAST	Self Employed	01-Jan-1944
164	20079108	Busina Tabe Tabe	M	POREBADA EAST	Store Keeper	30-Dec-1975
165	20124123	Busini Araidi Araidi	M	POREBADA EAST	Chef	30-Aug-1984
166	20076443	Charlie Roy	M	POREBADA EAST	Subsistence Farmer	02-May-1968
167	20125719	Dabara Isaac	M	POREBADA EAST	Fisherman	16-Oct-1992
168	20079052	Daera Morea	M	POREBADA EAST	Self Employed	04-Jan-1978
169	20079051	Daera Pune	M	POREBADA EAST	Self Employed	26-Jan-1976
170	20079092	Daera Raka	M	POREBADA EAST	Self Employed	23-Apr-1980
171	20087709	Daera Tabe	M	POREBADA EAST	Student	06-Oct-1986
172	20217388	Dairi Gari	M	POREBADA EAST	Unemployed	29-Jun-1993
173	20004214	Dairi GAVERA	M	POREBADA EAST	Worker	27-Dec-1992
174	20079063	Dairi Gorogo	M	POREBADA EAST	Self Employed	01-Jan-1966
175	20079151	Dairi Henao	M	POREBADA EAST	Self Employed	15-Jun-1962
176	20067909	Dairi Mea	M	POREBADA EAST	Student	05-Apr-1989
177	20130741	Dairi Morea	M	POREBADA EAST	Fisherman	03-Mar-1987
178	20130936	Dairi Pota	M	POREBADA EAST	Household Duties	07-Oct-1996
179	20005161	DAIRI TAMARUA	M	POREBADA EAST	Unemployed	19-Feb-1991
180	20032997	Dairi Auani Lahui	M	POREBADA EAST	Worker	08-Jun-1976
181	20081419	Dairi Sioni Lohia	M	POREBADA EAST	Self Employed	01-Jan-1964
182	20197929	Damani Arere	M	POREBADA EAST	Student	22-Jun-1999
183	20217391	Damani Colin	M	POREBADA EAST	Fisherman	09-Jun-2003
184	20069663	David Henry	M	POREBADA EAST	Self Employed	22-Sep-1983
185	20090434	David Morea	M	POREBADA EAST	Clerk	23-Aug-1973
186	20069662	David Morea Mula	M	POREBADA EAST	Self Employed	23-Mar-1979
187	20124127	David Morea Toea	M	POREBADA EAST	Fisherman	18-Nov-1989
188	20090259	David Riu	M	POREBADA EAST	Self Employed	01-Aug-1976
189	20069660	David Taumaku	M	POREBADA EAST	Supervisor	15-Dec-1976
190	20032540	David Busina Gari	M	POREBADA EAST	Self Employed	01-Jan-1983
191	20072898	Dimere Arere	M	POREBADA EAST	Subsistence Farmer	01-Jan-1961
192	20125723	Dimere Arere	M	POREBADA EAST	Student	19-Jan-1993
193	20123377	Dimere Arua	M	POREBADA EAST	Pastor	16-Dec-1958
194	20130942	Dimere Beatrice	M	POREBADA EAST	Not Specified	26-Nov-1988
195	20130945	Dimere Dairi Goata	M	POREBADA EAST	Student	06-Mar-1997
196	20037938	Dimere Doura	M	POREBADA EAST	Self Employed	18-Mar-1945
197	20092357	Dimere Gorogo	M	POREBADA EAST	Fisherman	25-Sep-1960
198	20123378	Dimere Koani	M	POREBADA EAST	Self Employed	20-Oct-1954
199	20092328	Dimere Kokoro	M	POREBADA EAST	Fisherman	21-Sep-1951
200	20123379	Dimere Loulai	M	POREBADA EAST	Self Employed	20-Nov-1958
201	20081588	Dimere Mea	M	POREBADA EAST	Mechanic	01-Jan-1964
202	20123380	Dimere Pune	M	POREBADA EAST	Draftsman	12-Feb-1958
203	20092337	Dimere Riu	M	POREBADA EAST	Self Employed	01-Jan-1971
204	20217393	Dimere Robert	M	POREBADA EAST	Student	10-May-2002
205	20123381	Dimere Siage	M	POREBADA EAST	Self Employed	01-Jan-1973
206	20058866	Dimere Tara	M	POREBADA EAST	Self Employed	01-Jan-1971
207	20079088	Dimere Vagi	M	POREBADA EAST	Self Employed	06-Sep-1962
208	20124861	Dirona Tau	M	POREBADA EAST	Fisherman	30-Jul-1998
209	20124129	Dorido Henry Henry	M	POREBADA EAST	Self Employed	31-May-1985
210	20123384	Doura Busina	M	POREBADA EAST	Magistrate	21-Nov-1968
211	9920124916	Doura Dairi	M	POREBADA EAST	Self Employed	27-Jun-1998
212	20004179	DOURA DIMERE	M	POREBADA EAST	Pastor	16-Jun-1966
213	20130590	Doura Gau	M	POREBADA EAST	Fisherman	09-Dec-1994
214	20092591	Doura Igo	M	POREBADA EAST	Fisherman	03-Jan-1987
215	20003610	DOURA MOREA	M	POREBADA EAST	Worker	01-Jan-1959
216	20217394	Doura Sioni	M	POREBADA EAST	Worker	18-Mar-1994
217	20131290	Doura Sisia	M	POREBADA EAST	Fisherman	13-Dec-1997
218	20131289	Doura Toua	M	POREBADA EAST	Fisherman	16-Jun-1994
219	20004189	DOURA DIMERE VAGI	M	POREBADA EAST	Policeman	14-Feb-1970
220	20003342	DOURA MOREA BRIAN	M	POREBADA EAST	Worker	01-Jul-1990
221	20003419	DUAHI ARAIDI	M	POREBADA EAST	Worker	10-Oct-1969
222	20034131	Duahi Morea Peter	M	POREBADA EAST	Self Employed	12-Dec-1972
223	20033843	Duahi Morea Tom	M	POREBADA EAST	Self Employed	05-May-1958
224	20227560	Eddie Peter	M	POREBADA EAST	Fisherman	13-Feb-1989
225	20081123	Edea Bodibo	M	POREBADA EAST	Self Employed	03-Mar-1979
226	20079002	Edea Momoru	M	POREBADA EAST	Self Employed	24-Feb-1984
227	20078634	Edea Vagi	M	POREBADA EAST	Self Employed	22-Nov-1980
228	20124973	Edoni Joseph	M	POREBADA EAST	Worker	14-Nov-1970
229	20124978	Elly Pune Michael	M	POREBADA EAST	Fisherman	02-Feb-1999
230	20227561	Emmanuel Morea	M	POREBADA EAST	Fisherman	03-Sep-1994
231	20003649	EMMANUEL UME JACK	M	POREBADA EAST	Security	\N
1266	20034383	Vele Hitolo Lohia	M	POREBADA EAST	Self Employed	05-Aug-1985
232	20083562	Evoa Igua	M	POREBADA EAST	Self Employed	01-Jan-1976
233	20124860	Fave Fave	M	POREBADA EAST	Household Duties	16-Mar-1979
234	20131419	Fave George	M	POREBADA EAST	Security	23-Mar-1980
235	20131418	Fave Taumaku	M	POREBADA EAST	Fisherman	15-Mar-1997
236	20005166	FRANSIS LAHUI	M	POREBADA EAST	Self Employed	10-Jan-1979
237	20124132	Gabe Arua Arua	M	POREBADA EAST	Clerk	06-Oct-1979
238	20130976	Gabe Vave	M	POREBADA EAST	Not Specified	01-Jan-1998
239	20004636	GABI VALI	M	POREBADA EAST	Worker	01-Jan-1981
240	20081557	Gahusi Hitolo	M	POREBADA EAST	Self Employed	21-Oct-1959
241	20083553	Gahusi Simon	M	POREBADA EAST	Subsistence Farmer	01-Jan-1963
242	20092792	Gahusi Gahusi Lohia Abdul	M	POREBADA EAST	Self Employed	22-Aug-1972
243	20124842	Gali Moale	M	POREBADA EAST	Surveyor	02-Aug-1982
244	20124847	Gali Vagi	M	POREBADA EAST	Fisherman	05-Nov-1998
245	20124975	Ganiga Thomas Douna	M	POREBADA EAST	Worker	18-Jun-1984
246	20130740	Gari Dairi	M	POREBADA EAST	Security	19-May-1994
247	20085347	Gari Fred	M	POREBADA EAST	Worker	21-Jun-1980
248	20083703	Gari Heagi	M	POREBADA EAST	Unemployed	24-Feb-1985
249	20085433	Gari Heni	M	POREBADA EAST	Unemployed	25-May-1976
250	20083645	Gari Kovae	M	POREBADA EAST	Worker	29-Sep-1974
251	20092871	Gari Lahui	M	POREBADA EAST	Self Employed	26-Jun-1975
252	20125732	Gari Morea	M	POREBADA EAST	Student	26-Jun-1998
253	20073013	Gari Vagi	M	POREBADA EAST	Subsistence Farmer	01-Jan-1932
254	20035525	Gari Vele Arua	M	POREBADA EAST	Clergyman	26-Jun-1962
255	20069655	Gari Irua Heagi	M	POREBADA EAST	Self Employed	16-Jun-1965
256	20072539	Gari Keni Lohia	M	POREBADA EAST	Self Employed	01-Jan-1945
257	20092791	Gau Baru	M	POREBADA EAST	Electrician	07-Dec-1973
258	20227566	Gau Benjamin	M	POREBADA EAST	Fisherman	21-Jul-2003
259	20083922	Gau Doura	M	POREBADA EAST	Self Employed	12-Jun-1971
260	20009392	GAU GAU PETER	M	POREBADA EAST	Worker	26-Jul-1988
261	20083690	Gau Gaudi	M	POREBADA EAST	Self Employed	11-Sep-1973
262	20081397	Gau Gure	M	POREBADA EAST	Security	15-Jul-1973
263	20081542	Gau Heagi	M	POREBADA EAST	Unemployed	24-Nov-1979
264	20051356	Gau Helai	M	POREBADA EAST	Self Employed	24-Apr-1973
265	20124135	Gau Igo Igo	M	POREBADA EAST	Self Employed	06-Mar-1947
266	20076554	Gau Irua	M	POREBADA EAST	Self Employed	01-Jan-1958
267	20059048	Gau Iruna	M	POREBADA EAST	Self Employed	01-Jan-1945
268	20076562	Gau Lohia	M	POREBADA EAST	Self Employed	01-Jan-1961
269	20088156	Gau Moi	M	POREBADA EAST	Self Employed	10-May-1950
270	20008229	GAU MOREA PETER	M	POREBADA EAST	Engineer	03-Feb-1976
271	20085478	Gau Taumaku	M	POREBADA EAST	Unemployed	23-Feb-1982
272	20003519	GAU VAGI	M	POREBADA EAST	Unemployed	01-Jan-1993
273	20092698	Gau Vagi	M	POREBADA EAST	Electrician	04-Jun-1969
274	20083716	Gau Helai John	M	POREBADA EAST	Self Employed	02-Nov-1965
275	20047093	Gau Helai Mea	M	POREBADA EAST	Subsistence Farmer	12-Aug-1976
276	20032187	Gau Helai Morea	M	POREBADA EAST	Driver	11-Sep-1963
277	20069551	Gau Irua Arua	M	POREBADA EAST	Self Employed	01-Jan-1972
278	20033567	Gau Irua Heagi	M	POREBADA EAST	Self Employed	16-Jun-1965
279	20031905	Gau Lohia Mea	M	POREBADA EAST	Self Employed	01-Feb-1967
280	20031289	Gau Pako Morea	M	POREBADA EAST	Self Employed	24-Dec-1950
281	20030951	Gau Pako Peter	M	POREBADA EAST	Self Employed	22-Aug-1952
282	20092740	Gau Vagi Morea	M	POREBADA EAST	Student	04-Dec-1981
283	20087681	Gaudi Ebo	M	POREBADA EAST	Student	17-Apr-1990
284	20130758	Gaudi Inara	M	POREBADA EAST	Fisherman	10-Nov-1994
285	20005140	GAUDI KOANI	M	POREBADA EAST	Self Employed	12-Dec-1991
286	20124134	Gaudi Mere Tara	M	POREBADA EAST	Self Employed	16-Sep-1977
287	20227569	Gavera Dennice	M	POREBADA EAST	Fisherman	28-Feb-1997
288	20003524	GAVERA IAN	M	POREBADA EAST	Unemployed	01-Jan-1990
289	20197947	Gavera James	M	POREBADA EAST	Subsistence Farmer	30-Jun-2000
290	20227570	Gavera Jimmy	M	POREBADA EAST	Student	29-Jun-2000
291	20062439	Gavera Morea	M	POREBADA EAST	Self Employed	16-Jan-1979
292	20227571	Gavera Sevese	M	POREBADA EAST	Student	26-Jan-2003
293	20131378	Gavera Tarube	M	POREBADA EAST	Fisherman	05-Jul-1995
294	20123392	Gavera Vasiri	M	POREBADA EAST	Self Employed	13-Jan-1970
295	20227572	Gavera Vasiri	M	POREBADA EAST	Student	17-Jan-2001
296	20009437	GAVERA GOROGO GOROGO	M	POREBADA EAST	Fisherman	02-Oct-1993
297	20008959	GEBORE RON	M	POREBADA EAST	Teacher	07-Jun-1965
298	20004209	GEGE BODIBO	M	POREBADA EAST	Unemployed	01-Jan-1991
299	20017932	Gege Vagi Tauedea	M	POREBADA EAST	Worker	03-Jun-1989
300	20130919	Gemona Arua	M	POREBADA EAST	Household Duties	08-Apr-1997
301	20130920	Gemona Moeka	M	POREBADA EAST	Student	06-Aug-1995
302	20023636	George Dairi	M	POREBADA EAST	Subsistence Farmer	18-Mar-1973
303	20005184	GMNI WAULA GELEGELE	M	POREBADA EAST	Student	26-Apr-1991
304	20130961	Goasa Mesole	M	POREBADA EAST	Self Employed	15-Feb-1996
305	20227574	Goasa Mea Jimmy	M	POREBADA EAST	Unemployed	06-Feb-2001
306	20005120	GOATA BARU	M	POREBADA EAST	Driver	18-Jan-1989
307	20083930	Goata Heau	M	POREBADA EAST	Self Employed	05-Jun-1984
308	20130913	Goata Kana	M	POREBADA EAST	Student	27-May-1997
309	20123395	Goata Karua Jeff	M	POREBADA EAST	Self Employed	15-Jan-1960
310	20227576	Goata Kevau	M	POREBADA EAST	Fisherman	13-Dec-2000
311	20227577	Goata Kwara	M	POREBADA EAST	Fisherman	15-Feb-1999
312	20123396	Goata Lohia	M	POREBADA EAST	Self Employed	12-Mar-1963
313	20131311	Goata Lohia	M	POREBADA EAST	Not Specified	26-Nov-1958
314	9920130591	Goata Manasseh	M	POREBADA EAST	Worker	28-Aug-1994
315	20076473	Goata Mea	M	POREBADA EAST	Self Employed	20-Jan-1972
316	20062437	Goata Merabo	M	POREBADA EAST	Self Employed	16-Dec-1963
317	20072939	Goata Morea	M	POREBADA EAST	Mechanic	20-Jun-1965
318	20124138	Goata Morea Aleva	M	POREBADA EAST	Fisherman	31-Dec-1990
319	20227578	Goata Varuko	M	POREBADA EAST	Student	22-Feb-2003
320	9920130596	Goata Vau	M	POREBADA EAST	Fisherman	06-Jun-1995
321	20032469	Goata Lohia Peter	M	POREBADA EAST	Subsistence Farmer	14-Oct-1951
322	20197927	Goata Peter Igo	M	POREBADA EAST	Student	31-May-1999
323	20130981	Gorogo Busina	M	POREBADA EAST	Student	20-May-1997
324	20227581	Gorogo Dimele	M	POREBADA EAST	Fisherman	18-Sep-1999
325	20072947	Gorogo Doura	M	POREBADA EAST	Teacher	24-Feb-1965
326	20131132	Gorogo Gau	M	POREBADA EAST	Fisherman	17-May-1990
327	20004585	GOROGO GAVERA	M	POREBADA EAST	Unemployed	01-Jan-1993
328	20227583	Gorogo Gavera	M	POREBADA EAST	Student	05-Apr-2001
329	20123397	Gorogo George B	M	POREBADA EAST	Self Employed	03-Jul-1988
330	20227584	Gorogo Heagi Leisy	M	POREBADA EAST	Not Specified	18-Mar-1964
331	20004624	GOROGO HEAV	M	POREBADA EAST	Worker	01-Jan-1991
332	20131329	Gorogo Homoka	M	POREBADA EAST	Driver	06-Oct-1967
333	20003614	GOROGO JACK	M	POREBADA EAST	Unemployed	01-Jan-1982
334	20059224	Gorogo Lahui	M	POREBADA EAST	Self Employed	12-May-1982
335	20078740	Gorogo Morea	M	POREBADA EAST	Subsistence Farmer	01-Jan-1960
336	20123400	GOROGO MOREA	M	POREBADA EAST	Unemployed	01-Jan-1991
337	20125785	Gorogo Riu	M	POREBADA EAST	Student	25-May-1997
338	20227587	Gorogo Taumaku	M	POREBADA EAST	Student	23-Dec-2002
339	20227588	Gorogo Vagi	M	POREBADA EAST	Unemployed	08-May-2000
340	20003975	GOROGO ARUA BAU	M	POREBADA EAST	Contractor	11-Jun-1988
341	20079036	Gorogo Arua Jack	M	POREBADA EAST	Self Employed	01-Jan-1982
342	20079183	Gorogo Arua Kieth	M	POREBADA EAST	Self Employed	01-Jan-1977
343	20003976	GOROGO ARUA RICHARD	M	POREBADA EAST	Unemployed	01-Jan-1990
344	20092366	Gorogo Arua Seri	M	POREBADA EAST	Security	07-May-1980
345	20076005	Gorogo Gari Mea	M	POREBADA EAST	Self Employed	09-Feb-1969
346	20075985	Gorogo Gari Saimon	M	POREBADA EAST	Self Employed	14-Feb-1971
347	20072900	Gorogo Gari Taunao	M	POREBADA EAST	Self Employed	14-Feb-1971
348	20079025	Gorogo Keni Heagi	M	POREBADA EAST	Self Employed	18-Apr-1936
349	20025740	Gorogo Koani Gavera	M	POREBADA EAST	Self Employed	06-Jun-1963
350	20064683	Gorogo Koani Homoka	M	POREBADA EAST	Driver	01-Jan-1966
351	20067584	Gorogo Koani Oda	M	POREBADA EAST	Self Employed	04-Oct-1963
352	20089713	Gorogo Koani Peter	M	POREBADA EAST	Self Employed	18-Mar-1971
353	20051176	Gorogo Riu Arua	M	POREBADA EAST	Self Employed	09-Oct-1983
354	20054209	Gorogo Riu Riu	M	POREBADA EAST	Engineer	24-May-1979
355	20227589	Guba Mea	M	POREBADA EAST	Student	10-Jan-2003
356	20031369	Guba Daera Igo	M	POREBADA EAST	Self Employed	01-Jan-1951
357	20003640	HALU MARABE	M	POREBADA EAST	Unemployed	01-Jan-1987
358	20124875	Harry Peter	M	POREBADA EAST	Worker	21-Jul-1992
359	20227590	Hau Vaino	M	POREBADA EAST	Worker	29-May-1998
360	20076555	Havata Chris	M	POREBADA EAST	Self Employed	16-Nov-1986
361	20094492	Havata Koani	M	POREBADA EAST	Fisherman	19-Apr-1975
362	20076545	Havata Lohia	M	POREBADA EAST	Self Employed	03-Feb-1984
363	20123404	Havata Morea	M	POREBADA EAST	Maintenance Worker	22-Oct-1971
364	20227591	Havata Nama	M	POREBADA EAST	Fisherman	03-Aug-2000
365	20094499	Havata Pune Joe	M	POREBADA EAST	Fisherman	25-Apr-1977
366	20003339	HAVATA LOHIA STANLY	M	POREBADA EAST	Self Employed	19-Jan-1988
367	20003888	HAVATA PUNE DAIRI	M	POREBADA EAST	Worker	03-Dec-1972
368	20009419	HAVATA PUNE GOROGO	M	POREBADA EAST	Pastor	19-May-1968
369	20124147	Heagi Busina Busina	M	POREBADA EAST	Worker	11-Nov-1980
370	20092671	Heagi Gau	M	POREBADA EAST	Self Employed	09-Oct-1996
371	20123406	Heagi Gau	M	POREBADA EAST	Unemployed	16-Jun-1965
372	20227592	Heagi Gau	M	POREBADA EAST	Fisherman	11-Apr-2004
373	20124982	Heagi Gorogo	M	POREBADA EAST	Fisherman	01-Jan-1966
374	20124148	Heagi Gorogo Morea	M	POREBADA EAST	Self Employed	15-Oct-1974
375	20124149	Heagi Gorogo Morea Babun	M	POREBADA EAST	Teacher	07-Jul-1969
376	20123409	Heagi Mea	M	POREBADA EAST	Self Employed	03-Nov-1987
377	20004528	HEAGI TAUMAKU	M	POREBADA EAST	Unemployed	01-Jan-1993
378	20054803	Heagi Toua	M	POREBADA EAST	Self Employed	19-Sep-1958
379	20056628	Heagi Gari Heagi	M	POREBADA EAST	Self Employed	01-Jan-1960
380	20069683	Heagi Gau Gari	M	POREBADA EAST	Self Employed	03-Mar-1986
381	20022418	Heagi Gorogo Asi	M	POREBADA EAST	Self Employed	11-Sep-1990
382	20022396	Heagi Gorogo Gorogo	M	POREBADA EAST	Fisherman	01-Jan-1989
383	20076592	Heagi Gorogo John	M	POREBADA EAST	Self Employed	12-Jan-1987
384	20227594	Heagi Gorogo Taumaku	M	POREBADA EAST	Unemployed	23-Sep-1993
385	20030882	Heagi Heagi Heagi	M	POREBADA EAST	Self Employed	21-Aug-1962
386	20054313	Heagi Heagi Tom	M	POREBADA EAST	Self Employed	07-Dec-1983
387	20227595	Heagi Leisi Arua	M	POREBADA EAST	Unemployed	13-Feb-2002
388	20131413	Heau Baru	M	POREBADA EAST	Student	03-Mar-1999
389	20123446	Heau Gorogo	M	POREBADA EAST	Fisherman	01-Jan-1971
390	20130910	Heau Homoka	M	POREBADA EAST	Student	07-Apr-1996
391	20004234	HEAU MOREA	M	POREBADA EAST	Worker	01-Jan-1970
392	20124151	Heau Vagi Morea	M	POREBADA EAST	Pastor	01-Oct-1982
393	20003638	HEAU VAGI VAGI	M	POREBADA EAST	Unemployed	13-Feb-1992
394	20125789	Helai Gersom	M	POREBADA EAST	Student	08-Jan-1993
395	20227597	Helai Jemo	M	POREBADA EAST	Worker	18-Jun-1994
396	20036802	Helai Morea	M	POREBADA EAST	Self Employed	01-Jan-1936
397	20125790	Helai Morea	M	POREBADA EAST	Student	18-Jun-1994
398	20092293	Helai Pune	M	POREBADA EAST	Subsistence Farmer	21-Dec-1950
399	20130930	Helai Raga	M	POREBADA EAST	Fisherman	15-May-1993
400	20123415	HELAI TAUEDEA	M	POREBADA EAST	Worker	29-Oct-1991
401	20090482	Helai Pune Simon	M	POREBADA EAST	Subsistence Farmer	16-Jan-1978
402	20197934	Helangi Kora	M	POREBADA EAST	Subsistence Farmer	01-Dec-1975
403	20076601	Henao Isaiah	M	POREBADA EAST	Self Employed	29-Aug-1975
404	20003883	HENAO LAHUI FIVE	M	POREBADA EAST	Self Employed	10-Jan-1979
405	20079122	Heni Aua	M	POREBADA EAST	Self Employed	05-Oct-1949
406	20003629	HENI JUNIOR VAGI	M	POREBADA EAST	Worker	27-Sep-1983
407	20092363	Heni Simon	M	POREBADA EAST	Subsistence Farmer	04-Jul-1944
408	20130636	Heni Toua	M	POREBADA EAST	Worker	23-Sep-1995
409	20022383	Heni Vagi Victory	M	POREBADA EAST	Self Employed	17-Dec-1976
410	20004248	HENI SIAGE GAU NELSON	M	POREBADA EAST	Worker	21-Apr-1972
411	20004249	HENI SIAGE IGO	M	POREBADA EAST	Driver	06-Apr-1964
412	20087704	Heni Siage Ray Tom	M	POREBADA EAST	Self Employed	01-Jan-1958
413	20092810	Heni Vagi Vagi	M	POREBADA EAST	Public Servant	17-Aug-1954
414	20004149	HENRY ODA	M	POREBADA EAST	Unemployed	01-Jan-1990
415	20123416	Henry Taumaku	M	POREBADA EAST	Self Employed	01-Jan-1961
416	20090452	Henry Vagi	M	POREBADA EAST	Self Employed	07-Dec-1987
417	20036680	Henry Dorido Dorido	M	POREBADA EAST	Self Employed	01-Jan-1965
418	20035512	Henry Hitolo Hiltolo	M	POREBADA EAST	Student	06-Aug-1988
419	20124854	Hila Elijah	M	POREBADA EAST	Student	18-Dec-1991
420	20022407	Hila Sibona	M	POREBADA EAST	Fisherman	14-Mar-1990
421	20124972	Hitolo Alfred	M	POREBADA EAST	Household Duties	22-May-1977
422	20078743	Hitolo Baeau	M	POREBADA EAST	Subsistence Farmer	15-May-1979
423	20131411	Hitolo Basil	M	POREBADA EAST	Student	27-Apr-1995
424	20131306	Hitolo Bemu	M	POREBADA EAST	Fisherman	24-Apr-1996
425	20123419	Hitolo Enere Henry	M	POREBADA EAST	Self Employed	09-Sep-1966
426	20227600	Hitolo Jamieson	M	POREBADA EAST	Security	17-Dec-1998
427	20069269	Hitolo John	M	POREBADA EAST	Self Employed	08-Mar-1978
428	20123420	Hitolo Kevin	M	POREBADA EAST	Self Employed	15-Apr-1985
429	20059211	Hitolo Lohia	M	POREBADA EAST	Self Employed	12-Feb-1978
430	20130737	Hitolo Meauri	M	POREBADA EAST	Household Duties	23-Jan-1995
431	20061833	Hitolo Momoru	M	POREBADA EAST	Self Employed	28-Apr-1946
432	20227603	Hitolo Momoru	M	POREBADA EAST	Fisherman	05-Aug-2001
433	20123421	Hitolo Morea	M	POREBADA EAST	Student	04-Mar-1989
434	20130625	Hitolo Morea	M	POREBADA EAST	Household Duties	19-Sep-1993
435	20073000	Hitolo Morea  Srn	M	POREBADA EAST	Self Employed	09-Jul-1976
436	20003880	HITOLO PUNE LOHIA	M	POREBADA EAST	Unemployed	01-Jan-1993
437	20069752	Hitolo Simon	M	POREBADA EAST	Self Employed	12-May-1979
438	20131412	Hitolo Sioni	M	POREBADA EAST	Fisherman	10-Oct-1993
439	20227606	Hitolo Varuko	M	POREBADA EAST	Fisherman	05-Sep-2001
440	20124153	Hitolo Varuko Lohia	M	POREBADA EAST	Self Employed	26-Sep-1969
441	20124154	Hitolo Varuko Morea	M	POREBADA EAST	Self Employed	20-Feb-1975
442	20057198	Hitolo Vele	M	POREBADA EAST	Student	23-Jun-1989
443	20123422	Hitolo Vele	M	POREBADA EAST	Unemployed	18-Aug-1960
444	20081569	Hitolo Gahusi Idau	M	POREBADA EAST	Self Employed	12-May-1978
445	20005038	HITOLO IGO TAUMAKU	M	POREBADA EAST	Self Employed	17-Jul-1992
446	20227609	Hitolo Momoru Chris	M	POREBADA EAST	Student	27-Sep-1999
447	20033460	Hitolo Morea Morea	M	POREBADA EAST	Self Employed	23-Sep-1976
448	20078745	Hitolo Morea Taumaku	M	POREBADA EAST	Subsistence Farmer	01-Jan-1969
449	20227610	Hitolo Tau Tara	M	POREBADA EAST	Fisherman	11-Oct-2001
450	20005034	HITOLO TAUEDEA MURA	M	POREBADA EAST	Self Employed	20-Sep-1989
451	20031889	Hitolo Varuko Varuko	M	POREBADA EAST	Self Employed	01-Jan-1962
452	20123423	Homoka Igo	M	POREBADA EAST	Subsistence Farmer	01-Sep-1971
453	20064686	Homoka Koani Koani	M	POREBADA EAST	Self Employed	03-Oct-1974
454	20061842	Homoka Koani Tauedea	M	POREBADA EAST	Self Employed	01-Apr-1969
455	20004251	HOOPER STANLEY	M	POREBADA EAST	Worker	18-Jan-1967
456	20130629	Hooper Stanley	M	POREBADA EAST	Student	25-Aug-1998
457	20062523	Iageti Atara	M	POREBADA EAST	Self Employed	16-Sep-1975
458	20059217	Iageti Dairi	M	POREBADA EAST	Self Employed	05-Jul-1977
459	20124155	Igo Dairi Tauedea	M	POREBADA EAST	Subsistence Farmer	01-Jan-1941
460	20227617	Igo Desmon	M	POREBADA EAST	Unemployed	05-May-2002
461	20056642	Igo Karoho	M	POREBADA EAST	Unemployed	02-May-1979
462	20059280	Igo Koani	M	POREBADA EAST	Self Employed	07-Jul-1959
463	20124160	Igo Lahui Gari	M	POREBADA EAST	Fisherman	09-May-1961
464	20130631	Igo Rodney	M	POREBADA EAST	Household Duties	23-Aug-1992
465	20090435	Igo Romney	M	POREBADA EAST	Student	23-Aug-1986
466	20227643	Igo Tommy Toea	M	POREBADA EAST	Fisherman	11-Feb-1964
467	20227644	Igo Vagi	M	POREBADA EAST	Unemployed	13-Dec-2000
468	20006540	IGO ARUA GERRY	M	POREBADA EAST	Student	20-Sep-1989
469	20006541	IGO ARUA KEVAU	M	POREBADA EAST	Student	20-May-1993
470	20092362	Igo Baru Baru	M	POREBADA EAST	Student	13-Apr-1982
471	20090260	Igo Baru Heau	M	POREBADA EAST	Student	12-Sep-1988
472	20079029	Igo Gari Dairi	M	POREBADA EAST	Self Employed	10-Sep-1952
473	20008970	IGO HENI NOEL	M	POREBADA EAST	Carpenter	08-Aug-1989
474	20031387	Igo Morea Arua	M	POREBADA EAST	Security	03-Mar-1959
475	20022400	Igo Pautani Arua	M	POREBADA EAST	Self Employed	14-Mar-1990
476	20031833	Igo Pautani Koani	M	POREBADA EAST	Self Employed	05-Nov-1987
477	20031439	Igo Pautani Pautani	M	POREBADA EAST	Self Employed	18-Mar-1974
478	20094544	Igo Varuko Hitolo	M	POREBADA EAST	Subsistence Farmer	19-Nov-1968
479	20094537	Igo Varuko Varuko	M	POREBADA EAST	Fitter	28-Nov-1965
480	20059417	Igua Momoru	M	POREBADA EAST	Self Employed	01-Jul-1978
481	20131349	Ikai'Ini Aisi	M	POREBADA EAST	Pastor	10-Sep-1959
482	20090416	Inara Sioni	M	POREBADA EAST	Driver	24-Feb-1982
483	20227645	Iobi Junior	M	POREBADA EAST	Student	12-Jun-1999
484	20124815	Irua Gau	M	POREBADA EAST	Fisherman	26-Jun-1988
485	20123433	Irua Tara	M	POREBADA EAST	Security	01-Jan-1983
486	20062501	Iruna Lahui	M	POREBADA EAST	Self Employed	01-Jan-1980
487	20003585	IRUNA GAU GAU	M	POREBADA EAST	Worker	27-Oct-1992
488	20064671	Isaiah Andy Lohia	M	POREBADA EAST	Self Employed	11-May-1985
489	20130932	Isaiah Doura	M	POREBADA EAST	Fisherman	15-Apr-1964
490	20062530	Isaiah Isaiah Lohia	M	POREBADA EAST	Self Employed	06-Aug-1976
491	20006018	ISAIAH KOANI	M	POREBADA EAST	Unemployed	30-Apr-1976
492	20059225	Isaiah Lohia Snr	M	POREBADA EAST	Self Employed	01-Apr-1955
493	20197963	ISAIAH Madaha	M	POREBADA EAST	Fisherman	24-Oct-1991
494	20124162	Isaiah Tabe Morea	M	POREBADA EAST	Subsistence Farmer	01-Aug-1963
495	20083721	Isaiah Vagi	M	POREBADA EAST	Unemployed	15-May-1957
496	20227651	Isaiah Vele	M	POREBADA EAST	Fisherman	15-Jun-2000
497	20227652	Isaiah Dairi Port Moresby	M	POREBADA EAST	Fisherman	17-Dec-2002
498	20033585	Isaiah Koani Igo	M	POREBADA EAST	Self Employed	10-Mar-1981
499	20035519	Isaiah Koani Iruna	M	POREBADA EAST	Self Employed	27-Aug-1984
500	20033514	Isaiah Koani Lahui	M	POREBADA EAST	Self Employed	20-Nov-1983
501	20081559	Isaiah Oda Morea	M	POREBADA EAST	Self Employed	01-Jan-1964
502	20090258	Isaiah Tabe Mea	M	POREBADA EAST	Subsistence Farmer	04-Oct-1974
503	20090251	Isaiah Tabe Vagi	M	POREBADA EAST	Subsistence Farmer	28-Feb-1969
504	20031995	Isaiah Vagi John	M	POREBADA EAST	Self Employed	11-Aug-1969
505	20081587	Iva Raymond	M	POREBADA EAST	Self Employed	22-Jun-1988
506	20125787	Ivai Billy Busina	M	POREBADA EAST	Student	13-Mar-1998
507	20125786	Ivai Lou	M	POREBADA EAST	Fisherman	24-May-1995
508	20062162	Ivi Pilu	M	POREBADA EAST	Worker	30-Nov-1947
509	20087387	Jack Auani	M	POREBADA EAST	Student	16-Aug-1983
510	20045413	Jack Kokoro	M	POREBADA EAST	Self Employed	22-Sep-1972
511	20081502	Jack Lahui	M	POREBADA EAST	Self Employed	29-Dec-1970
512	20081478	Jack Momoru	M	POREBADA EAST	Pastor	16-Sep-1976
513	20081439	Jack Morea	M	POREBADA EAST	Self Employed	02-Aug-1974
514	20227654	James Jimmy	M	POREBADA EAST	Student	05-Jan-1995
515	20131379	James Vasiri	M	POREBADA EAST	Student	01-Jan-1998
516	20081534	Jerry Miki	M	POREBADA EAST	Self Employed	12-Feb-1982
517	20079048	Jimmy Morea	M	POREBADA EAST	Supervisor	25-Feb-1978
518	20032157	Jimmy Lohia Havata	M	POREBADA EAST	Self Employed	12-Dec-1974
519	20124163	Joe Dairi Rupert	M	POREBADA EAST	Self Employed	09-Dec-1975
520	20130956	Joe Doriga	M	POREBADA EAST	Self Employed	23-Oct-1993
521	20008722	JOE GIMA	M	POREBADA EAST	Unemployed	01-Jan-1980
522	20076730	Joe Rex	M	POREBADA EAST	Self Employed	02-Jun-1980
523	20130958	Joe Vani	M	POREBADA EAST	Student	25-Jul-1997
524	20004174	JOHN ANAWE	M	POREBADA EAST	Security	25-Jun-1987
525	20125737	John Isaiah	M	POREBADA EAST	Storeman	26-Sep-1994
526	20009464	JOHN JOSHUA	M	POREBADA EAST	Unemployed	01-Jan-1992
527	20227659	John Nou	M	POREBADA EAST	Fisherman	01-Jan-2000
528	20131142	John Sara	M	POREBADA EAST	Doctor	01-Jan-1993
529	20009507	JOHN DIMERE VAGI	M	POREBADA EAST	Student	09-Dec-1993
530	20227660	John Jnr Mea	M	POREBADA EAST	Student	29-Aug-2001
531	20227661	John Miria Mea	M	POREBADA EAST	Worker	20-Jul-1970
532	20072957	John Morea Mea Auda	M	POREBADA EAST	Self Employed	18-Nov-1987
533	20076522	John Morea Mea Igo	M	POREBADA EAST	Self Employed	19-Jun-1986
534	20076518	John Morea Mea Mea	M	POREBADA EAST	Subsistence Farmer	21-Mar-1983
535	20123439	Josiah Gari	M	POREBADA EAST	Subsistence Farmer	27-Oct-1977
536	20076526	Josiah Peni Iruru	M	POREBADA EAST	Store Keeper	28-May-1986
537	20008234	KALAU ANTON	M	POREBADA EAST	Student	01-Jan-1985
538	20090474	Kalula Isidore	M	POREBADA EAST	Subsistence Farmer	27-May-1975
539	20197931	Kapa Ora Kokoro	M	POREBADA EAST	Subsistence Farmer	17-Aug-1996
540	20131331	Kariva Ivan	M	POREBADA EAST	Fisherman	30-Apr-1970
541	20079194	Karo Collin	M	POREBADA EAST	Worker	12-Aug-1963
542	20009562	KARO JOE	M	POREBADA EAST	Unemployed	01-Jan-1981
543	20009567	KAROHO GAU	M	POREBADA EAST	Unemployed	01-Jan-1974
544	20227664	Karoho Gau	M	POREBADA EAST	Unemployed	31-May-2003
545	20087633	Karoho Igo	M	POREBADA EAST	Subsistence Farmer	26-Jun-1981
546	20123442	Karoho William	M	POREBADA EAST	Self Employed	10-Apr-1989
547	20094935	Karoho Morea Gau	M	POREBADA EAST	Self Employed	08-Nov-1980
548	20131131	Karua Agi	M	POREBADA EAST	Student	13-May-1997
549	20125740	Karua Billy	M	POREBADA EAST	Student	15-May-1998
550	20131130	Karua Busina	M	POREBADA EAST	Student	06-Apr-1996
551	20130728	Karua Charlie	M	POREBADA EAST	Unemployed	15-Jul-1982
552	20124166	Karua Goata Peter	M	POREBADA EAST	Worker	03-Jul-1988
553	20009477	KARUA HITOLO	M	POREBADA EAST	Subsistence Farmer	01-Jan-1992
554	20124966	Karua Riu	M	POREBADA EAST	Unemployed	01-Jan-1962
555	20067606	Karua Sisia	M	POREBADA EAST	Self Employed	08-May-1984
556	20092383	Karua Mea Mea	M	POREBADA EAST	Self Employed	27-Jun-1981
557	20092313	Karua Mea Michael	M	POREBADA EAST	Self Employed	06-Jun-1979
558	20092343	Karua Mea Pune	M	POREBADA EAST	Self Employed	15-Aug-1975
559	20092308	Karua Mea Raka	M	POREBADA EAST	Self Employed	16-Feb-1983
560	20227665	Keith Anai John	M	POREBADA EAST	Unemployed	03-May-2003
561	20227667	Kelly Igo	M	POREBADA EAST	Fisherman	18-Nov-1999
562	20227668	Kelly Vagi	M	POREBADA EAST	Fisherman	01-Sep-2000
563	20227669	Keni Koani	M	POREBADA EAST	Fisherman	02-Apr-2002
564	20087384	Keni Merabo	M	POREBADA EAST	Unemployed	08-Oct-1968
565	20083691	Keni Pala	M	POREBADA EAST	Fisherman	12-Jul-1960
566	20083927	Keni Vui	M	POREBADA EAST	Unemployed	26-Sep-1983
567	20227670	Kenny Lahui	M	POREBADA EAST	Fisherman	02-Nov-1998
568	20129889	Kevau Baru	M	POREBADA EAST	Student	05-Sep-1998
569	20227673	Kevau Heau	M	POREBADA EAST	Unemployed	13-Jun-1969
570	20089787	Kevau Hitolo	M	POREBADA EAST	Seaman	12-Aug-1973
571	20123444	KEVAU LOHIA	M	POREBADA EAST	Fisherman	13-Sep-1975
572	20129888	Kevau Pune	M	POREBADA EAST	Student	28-Feb-1997
573	20079027	Kevau Lohia Hitolo	M	POREBADA EAST	Seaman	12-Aug-1973
574	20033836	Kevau Lohia Lohia	M	POREBADA EAST	Self Employed	13-Sep-1975
575	20227674	Kevau Pune Morea	M	POREBADA EAST	Student	21-Feb-2003
576	20068093	Kila David	M	POREBADA EAST	Self Employed	27-Nov-1969
577	20059399	Kila Eli	M	POREBADA EAST	Self Employed	01-Jan-1979
578	20227675	Kila Hakson	M	POREBADA EAST	Security	26-Sep-1975
579	20083564	Kila Hitolo	M	POREBADA EAST	Self Employed	12-Dec-1986
580	20130951	Kila Raka Ina	M	POREBADA EAST	Driver	05-May-1951
581	20004600	KILA KONE KONE CHRIS	M	POREBADA EAST	Self Employed	25-Dec-1991
582	20087437	Koani Ako	M	POREBADA EAST	Self Employed	12-Mar-1977
583	20124169	Koani Buruka Gorogo	M	POREBADA EAST	Unemployed	17-Jan-1986
584	20083637	Koani Dimere	M	POREBADA EAST	Self Employed	22-Dec-1980
585	20085501	Koani Gau	M	POREBADA EAST	Self Employed	01-Jan-1954
586	20062554	Koani Kevau	M	POREBADA EAST	Self Employed	10-Sep-1982
587	20085489	Koani Koita	M	POREBADA EAST	Self Employed	01-Jan-1950
588	20078980	Koani Lohia	M	POREBADA EAST	Self Employed	01-Jan-1965
589	20129883	Koani Miria	M	POREBADA EAST	Fisherman	28-Jun-1992
590	20197935	Koani Morea	M	POREBADA EAST	Fisherman	14-Jun-1998
591	20227680	Koani Morea Banabas	M	POREBADA EAST	Student	16-Oct-2002
592	20129884	Koani Ovia	M	POREBADA EAST	Student	01-Jan-1995
593	20131405	Koani Peter	M	POREBADA EAST	Pastor	25-Sep-1970
594	20131424	Koani Peter	M	POREBADA EAST	Household Duties	21-May-1997
595	20131425	Koani Vai	M	POREBADA EAST	Student	05-Apr-1999
596	20072871	Koani Baru Morea	M	POREBADA EAST	Self Employed	19-Sep-1985
597	20002831	KOANI DIMERE ARERE	M	POREBADA EAST	Worker	15-Jul-1991
598	20083638	Koani Dimere Mea	M	POREBADA EAST	Self Employed	23-Jul-1985
599	20092338	Koani Pune Vagi	M	POREBADA EAST	Self Employed	12-Feb-1971
600	20031433	Koani Riu Lohia	M	POREBADA EAST	Clerk	04-Sep-1966
601	20079032	Koani Riu Peter	M	POREBADA EAST	Pastor	25-Aug-1970
602	20045416	Koani Vagi Vagi	M	POREBADA EAST	Student	04-Aug-1983
603	20090268	Kohu Terry	M	POREBADA EAST	Self Employed	16-May-1988
604	20061838	Koita Bemu Toby	M	POREBADA EAST	Self Employed	01-Jan-1967
605	20072522	Koita Bua	M	POREBADA EAST	Household Duties	01-Jan-1967
606	20123448	Koita Hure	M	POREBADA EAST	Self Employed	01-Jan-1956
607	20076135	Koita Keni	M	POREBADA EAST	Self Employed	01-Jan-1963
608	20123449	Koita Merabo	M	POREBADA EAST	Self Employed	01-Jan-1953
609	20092727	Kokoro Homoka Morea	M	POREBADA EAST	Self Employed	15-May-1979
610	20089775	Kone Kila	M	POREBADA EAST	Electrician	01-Jan-1962
611	20095081	Kopi Asi	M	POREBADA EAST	Self Employed	28-Apr-1970
612	20094557	Kopi Koani	M	POREBADA EAST	Self Employed	01-Jan-1976
613	20125733	Kore Geita	M	POREBADA EAST	Self Employed	12-Mar-1997
614	20131330	Koregai Sandy	M	POREBADA EAST	Fisherman	01-May-1991
615	20079121	Koru Igo Heni	M	POREBADA EAST	Self Employed	01-Jan-1969
616	20076607	Koru Igo Igo	M	POREBADA EAST	Self Employed	14-Feb-1999
617	20076588	Koru Igo Lahui	M	POREBADA EAST	Subsistence Farmer	01-Jan-1981
618	20076591	Koru Igo Siage	M	POREBADA EAST	Self Employed	21-May-1977
619	20123452	Kovae Tarupa	M	POREBADA EAST	Subsistence Farmer	27-Oct-1972
620	20072564	Kovae Gari Kovae	M	POREBADA EAST	Storeman	25-May-1975
621	20031423	Kovae Gari Vele	M	POREBADA EAST	Self Employed	10-Oct-1960
622	20022677	Kovae Keni Kovae	M	POREBADA EAST	Subsistence Farmer	01-Jan-1957
623	20227683	Kovea Tarube	M	POREBADA EAST	Driver	23-Dec-1980
624	20005188	Kwapena Hitolo	M	POREBADA EAST	Unemployed	20-Aug-1991
625	20031898	Kwapena Kwapena	M	POREBADA EAST	Driver	\N
626	20005062	KWAPENA MANU	M	POREBADA EAST	Unemployed	05-Mar-1992
627	20031860	Kwapena Morea	M	POREBADA EAST	Student	25-Feb-1987
628	20094489	Lahui Arua	M	POREBADA EAST	Self Employed	01-Jan-1962
629	20123454	Lahui Gorogo	M	POREBADA EAST	Self Employed	19-Oct-1951
630	20227686	Lahui Igo	M	POREBADA EAST	Fisherman	04-Jan-2003
631	20017846	Lahui Isaiah	M	POREBADA EAST	Student	02-Aug-1992
632	20081129	Lahui Jack	M	POREBADA EAST	Worker	04-Jan-1947
633	20227687	Lahui Jack jnr	M	POREBADA EAST	Student	26-Sep-1997
634	20089779	Lahui Karoho	M	POREBADA EAST	Self Employed	23-Dec-1950
635	20124981	Lahui Morea	M	POREBADA EAST	Fisherman	04-Aug-1960
636	20001427	LAHUI REA	M	POREBADA EAST	Unemployed	11-Nov-1993
637	20227690	Lahui Riu	M	POREBADA EAST	Fisherman	26-Jan-2000
638	20078750	Lahui Tauedea	M	POREBADA EAST	Self Employed	26-Dec-1967
639	20081410	Lahui Toea	M	POREBADA EAST	Self Employed	25-May-1949
640	20005048	LAHUI VELE	M	POREBADA EAST	Student	04-Apr-1993
641	20003346	LAHUI IGO RIU	M	POREBADA EAST	Worker	27-Dec-1977
642	20009521	LAHUI MOMORU BARU	M	POREBADA EAST	Student	17-Aug-1987
643	20009522	LAHUI MOMORU KOANI	M	POREBADA EAST	Student	04-Feb-1989
644	20005119	LANCAN BUSINA NICKY	M	POREBADA EAST	Clerk	23-Mar-1989
645	20227691	Lancan Ian	M	POREBADA EAST	Unemployed	21-Mar-2002
646	20008601	LEAWI JEREMIAH	M	POREBADA EAST	Not Specified	13-May-1983
647	20227692	Leka Sasae	M	POREBADA EAST	Self Employed	11-May-1986
648	20227693	Len Gabe	M	POREBADA EAST	Worker	24-Jun-1994
649	20005049	LIBAE MOREA	M	POREBADA EAST	Worker	01-Jan-1982
650	20124177	Libai Stanley Gregory	M	POREBADA EAST	Worker	14-Jul-1978
651	20124178	Libai Stanley Gregory	M	POREBADA EAST	Worker	29-Dec-1983
652	20083934	Lohia Anikau	M	POREBADA EAST	Clerk	18-Jan-1958
653	20004216	LOHIA DAIRI	M	POREBADA EAST	Fisherman	13-Jul-1989
654	20032996	Lohia Dairi	M	POREBADA EAST	Self Employed	28-Nov-1985
655	20124179	Lohia Dairi Heau	M	POREBADA EAST	Self Employed	12-Jan-1962
656	20124180	Lohia Dairi Vagi	M	POREBADA EAST	Self Employed	17-Feb-1967
657	20069495	Lohia Gari	M	POREBADA EAST	Self Employed	25-Feb-1967
658	20083591	Lohia Gau	M	POREBADA EAST	Electrician	30-Mar-1975
659	20005031	LOHIA GAVERA JNR	M	POREBADA EAST	Unemployed	20-Feb-1993
660	20005160	LOHIA GOROGO	M	POREBADA EAST	Student	01-Jan-1990
661	20078994	Lohia Havata	M	POREBADA EAST	Self Employed	25-Dec-1957
662	20005163	LOHIA HEAU VAGI	M	POREBADA EAST	Worker	01-Jan-1990
663	20123456	LOHIA Hitolo	M	POREBADA EAST	Unemployed	28-Jun-1992
664	20130736	Lohia Homoka	M	POREBADA EAST	Student	27-Aug-1994
665	20076599	Lohia Jack	M	POREBADA EAST	Self Employed	01-Mar-1964
666	20031420	Lohia Koani	M	POREBADA EAST	Student	10-Oct-1987
667	20089756	Lohia Lohia	M	POREBADA EAST	Student	12-Feb-1978
668	20130934	Lohia Lohia	M	POREBADA EAST	Factory Worker	15-Jan-1996
669	20227699	Lohia Lohia	M	POREBADA EAST	Fisherman	08-Apr-2002
670	20131312	Lohia Maba	M	POREBADA EAST	Student	12-Aug-1998
671	20227700	Lohia Morea Billy	M	POREBADA EAST	Student	14-Dec-1995
672	20124181	Lohia Morea Gavera	M	POREBADA EAST	Self Employed	26-Sep-1982
673	20005029	LOHIA RICHARD	M	POREBADA EAST	Unemployed	02-Oct-1990
674	20076616	Lohia Stanly	M	POREBADA EAST	Self Employed	01-Jan-1987
675	20227701	Lohia Toua	M	POREBADA EAST	Unemployed	26-Feb-2004
676	20131108	Lohia Vaburi	M	POREBADA EAST	Fisherman	05-Feb-1997
677	20125715	Lohia Vaburi Anikau	M	POREBADA EAST	Not Specified	18-Jan-1959
678	20125716	Lohia Vagi	M	POREBADA EAST	Worker	13-Dec-1978
679	20124182	Lohia Varuko Hitolo	M	POREBADA EAST	Driver	28-Apr-1968
680	20124183	Lohia Varuko Igo Isaiah	M	POREBADA EAST	Driver	23-Oct-1963
681	20005185	LOHIA ARUA TAUEDEA	M	POREBADA EAST	Student	11-Sep-1992
682	20090263	Lohia Dairi Isaiah	M	POREBADA EAST	Driver	17-Apr-1969
683	20069652	Lohia Gari Gorogo	M	POREBADA EAST	Self Employed	07-Jan-1980
684	20006531	LOHIA GOATA GOATA	M	POREBADA EAST	Fisherman	06-Oct-1991
685	20227702	Lohia Goata Koani	M	POREBADA EAST	Worker	21-Mar-1999
686	20051338	Lohia Heagi Seri	M	POREBADA EAST	Self Employed	26-Aug-1978
687	20227705	Lohia Hitolo Hitolo	M	POREBADA EAST	Fisherman	01-Apr-1979
688	20227706	Lohia Hitolo Pune	M	POREBADA EAST	Fisherman	28-Jan-1995
689	20227707	Lohia Hitolo Teta	M	POREBADA EAST	Fisherman	27-Jul-2001
690	20227709	Lohia Lohia Morea	M	POREBADA EAST	Fisherman	26-Aug-2002
691	20005525	LOHIA MOREA GOROGO	M	POREBADA EAST	Student	25-Aug-1990
692	20083607	Lohia Morea Vaburi	M	POREBADA EAST	Self Employed	15-May-1981
693	20064551	Lohia Oda Hutuma	M	POREBADA EAST	Subsistence Farmer	01-Jan-1985
694	20050573	Lohia Sioni Raka	M	POREBADA EAST	Store Keeper	01-Jan-1963
695	20045625	Lohia Sioni Simon	M	POREBADA EAST	Self Employed	23-Apr-1952
696	20227710	Lohia Tara Hitolo	M	POREBADA EAST	Teacher	26-Feb-1997
697	20227711	Lohia Tara Willie	M	POREBADA EAST	Student	11-May-2003
698	20035520	Lohia Varuko Gaudi	M	POREBADA EAST	Self Employed	14-Feb-1972
699	20068081	Lohia Varuko Momoru	M	POREBADA EAST	Self Employed	30-Apr-1976
700	20050660	Lohia Varuko Morea Gau	M	POREBADA EAST	Worker	18-Oct-1956
701	20079180	Lohia Vasiri Gavera	M	POREBADA EAST	Self Employed	30-Jul-1975
702	20123459	LOULAI JOHN	M	POREBADA EAST	Unemployed	16-Feb-1993
703	20123461	LOULAI LOHIA	M	POREBADA EAST	Unemployed	07-Jun-1993
704	20227713	Lovana Scorh	M	POREBADA EAST	Worker	14-Jul-1994
705	20005022	MABA GARI	M	POREBADA EAST	Unemployed	09-Apr-1993
706	20085483	Maba Koani	M	POREBADA EAST	Fisherman	01-Dec-1975
707	20083669	Maba Kovae	M	POREBADA EAST	Unemployed	01-Jan-1980
708	20079196	Maba Lohia Morea	M	POREBADA EAST	Self Employed	01-Jan-1930
709	20083677	Maba Morea	M	POREBADA EAST	Fisherman	23-May-1972
710	20085512	Maba Riu	M	POREBADA EAST	Self Employed	23-Oct-1966
711	20056546	Madi Haraka	M	POREBADA EAST	Subsistence Farmer	08-Aug-1978
712	20003600	MAGARI MORRIS	M	POREBADA EAST	Consultant	20-Jul-1966
713	20061828	Mahuta Joe Vaburi	M	POREBADA EAST	Self Employed	29-Oct-1982
714	20227714	Mahuta Mahuta	M	POREBADA EAST	Student	03-Jan-2002
715	20227715	Mahuta Moses	M	POREBADA EAST	Student	12-Feb-2004
716	20059055	Mahuta Nanai	M	POREBADA EAST	Clerk	06-May-1977
717	20227716	Mahuta Stanley	M	POREBADA EAST	Unemployed	09-Sep-2002
718	20067880	Maima Busina	M	POREBADA EAST	Self Employed	28-Feb-1987
719	20130975	Maima Heni	M	POREBADA EAST	Not Specified	12-Sep-1996
720	20009429	MAIMI LAHUI PAUL	M	POREBADA EAST	Journalist	10-Aug-1952
721	20003347	MAITA ATARA IAGETI	M	POREBADA EAST	Worker	01-Jan-1945
722	20069658	Malu Rocky	M	POREBADA EAST	Self Employed	14-Jun-1956
723	20124869	Mananua Leslie	M	POREBADA EAST	Worker	21-Aug-1977
724	20009251	MANDUI LUCAS	M	POREBADA EAST	Worker	01-Jan-1981
725	20050670	Martin Gable	M	POREBADA EAST	Self Employed	24-Oct-1972
726	20067982	Mataio Bluey Helai	M	POREBADA EAST	Self Employed	13-Jun-1962
727	20125791	Mataio Gau	M	POREBADA EAST	Not Specified	22-Oct-1997
728	20005576	MATAIO STEVEN	M	POREBADA EAST	Student	29-Apr-1991
729	20131143	Mataio Steven	M	POREBADA EAST	Household Duties	11-Oct-1994
730	20123463	Mataio Tauedea Timoti	M	POREBADA EAST	Self Employed	06-Oct-1958
731	20033466	Mataio Morea Vele	M	POREBADA EAST	Self Employed	01-Jan-1984
732	20124184	Mauri Igo Vaburi	M	POREBADA EAST	Self Employed	21-May-1960
733	20081400	Mauri Igo Gau	M	POREBADA EAST	Self Employed	06-Oct-1962
734	20124186	Mea Arua Morea	M	POREBADA EAST	Unemployed	14-Jun-1989
736	20227722	Mea Billy Busina	M	POREBADA EAST	Fisherman	02-Nov-2002
737	20008249	MEA BUSINA	M	POREBADA EAST	Worker	01-Jan-1978
738	20008955	MEA DOURA	M	POREBADA EAST	Worker	01-Jan-1989
739	20008717	MEA GUBA	M	POREBADA EAST	Fireman	19-Sep-1968
740	20008247	MEA IGO	M	POREBADA EAST	Unemployed	01-Jan-1986
741	20124968	Mea Lohia	M	POREBADA EAST	Student	22-Jan-1998
742	20092351	Mea Lohia Karua	M	POREBADA EAST	Self Employed	07-Apr-1952
743	20131366	Mea Mea	M	POREBADA EAST	Household Duties	27-Aug-1993
744	20008248	MEA MEA JOHN	M	POREBADA EAST	Worker	01-Jan-1982
745	20008245	MEA MEA MOREA	M	POREBADA EAST	Worker	01-Jan-1967
746	20008957	MEA MOREA	M	POREBADA EAST	Worker	01-Jan-1992
747	20081556	Mea Paul	M	POREBADA EAST	Accountant	01-Jan-1982
748	20124187	Mea Pune Davis	M	POREBADA EAST	Self Employed	23-Jul-1987
749	20227727	Mea Toua	M	POREBADA EAST	Student	13-Jan-2001
750	20094437	Mea Vagi	M	POREBADA EAST	Fisherman	25-Jun-1977
751	20008958	MEA VICTOR	M	POREBADA EAST	Unemployed	01-Jan-1979
752	20005131	MEA AUANI VABURI	M	POREBADA EAST	Worker	07-Feb-1989
753	20090430	Mea Busina Kristofer	M	POREBADA EAST	Student	04-Mar-1984
754	20227728	Mea G Morea	M	POREBADA EAST	Fisherman	03-Sep-2001
755	20072954	Mea Gari Morea	M	POREBADA EAST	Self Employed	01-Jan-1971
756	20067900	Mea Gari K Toua	M	POREBADA EAST	Self Employed	01-Jan-1969
757	20227729	Mea Gau Hitolo	M	POREBADA EAST	Fisherman	29-Sep-2000
758	20227730	Mea Gau Pilu	M	POREBADA EAST	Fisherman	02-Apr-1994
759	20227731	Mea Gau Willie	M	POREBADA EAST	Fisherman	12-Apr-1996
760	20227732	Mea Goata Raka	M	POREBADA EAST	Student	31-May-2002
761	20004219	MEA PUNE TABE	M	POREBADA EAST	Self Employed	20-May-1970
762	20227733	Mea Taumaku Havata	M	POREBADA EAST	Fisherman	21-Oct-1997
763	20123466	MERABO ADRIAN	M	POREBADA EAST	Student	10-Jun-1994
764	20072932	Merabo Anai	M	POREBADA EAST	Self Employed	29-Jan-1975
765	20072519	Merabo Iga	M	POREBADA EAST	Self Employed	01-Jan-1980
766	20123465	Merabo Koita	M	POREBADA EAST	Self Employed	01-Jan-1987
767	20003424	MERABO LOHIA	M	POREBADA EAST	Fisherman	06-Jul-1989
768	20123467	MERABO MEA	M	POREBADA EAST	Teacher	22-Sep-1989
769	20072928	Merabo Morea	M	POREBADA EAST	Self Employed	01-Jan-1975
770	20072528	Merabo Tolo	M	POREBADA EAST	Self Employed	01-Jan-1976
771	20072931	Merabo Vagi	M	POREBADA EAST	Self Employed	01-Jan-1971
772	20003641	MERABO KOITA GIA	M	POREBADA EAST	Fisherman	15-Nov-1990
773	20083692	Miria James Mea	M	POREBADA EAST	Salesman	19-Jul-1976
774	20123470	Miria John	M	POREBADA EAST	Self Employed	04-Dec-1943
775	20007751	MISIKARAM KEVAN	M	POREBADA EAST	Unemployed	01-Jan-1987
776	20005607	MISIKARAM LOHIA	M	POREBADA EAST	Unemployed	01-Jan-1982
777	20005608	MISIKARAM MODE	M	POREBADA EAST	Unemployed	01-Jan-1960
778	20007461	MISIKARAM NGUNIA JR	M	POREBADA EAST	Unemployed	01-Jan-1993
779	20007745	MISIKARAM RONNIE	M	POREBADA EAST	Unemployed	01-Jan-1981
780	20005579	MISIKARAM SAMSON	M	POREBADA EAST	Unemployed	01-Jan-1990
781	20007747	MISIKARAM VASIRI	M	POREBADA EAST	Unemployed	01-Jan-1983
782	20009434	MOALE KOITA RAVAO	M	POREBADA EAST	Fisherman	01-Jan-1991
783	20009571	MOALE KOITA VAGI	M	POREBADA EAST	Fisherman	01-Jan-1989
784	20092359	Moeka Barry	M	POREBADA EAST	Self Employed	31-Dec-1974
785	20131144	Moeka Pune	M	POREBADA EAST	Fisherman	02-Feb-1996
786	20090425	Moi Gau	M	POREBADA EAST	Self Employed	09-Apr-1980
787	20089835	Moi Lahui	M	POREBADA EAST	Self Employed	27-Feb-1987
788	20058874	Momoru Hitolo	M	POREBADA EAST	Subsistence Farmer	20-Sep-1968
789	20094521	Momoru Lahui	M	POREBADA EAST	Teacher	05-Jun-1954
790	20076573	Momoru Tarupa	M	POREBADA EAST	Self Employed	06-Aug-1954
791	20062482	Momoru Varuko	M	POREBADA EAST	Self Employed	23-Jul-1987
792	20227738	More Vagi	M	POREBADA EAST	Fisherman	25-Aug-2000
793	20076559	Morea Arere Peter	M	POREBADA EAST	Teacher	01-Jan-1977
794	20227739	Morea Arua	M	POREBADA EAST	Student	02-Apr-2002
795	20124192	Morea Arua Gau	M	POREBADA EAST	Student	04-Dec-1984
796	20069561	Morea Audabi	M	POREBADA EAST	Worker	16-Dec-1957
797	20064582	Morea Bemu	M	POREBADA EAST	Self Employed	26-Feb-1971
798	20092302	Morea Dairi Romeo	M	POREBADA EAST	Subsistence Farmer	02-Dec-1982
799	20123472	Morea David	M	POREBADA EAST	Self Employed	24-Nov-1949
800	20227740	Morea David	M	POREBADA EAST	Fisherman	01-Aug-2000
801	20072934	Morea Doura	M	POREBADA EAST	Self Employed	05-May-1959
802	20092624	Morea Eguta	M	POREBADA EAST	Household Duties	12-Mar-1980
803	20124196	Morea Eguta Igo	M	POREBADA EAST	Manager	29-Sep-1973
804	20083933	Morea Gau	M	POREBADA EAST	Self Employed	08-Aug-1968
805	20123473	Morea Gau Vaburi	M	POREBADA EAST	Self Employed	24-Dec-1955
806	20123474	Morea Goata	M	POREBADA EAST	Self Employed	13-Jun-1956
807	20130914	Morea Goata Homoka	M	POREBADA EAST	Worker	13-May-1969
808	20076576	Morea Gogo	M	POREBADA EAST	Self Employed	01-Jan-1978
809	20090271	Morea Harold	M	POREBADA EAST	Student	24-Apr-1989
810	20227743	Morea Heagi Herman	M	POREBADA EAST	Fisherman	01-Jan-1980
811	20076476	Morea Heau	M	POREBADA EAST	Pastor	29-Dec-1972
812	20123476	Morea Hesede	M	POREBADA EAST	Accountant	19-Jan-1980
813	20023231	Morea Igo	M	POREBADA EAST	Subsistence Farmer	18-Mar-1974
814	20227744	Morea Igo	M	POREBADA EAST	Fisherman	06-Dec-2001
815	20076733	Morea Isaiah	M	POREBADA EAST	Self Employed	01-Jan-1973
816	20131292	Morea Isaiah	M	POREBADA EAST	Fisherman	12-Feb-1996
817	20227745	Morea Isaiah	M	POREBADA EAST	Fisherman	01-Jan-1997
818	20130990	Morea Karua	M	POREBADA EAST	Not Specified	26-Mar-1997
819	20085477	Morea Koani	M	POREBADA EAST	Unemployed	01-Jan-1976
820	20030949	Morea Lohia	M	POREBADA EAST	Self Employed	01-Mar-1978
821	20125796	Morea Lohia	M	POREBADA EAST	Pastor	03-Oct-1959
822	20227747	Morea Loulai	M	POREBADA EAST	Not Specified	04-Oct-2000
823	20124846	Morea Maba	M	POREBADA EAST	Fisherman	02-Jan-1995
824	20123477	Morea Maraga	M	POREBADA EAST	Security	10-Mar-1993
825	20123478	Morea Mataio Helai	M	POREBADA EAST	Fitter Machinist	06-Aug-1962
826	20130744	Morea Morea	M	POREBADA EAST	Household Duties	01-Jan-1998
827	20008262	MOREA MOREA RIU	M	POREBADA EAST	Not Specified	01-Jan-1985
828	20069653	Morea Morgan Morea	M	POREBADA EAST	Self Employed	04-Apr-1974
829	20067460	Morea Morris	M	POREBADA EAST	Self Employed	07-May-1952
830	20123479	Morea Oda	M	POREBADA EAST	Subsistence Farmer	27-Jul-1976
831	20124202	Morea Oda Arua	M	POREBADA EAST	Fisherman	11-Dec-1987
832	20092374	Morea Pala	M	POREBADA EAST	Technician	06-Nov-1969
833	20131137	Morea Pautani	M	POREBADA EAST	Driver	01-Jan-1972
834	20007464	MOREA PUNE LOHIA	M	POREBADA EAST	Worker	01-Jan-1972
835	20123484	MOREA REV MOREA	M	POREBADA EAST	Pastor	08-Mar-1954
836	20078751	Morea Riu	M	POREBADA EAST	Self Employed	08-Nov-1979
837	20092310	Morea Seri  Jnr	M	POREBADA EAST	Self Employed	07-Mar-1978
838	20083730	Morea Seri  Snr	M	POREBADA EAST	Unemployed	10-Apr-1958
839	20131363	Morea Taumaku	M	POREBADA EAST	Student	09-Apr-1997
840	20081370	Morea Vagi	M	POREBADA EAST	Self Employed	30-Nov-1979
841	20123482	Morea Varuko	M	POREBADA EAST	Fisherman	02-Feb-1976
842	20125781	Morea Varuko	M	POREBADA EAST	Fisherman	02-Feb-1965
843	20131134	Morea Veri	M	POREBADA EAST	Self Employed	22-Jun-1994
844	20227749	Morea Vincent	M	POREBADA EAST	Student	21-May-2002
845	20094496	Morea  Arua Dairi	M	POREBADA EAST	Self Employed	08-Feb-1950
846	20079120	Morea  Lahui Lahui	M	POREBADA EAST	Self Employed	13-Oct-1985
847	20089847	Morea  Vagi Igo	M	POREBADA EAST	Inspector	02-Jul-1980
848	20007770	MOREA AIASOA WAYNE	M	POREBADA EAST	Worker	26-Nov-1975
849	20030942	Morea Arua Arua	M	POREBADA EAST	Student	14-Dec-1988
850	20032992	Morea Auani Auani	M	POREBADA EAST	Self Employed	20-Jun-1976
851	20069276	Morea Baru Guba	M	POREBADA EAST	Self Employed	01-Jan-1970
852	20003958	MOREA BRIAN MEA	M	POREBADA EAST	Worker	08-Oct-1968
853	20227751	Morea Busina Arua	M	POREBADA EAST	Unemployed	22-Aug-1995
854	20227752	Morea Busina Gorogo	M	POREBADA EAST	Student	06-Sep-2002
855	20227753	Morea Daera Pune	M	POREBADA EAST	Student	16-Jun-2003
856	20083668	Morea Gorogo Lohia	M	POREBADA EAST	Self Employed	25-Jul-1952
857	20033568	Morea Heau Hitolo	M	POREBADA EAST	Self Employed	23-Feb-1975
858	20034381	Morea Heau Toea	M	POREBADA EAST	Self Employed	02-Jul-1958
859	20033581	Morea Heau Varuko	M	POREBADA EAST	Self Employed	01-Jan-1968
860	20083563	Morea Helai Helai	M	POREBADA EAST	Teacher	18-Mar-1964
861	20227755	Morea Hitolo Camilo	M	POREBADA EAST	Student	28-Apr-2004
862	20003618	MOREA I HELAI	M	POREBADA EAST	Self Employed	23-Nov-1987
863	20076533	Morea Igo Dairi	M	POREBADA EAST	Plumber	28-Aug-1959
864	20004629	MOREA IGO PAUTANI	M	POREBADA EAST	Fisherman	13-Oct-1973
865	20079049	Morea Igo Raka	M	POREBADA EAST	Self Employed	01-Jan-1980
866	20079030	Morea Igo Vaburi	M	POREBADA EAST	Self Employed	21-May-1962
867	20083552	Morea Isaiah Helai	M	POREBADA EAST	Self Employed	23-Nov-1987
868	20083578	Morea Isaiah Momoru	M	POREBADA EAST	Student	01-Jan-1984
869	20227756	Morea Jnr Goata	M	POREBADA EAST	Unemployed	12-Mar-1982
870	20092379	Morea Koitabu Taumaku	M	POREBADA EAST	Self Employed	05-Oct-1973
871	20079128	Morea Lahui Tauedea	M	POREBADA EAST	Self Employed	11-Nov-1987
872	20050662	Morea Lohia Varuko	M	POREBADA EAST	Fisherman	07-Jan-1979
873	20034141	Morea Morea Gau	M	POREBADA EAST	Self Employed	27-Nov-1997
874	20072894	Morea Oda Tauedea	M	POREBADA EAST	Subsistence Farmer	08-Aug-1983
875	20054285	Morea Pako Gau	M	POREBADA EAST	Worker	13-Jun-1972
876	20008975	MOREA PAUTANI ARUA	M	POREBADA EAST	Unemployed	22-Mar-1990
877	20059226	Morea Riu Lahui	M	POREBADA EAST	Self Employed	01-Jan-1977
878	20092619	Morea Riu Lohia	M	POREBADA EAST	Subsistence Farmer	01-Jan-1974
879	20227757	Morea Seri Seri	M	POREBADA EAST	Fisherman	08-Sep-2003
880	20069651	Morea Tau Baru	M	POREBADA EAST	Self Employed	13-Dec-1980
881	20069657	Morea Tau Tauedea	M	POREBADA EAST	Teacher	20-Aug-1970
882	20064737	Morea Tauedea Baru	M	POREBADA EAST	Self Employed	13-Dec-1978
883	20090462	Morea Taumaku Koitabu Baru	M	POREBADA EAST	Self Employed	26-Sep-1981
884	20069563	Morea Toea Gari	M	POREBADA EAST	Self Employed	27-Jan-1965
885	20083507	Morea Vagi Billy	M	POREBADA EAST	Self Employed	19-Oct-1986
886	20031982	Morea Vagi Vagi	M	POREBADA EAST	Self Employed	30-Nov-1980
887	20227758	Morgan Heau	M	POREBADA EAST	Security	21-May-1999
888	20079034	Morris Tara	M	POREBADA EAST	Self Employed	24-Apr-1975
889	20124927	Moses Busina	M	POREBADA EAST	Not Specified	18-Jan-1997
890	20004240	MOSES T BONTY BOIO	M	POREBADA EAST	Unemployed	10-Aug-1990
891	20067961	Neises Gorogo	M	POREBADA EAST	Self Employed	14-Jun-1987
892	20008259	NEISIS IGO	M	POREBADA EAST	Not Specified	16-Aug-1993
893	20125729	Nelson Tom	M	POREBADA EAST	Self Employed	01-Jan-1993
894	20092605	Nohokau Auani	M	POREBADA EAST	Security	01-Jan-1973
895	20078734	Oda Ahuta	M	POREBADA EAST	Pastor	08-Jun-1960
896	20064580	Oda Arua	M	POREBADA EAST	Self Employed	31-Jul-1988
897	20064625	Oda Gavera	M	POREBADA EAST	Self Employed	13-Sep-1986
898	20124208	Oda Gorogo Tauedea	M	POREBADA EAST	Subsistence Farmer	11-Oct-1989
899	20227761	Oda Gure	M	POREBADA EAST	Worker	30-Jul-1992
900	20001478	ODA REA	M	POREBADA EAST	Subsistence Farmer	16-Apr-1990
901	20003896	ODA REA	M	POREBADA EAST	Unemployed	16-Apr-1990
902	20008988	ODA TAUEDEA MOREA	M	POREBADA EAST	Not Specified	01-Jan-1983
903	20092712	Oda Heau Ai	M	POREBADA EAST	Subsistence Farmer	13-Aug-1988
904	20005138	ODA HEAU EDDIE	M	POREBADA EAST	Worker	14-Jun-1993
905	20031936	Ovia Simon Koani	M	POREBADA EAST	Self Employed	01-Jan-1960
906	20084076	Pako Peter	M	POREBADA EAST	Driver	01-May-1968
907	20036804	Pako Peter Gau	M	POREBADA EAST	Self Employed	01-Jan-1976
908	20083725	Pako Peter Morea	M	POREBADA EAST	Self Employed	21-Aug-1978
909	20004602	PALA BEN	M	POREBADA EAST	Teacher	12-Jul-1985
910	20227763	Pala Morea	M	POREBADA EAST	Fisherman	01-May-1997
911	20123502	PALA VALI	M	POREBADA EAST	Clerk	26-Oct-1990
912	20227764	Paleu Charles	M	POREBADA EAST	Doctor	04-Nov-1974
913	20227765	Palme Emmanuel	M	POREBADA EAST	Self Employed	21-Jun-1981
914	20090331	Pautani Arua	M	POREBADA EAST	Subsistence Farmer	06-Dec-1968
915	20008334	PAUTANI ARUA MOREA	M	POREBADA EAST	Worker	01-Jan-1990
916	20023653	Pautani Gau Morea	M	POREBADA EAST	Subsistence Farmer	20-Dec-1988
917	20023651	Pautani Igo	M	POREBADA EAST	Clerk	05-Oct-1944
918	20123505	Pautani Lahui	M	POREBADA EAST	Self Employed	02-Apr-1965
919	20004165	PERRY SIWI	M	POREBADA EAST	Self Employed	28-Oct-1986
920	20023646	Peter Arere	M	POREBADA EAST	Teacher	26-Oct-1974
921	20197944	Peter Edward	M	POREBADA EAST	Subsistence Farmer	16-Jan-1998
922	20023650	Peter Gau Oala	M	POREBADA EAST	Self Employed	15-Oct-1953
923	20008255	PETER GOATA	M	POREBADA EAST	Worker	01-Jan-1992
924	20124209	Peter Goata Lohia	M	POREBADA EAST	Self Employed	14-Oct-1951
925	20131426	Peter James	M	POREBADA EAST	Worker	26-May-1995
926	20002936	PETER LOHIA	M	POREBADA EAST	Student	23-May-1991
927	20076541	Peter Morea	M	POREBADA EAST	Teacher	01-Jan-1948
928	20131406	Peter Morea	M	POREBADA EAST	Fisherman	09-Oct-1992
929	9920130617	Peter Morea	M	POREBADA EAST	Worker	30-Sep-1998
930	20076452	Peter Rakatani	M	POREBADA EAST	Self Employed	06-May-1949
931	20124967	Peter Sam	M	POREBADA EAST	Student	31-Mar-1996
932	20197954	Peter Sam	M	POREBADA EAST	Student	31-Mar-1996
933	20131125	Peter Vaburi	M	POREBADA EAST	Household Duties	10-Feb-1996
934	20072953	Peter Busina Isaiah	M	POREBADA EAST	Self Employed	16-Dec-1970
935	20007263	PETER GAU MOREA	M	POREBADA EAST	Unemployed	03-Feb-1976
936	20031400	Peter Goata Goata	M	POREBADA EAST	Electrician	23-Oct-1973
937	20033464	Peter Goata Vaburi	M	POREBADA EAST	Self Employed	10-Mar-1979
938	20072976	Peter Vagi Igo	M	POREBADA EAST	Student	23-Nov-1988
939	20075997	Peter Vagi Manu	M	POREBADA EAST	Subsistence Farmer	03-Feb-1985
940	20130624	Petroff Arere	M	POREBADA EAST	Fisherman	13-Sep-1995
941	20124924	Petroff George	M	POREBADA EAST	Worker	09-Mar-1994
942	20227773	Phil Bernard	M	POREBADA EAST	Worker	01-Jan-1985
943	20061840	Pilu Ilimo	M	POREBADA EAST	Self Employed	04-Sep-1980
944	20131152	Pilu Rakatani	M	POREBADA EAST	Fisherman	20-Aug-1990
945	20123361	Pochelep Tapi	M	POREBADA EAST	Not Specified	10-Dec-1960
946	20227775	Pondrous Toua	M	POREBADA EAST	Fisherman	30-Mar-1996
947	20089856	Pune Aeari	M	POREBADA EAST	Subsistence Farmer	30-Apr-1981
948	20131392	Pune Aniko	M	POREBADA EAST	Fisherman	10-Sep-1994
949	20075990	Pune Busina	M	POREBADA EAST	Worker	24-Jun-1967
950	20123508	PUNE DIMERE	M	POREBADA EAST	Self Employed	03-Sep-1992
951	20124211	Pune Dimere Riu	M	POREBADA EAST	Worker	04-Oct-1982
952	20123506	Pune Gau	M	POREBADA EAST	Driver	09-Sep-1981
953	20094425	Pune Havata	M	POREBADA EAST	Gardener	13-Apr-1938
954	20094438	Pune Heagi	M	POREBADA EAST	Self Employed	01-Jan-1982
955	20089857	Pune Kevau	M	POREBADA EAST	Teacher	26-Jun-1974
956	20092356	Pune Lohia	M	POREBADA EAST	Financial Officer	13-Mar-1973
957	20008736	PUNE RIU	M	POREBADA EAST	Unemployed	28-Feb-1972
958	20123507	Pune Riu	M	POREBADA EAST	Driver	04-Oct-1984
959	20008254	PUNE VAGI MAC	M	POREBADA EAST	Welder	03-Apr-1979
960	20130953	Raka Fifaea	M	POREBADA EAST	Fisherman	11-Nov-1996
961	20124212	Rakatani Auani Arua	M	POREBADA EAST	Self Employed	24-Apr-1981
962	20078729	Rakatani Goata	M	POREBADA EAST	Self Employed	15-Nov-1984
963	20130925	Rakatani Gure	M	POREBADA EAST	Household Duties	24-Nov-1993
964	20078735	Rakatani Heau	M	POREBADA EAST	Self Employed	28-Apr-1976
965	20085749	Rakatani Kevau	M	POREBADA EAST	Self Employed	01-Jun-1969
966	20124970	Rakatani Lohia Peter	M	POREBADA EAST	Household Duties	04-Apr-1998
967	20083705	Rakatani Seba	M	POREBADA EAST	Self Employed	10-May-1977
968	20090421	Rakatani Arua Gau	M	POREBADA EAST	Self Employed	27-Mar-1986
969	20090459	Rakatani Auani Morea	M	POREBADA EAST	Subsistence Farmer	20-Apr-1983
970	20075999	Rakatani Peter Lohia	M	POREBADA EAST	Self Employed	08-Dec-1979
971	20094405	Rakatani Peter Morea	M	POREBADA EAST	Self Employed	01-Jan-1987
972	20094581	Rakatani Peter Peter	M	POREBADA EAST	Teacher	16-Nov-1972
973	20197953	Raphael Allan	M	POREBADA EAST	Worker	23-Sep-1989
974	20081591	Ray Ivai	M	POREBADA EAST	Welder	11-Dec-1961
975	20089848	Ray Joseph	M	POREBADA EAST	Student	01-Jan-1978
976	20076583	Rea Gau	M	POREBADA EAST	Self Employed	24-Jun-1974
977	20197928	REA Gau Morea	M	POREBADA EAST	Fisherman	20-Mar-1998
978	20005511	REI MOREA ASI	M	POREBADA EAST	Worker	01-Jan-1982
979	20009169	REI RAKA ASI	M	POREBADA EAST	Student	11-Feb-1993
980	20005178	REI SIBO	M	POREBADA EAST	Unemployed	01-Jan-1978
981	20056513	Riu Busina	M	POREBADA EAST	Self Employed	16-Dec-1975
982	20124216	Riu Busina Koani	M	POREBADA EAST	Fisherman	12-Oct-1981
983	20124217	Riu Busina Sioni	M	POREBADA EAST	Fisherman	05-Jan-1979
984	20227783	Riu Chris	M	POREBADA EAST	Fisherman	19-Sep-2002
985	20056514	Riu Karua	M	POREBADA EAST	Self Employed	04-Apr-1976
986	20087438	Riu Lahui	M	POREBADA EAST	Self Employed	16-Dec-1976
987	20008244	RIU LOHIA	M	POREBADA EAST	Unemployed	26-Jan-1992
988	20008968	RIU MOREA ARUA	M	POREBADA EAST	Unemployed	01-Jan-1969
989	20008956	RIU TAU	M	POREBADA EAST	Unemployed	01-Jan-1990
990	20197933	Riu Taumaku	M	POREBADA EAST	Student	22-Feb-2000
991	20062481	Riu Gau Hitolo	M	POREBADA EAST	Teacher	13-Oct-1971
992	20036013	Riu Gau Maba	M	POREBADA EAST	Self Employed	01-Jan-1973
993	20062424	Riu Gau Peter	M	POREBADA EAST	Self Employed	22-Sep-1974
994	20067885	Riu Gorogo Arua	M	POREBADA EAST	Self Employed	23-Aug-1956
995	20051157	Riu Gorogo Gorogo	M	POREBADA EAST	Self Employed	28-Jan-1948
996	20087407	Riu Heagi Morea	M	POREBADA EAST	Self Employed	15-Feb-1937
997	20007595	RIU MOREA MABA	M	POREBADA EAST	Carpenter	01-Jan-1988
998	20032177	Riu Morea Maba	M	POREBADA EAST	Worker	10-Dec-1987
999	20007750	RIU MOREA MOREA	M	POREBADA EAST	Unemployed	01-Jan-1991
1000	20131434	Rodney Charlie	M	POREBADA EAST	Student	01-Jan-1998
1001	20051174	Rupa Ray	M	POREBADA EAST	Worker	01-Jan-1953
1002	20092349	Saini Andrew	M	POREBADA EAST	Fisherman	15-Aug-1979
1003	20227788	Sam Kelly	M	POREBADA EAST	Fisherman	06-May-2002
1004	20227789	Sam Kila	M	POREBADA EAST	Worker	30-Nov-1990
1005	20004203	SAM DUAHI MOREA	M	POREBADA EAST	Worker	16-Oct-1984
1006	20025756	Sama Karua Karua	M	POREBADA EAST	Subsistence Farmer	23-Jun-1977
1007	20123490	Samduahi TOM	M	POREBADA EAST	Worker	25-Jan-1988
1008	20227790	Seba Rakatani	M	POREBADA EAST	Fisherman	22-Aug-1999
1009	20227791	Seba Vele	M	POREBADA EAST	Fisherman	01-Sep-2001
1010	20079163	Sebastian  Natera Raka	M	POREBADA EAST	Self Employed	24-Apr-1976
1011	20079037	Sebastian Natera Joe	M	POREBADA EAST	Self Employed	10-Dec-1988
1012	20081508	Sebastian Natera John	M	POREBADA EAST	Self Employed	08-Dec-1978
1013	20090403	Seri Arua	M	POREBADA EAST	Self Employed	01-Jan-1966
1014	20004155	SERI BILLY	M	POREBADA EAST	Student	31-Dec-1991
1015	20227794	Seri Koani	M	POREBADA EAST	Student	17-Dec-1995
1016	20003876	SERI MICHAEL	M	POREBADA EAST	Fisherman	17-Oct-1990
1017	20083616	Seri Morea	M	POREBADA EAST	Fisherman	02-May-1980
1018	20090348	Seri Sioni	M	POREBADA EAST	Subsistence Farmer	11-Sep-1978
1019	20094549	Seri Asi Gau	M	POREBADA EAST	Student	18-Oct-1987
1020	20087684	Seri Koani Koani	M	POREBADA EAST	Student	10-Nov-1986
1021	20005021	SERI MOREA MOREA	M	POREBADA EAST	Student	03-Sep-1992
1022	20008733	SIAGE ARUA HITOLO	M	POREBADA EAST	Carpenter	18-Jan-1988
1023	20009172	SIAGE GAU HENI	M	POREBADA EAST	Security	21-Apr-1972
1024	20123493	SIAGE GAU HITOLO	M	POREBADA EAST	Worker	14-Aug-1982
1025	20009393	SIAGE IGO HENI	M	POREBADA EAST	Driver	06-Apr-1965
1026	20009171	SIAGE MARAGA HENI	M	POREBADA EAST	Worker	21-Nov-1968
1027	20123494	SIAGE SIAGE HITOLO	M	POREBADA EAST	Driver	21-Jun-1991
1028	20083551	Siala Boe	M	POREBADA EAST	Self Employed	26-May-1954
1029	20227795	Sibona Barry	M	POREBADA EAST	Student	21-Jul-2003
1030	20130916	Simon Gaba	M	POREBADA EAST	Fisherman	21-May-1994
1031	20002829	SIMON GOROGO	M	POREBADA EAST	Student	06-Mar-1991
1032	20227796	Simon Isaiah	M	POREBADA EAST	Fisherman	24-Oct-1997
1033	20090257	Simon Junior	M	POREBADA EAST	Subsistence Farmer	24-Dec-1985
1034	20227797	Simon Koani	M	POREBADA EAST	Student	19-Nov-2002
1035	20131430	Simon Morea	M	POREBADA EAST	Worker	26-Sep-1979
1036	20047571	Simon Nou	M	POREBADA EAST	Self Employed	20-Mar-1985
1037	20045642	Simon Puka	M	POREBADA EAST	Self Employed	01-Jul-1982
1038	20129893	Simon Pune	M	POREBADA EAST	Student	27-Aug-1994
1039	20130917	Simon Sioni	M	POREBADA EAST	Fisherman	21-Jun-1997
1040	20033608	Simon Heni Arua	M	POREBADA EAST	Subsistence Farmer	04-Apr-1980
1041	20033046	Simon Heni Hitolo	M	POREBADA EAST	Security	14-Dec-1975
1042	20032466	Simon Heni Nao	M	POREBADA EAST	Self Employed	05-Nov-1983
1043	20124865	Sioni Carlos	M	POREBADA EAST	Fisherman	14-Mar-1984
1044	20031857	Sioni Gasiana	M	POREBADA EAST	Self Employed	\N
1045	20079119	Sioni Gorogo	M	POREBADA EAST	Subsistence Farmer	18-Jul-1978
1046	20031855	Sioni Joe	M	POREBADA EAST	Not Specified	22-Jun-1986
1047	20004521	SIRO NELSON	M	POREBADA EAST	Contractor	24-Aug-1985
1048	20072887	Sisia Arua	M	POREBADA EAST	Subsistence Farmer	01-Jan-1983
1049	20227802	Sisia Francis	M	POREBADA EAST	Fisherman	15-May-2001
1050	20006524	SISIA NOU	M	POREBADA EAST	Unemployed	01-Jan-1991
1051	20006149	SISIA PAUL	M	POREBADA EAST	Unemployed	01-Jan-1983
1052	20227804	Sisia Tauedea	M	POREBADA EAST	Worker	14-Mar-1985
1053	20227805	Sisia Jnr Heni	M	POREBADA EAST	Student	18-Jan-2003
1054	20003540	SISIA VARUBI DOURA	M	POREBADA EAST	Self Employed	11-Aug-1977
1055	20123496	Soge Arua	M	POREBADA EAST	Self Employed	07-Aug-1964
1056	20033458	Soge Len	M	POREBADA EAST	Clerk	17-May-1969
1057	20007590	SOGE LOHIA ARUA	M	POREBADA EAST	Subsistence Farmer	09-Sep-1991
1058	20087444	Soge Soge	M	POREBADA EAST	Self Employed	01-Jan-1972
1059	20008256	SOGE SOGE ARUA	M	POREBADA EAST	Bricklayer	01-Jul-1988
1060	20076595	Solien Roy	M	POREBADA EAST	Subsistence Farmer	02-May-1968
1061	20059064	Stanley Gregory	M	POREBADA EAST	Self Employed	14-Jul-1978
1062	20227806	Stanley Olive	M	POREBADA EAST	Household Duties	21-Sep-2000
1063	20034380	Stanly Libai Arua	M	POREBADA EAST	Self Employed	29-Dec-1982
1064	20130928	Steven Jason	M	POREBADA EAST	Household Duties	01-Jan-1998
1065	20227808	Steven Seri	M	POREBADA EAST	Student	04-Jun-2001
1066	20009481	STURGESS LOHIA BEN	M	POREBADA EAST	Driver	10-May-1964
1067	20227809	Suckling Dilu	M	POREBADA EAST	Student	24-May-1998
1068	20123510	Tabe Daera	M	POREBADA EAST	Self Employed	14-May-1951
1069	20083561	Tabe Hendry	M	POREBADA EAST	Self Employed	01-Jan-1969
1070	20005070	TABE SAM	M	POREBADA EAST	Worker	04-Apr-1985
1071	20083556	Tabe Tabe	M	POREBADA EAST	Self Employed	29-Sep-1987
1072	20081531	Tabe Daere Busina	M	POREBADA EAST	Worker	10-Jan-1951
1073	20008737	TABE MEA MEA	M	POREBADA EAST	Subsistence Farmer	24-Dec-1991
1074	20025467	Tapi Asi Heau	M	POREBADA EAST	Self Employed	01-Mar-1978
1075	20072511	Tara Hitolo	M	POREBADA EAST	Self Employed	01-Jan-1979
1076	20069536	Tara John	M	POREBADA EAST	Self Employed	06-Jun-1966
1077	20078988	Tara Kauna	M	POREBADA EAST	Self Employed	07-Jul-1964
1078	20227814	Tara Morris	M	POREBADA EAST	Student	06-May-2001
1079	20227816	Tara Seri	M	POREBADA EAST	Student	05-Jun-2003
1080	20090337	Tara Vele Vele	M	POREBADA EAST	Self Employed	24-Nov-1955
1081	20079185	Tarube Vaburi	M	POREBADA EAST	Self Employed	22-Nov-1985
1082	20005507	TARUBE VASIRI WILLIE	M	POREBADA EAST	Student	05-Feb-1994
1083	20123513	TARUPA GARI ARUA	M	POREBADA EAST	Fisherman	01-Jan-1972
1084	20008729	TAU GUBA	M	POREBADA EAST	Unemployed	01-Jan-1985
1085	20131118	Tau Hare Karoho	M	POREBADA EAST	Worker	28-Aug-1951
1086	20004631	TAU MICHEAL	M	POREBADA EAST	Student	01-Jan-1992
1087	20123515	TAU Morea Tau	M	POREBADA EAST	Teacher	01-Jan-1970
1088	20002940	TAU MURA	M	POREBADA EAST	Contractor	02-Jun-1969
1089	20054311	Tau Ray	M	POREBADA EAST	Self Employed	15-May-1968
1090	20131116	Tau Tauedea	M	POREBADA EAST	Teacher	06-Jul-1978
1091	20131359	Tau Taumaku	M	POREBADA EAST	Subsistence Farmer	07-Aug-1994
1092	20068064	Tau Vaburi	M	POREBADA EAST	Self Employed	21-Feb-1947
1093	20227823	Tauedea Lahui	M	POREBADA EAST	Fisherman	24-Apr-1998
1094	20227824	Tauedea Lohia	M	POREBADA EAST	Fisherman	29-Sep-2000
1095	20131400	Tauedea Morea	M	POREBADA EAST	Fisherman	02-Apr-1998
1096	20227825	Tauedea Moses	M	POREBADA EAST	Fisherman	04-Jan-2004
1097	20069291	Tauedea Papua Mataio	M	POREBADA EAST	Self Employed	29-Jan-1985
1098	20072983	Tauedea Peter	M	POREBADA EAST	Subsistence Farmer	16-Feb-1986
1099	20085710	Tauedea Igo Morea	M	POREBADA EAST	Clerk	06-Dec-1972
1100	20087699	Tauedea Igo Pune	M	POREBADA EAST	Self Employed	29-Jan-1977
1101	20004230	TAUEDEA LAHUI MOREA	M	POREBADA EAST	Fisherman	03-Feb-1993
1102	20033851	Tauedea Vaburi Taumaku	M	POREBADA EAST	Self Employed	27-Mar-1959
1103	20084073	Taumaku Arere	M	POREBADA EAST	Clerk	03-Dec-1959
1104	20094415	Taumaku Baru	M	POREBADA EAST	Security	01-Jan-1965
1105	20123519	Taumaku Goata	M	POREBADA EAST	Self Employed	10-Oct-1984
1106	20008585	TAUMAKU IGO MOREA	M	POREBADA EAST	Unemployed	01-Nov-1989
1107	20125793	Taumaku Jerry Jnr	M	POREBADA EAST	Household Duties	18-Mar-1998
1108	20123520	Taumaku Jerry Lohia	M	POREBADA EAST	Worker	16-Aug-1950
1109	20123521	TAUMAKU Jerry Taumaku	M	POREBADA EAST	Worker	02-Nov-1975
1110	20076548	Taumaku Mea	M	POREBADA EAST	Self Employed	19-May-1963
1111	20067955	Taumaku Momoru	M	POREBADA EAST	Clerk	26-Jan-1986
1112	20124868	Taumaku Morea	M	POREBADA EAST	Fisherman	13-Jul-1965
1113	20005577	TAUMAKU MOREA ARERE	M	POREBADA EAST	Student	07-Apr-1989
1114	20081539	Taumaku Peter	M	POREBADA EAST	Worker	18-Mar-1982
1115	20078726	Taumaku Pune	M	POREBADA EAST	Subsistence Farmer	06-Jun-1968
1116	20197932	Taumaku Robert	M	POREBADA EAST	Subsistence Farmer	28-Aug-1996
1117	20123522	TAUMAKU Tasman Taumaku	M	POREBADA EAST	Unemployed	01-Jan-1971
1118	20081435	Taumaku Tau	M	POREBADA EAST	Self Employed	01-Jan-1964
1119	20130940	Taumaku Tauedea	M	POREBADA EAST	Household Duties	14-Mar-1993
1120	20083538	Taumaku Taumaku	M	POREBADA EAST	Fisherman	30-Dec-1981
1121	20094455	Taumaku Koitabu Morea	M	POREBADA EAST	Self Employed	02-Jul-1959
1122	20064690	Taumaku Koitabu Riu	M	POREBADA EAST	Self Employed	15-Nov-1972
1123	20092880	Taumaku Koitabu Seri	M	POREBADA EAST	Self Employed	01-Jan-1962
1124	20092878	Taumaku Koitabu Vagi Bodibo	M	POREBADA EAST	Self Employed	27-Apr-1953
1125	20034159	Taumaku Tauedea Guba	M	POREBADA EAST	Self Employed	24-Sep-1983
1126	20005061	TAUMAKU TAUEDEA MOREA	M	POREBADA EAST	Self Employed	03-Jul-1993
1127	20131299	Tavonga Eugene	M	POREBADA EAST	Student	09-May-1998
1128	20131296	Tavonga Wilfred	M	POREBADA EAST	Policeman	26-Sep-1961
1129	20131297	Tavonga Willie	M	POREBADA EAST	Household Duties	10-Oct-1983
1130	20131399	Teina Allan	M	POREBADA EAST	Inspector	21-Aug-1982
1131	20076006	Teina Thomas	M	POREBADA EAST	Worker	09-Nov-1960
1132	20123523	TEMU Alphonse	M	POREBADA EAST	Student	28-Jul-1990
1133	20123524	TEMU Andrew	M	POREBADA EAST	Student	11-Jul-1992
1134	20131317	Temu Haiafy	M	POREBADA EAST	Unemployed	03-Jan-1998
1135	20123347	Temu VAGI	M	POREBADA EAST	Unemployed	31-Dec-1974
1136	20227829	Temu Vagi Alphonse	M	POREBADA EAST	Student	18-Feb-2002
1137	20227832	Tobby John	M	POREBADA EAST	Fisherman	15-Mar-2002
1138	20001428	TOEA BILLY	M	POREBADA EAST	Unemployed	18-Aug-1993
1139	20125784	Toea Goata	M	POREBADA EAST	Self Employed	24-May-1995
1140	20079083	Toea Gorogo	M	POREBADA EAST	Self Employed	02-Oct-1971
1141	20227834	Toea Gorogo	M	POREBADA EAST	Fisherman	07-Jun-2002
1142	20081406	Toea Lahui	M	POREBADA EAST	Self Employed	07-Jun-1977
1143	20081416	Toea Tabe	M	POREBADA EAST	Self Employed	09-Jun-1979
1144	20079064	Toea Willie	M	POREBADA EAST	Self Employed	09-Jun-1984
1145	20227835	Toea Morea Morea	M	POREBADA EAST	Unemployed	19-Dec-1968
1146	20131121	Tolana David	M	POREBADA EAST	Driver	27-May-1975
1147	20130628	Tolingling Boio	M	POREBADA EAST	Household Duties	10-Aug-1998
1148	20083666	Tolingling Moses	M	POREBADA EAST	Worker	14-Mar-1956
1149	20007112	TOM ARUA	M	POREBADA EAST	Unemployed	01-Jan-1986
1150	20058992	Tom Mora	M	POREBADA EAST	Self Employed	09-Sep-1969
1151	20004608	TOUA DIMERE	M	POREBADA EAST	Worker	29-Jun-1981
1152	20092339	Toua Doura	M	POREBADA EAST	Driver	13-Apr-1963
1153	20059066	Toua Heni	M	POREBADA EAST	Self Employed	19-Mar-1960
1154	20092586	Toua Igo	M	POREBADA EAST	Self Employed	19-Feb-1965
1155	20059219	Toua Kovae	M	POREBADA EAST	Self Employed	01-Jan-1965
1156	20123527	Toua Mea	M	POREBADA EAST	Student	15-Jun-1979
1157	20123528	Toua Mea	M	POREBADA EAST	Self Employed	08-Sep-1974
1158	20004622	TOUA MEA ARERE	M	POREBADA EAST	Student	17-Mar-1989
1159	20003408	UME EMMANUEL JNR	M	POREBADA EAST	Worker	11-Apr-1988
1160	20131327	Ume Pascal	M	POREBADA EAST	Subsistence Farmer	29-Jun-1980
1161	20227840	Ume Steven	M	POREBADA EAST	Student	08-Jun-2003
1162	20130730	Ura Vincent	M	POREBADA EAST	Unemployed	12-Dec-1958
1163	20123529	Vaburi Arere	M	POREBADA EAST	Student	10-Apr-1988
1164	20007220	VABURI ARUA	M	POREBADA EAST	Unemployed	01-Jan-1970
1165	20003521	VABURI BUSINA TAUEDEA	M	POREBADA EAST	Student	31-Oct-1989
1166	20124845	Vaburi Guba	M	POREBADA EAST	Fisherman	05-Jan-1995
1167	20123532	Vaburi Lohia	M	POREBADA EAST	Student	10-Apr-1988
1168	20123533	VABURI PUKARI	M	POREBADA EAST	Driver	01-Jan-1964
1169	20054254	Vaburi Tau	M	POREBADA EAST	Self Employed	29-Sep-1981
1170	20227843	Vaburi Arere Arere	M	POREBADA EAST	Student	12-Aug-2001
1171	20090471	Vaburi Lohia Morea	M	POREBADA EAST	Student	21-Dec-1982
1172	20130632	Vagi Anai	M	POREBADA EAST	Not Specified	06-Jan-1996
1173	20227845	Vagi Arere	M	POREBADA EAST	Student	17-Feb-2004
1174	20009057	VAGI ARUA	M	POREBADA EAST	Unemployed	25-Jul-1988
1175	20131415	Vagi Arua	M	POREBADA EAST	Fisherman	21-Oct-1994
1176	20092864	Vagi Baru	M	POREBADA EAST	Inspector	12-Apr-1969
1177	20125724	Vagi Edea	M	POREBADA EAST	Carpenter	04-Apr-1988
1178	20092684	Vagi Gau	M	POREBADA EAST	Worker	27-Nov-1947
1179	20083940	Vagi Gaudi	M	POREBADA EAST	Subsistence Farmer	04-Sep-1969
1180	20036794	Vagi Gege	M	POREBADA EAST	Worker	25-May-1968
1181	20123535	Vagi Gorogo	M	POREBADA EAST	Self Employed	23-Aug-1967
1182	20131384	Vagi Gulah	M	POREBADA EAST	Fisherman	31-Mar-1991
1183	20124980	Vagi Heau	M	POREBADA EAST	Fisherman	28-Jan-1966
1184	20125717	Vagi Helai	M	POREBADA EAST	Student	26-Jun-1997
1185	20130949	Vagi Heni	M	POREBADA EAST	Worker	16-Oct-1990
1186	20083728	Vagi Hila	M	POREBADA EAST	Self Employed	18-Jan-1965
1187	20008420	VAGI HITOLO	M	POREBADA EAST	Unemployed	12-May-1991
1188	20227847	Vagi Hitolo	M	POREBADA EAST	Fisherman	28-Mar-2001
1189	20123536	Vagi Isaiah	M	POREBADA EAST	Fisherman	05-Jun-1985
1190	20008418	VAGI KEVIN	M	POREBADA EAST	Student	01-Jan-1985
1191	20123537	Vagi Kila	M	POREBADA EAST	Self Employed	24-Nov-1959
1192	20079079	Vagi Lohia	M	POREBADA EAST	Self Employed	27-May-1976
1193	20131122	Vagi Loulai	M	POREBADA EAST	Fisherman	05-Mar-1993
1194	20007983	VAGI MOREA	M	POREBADA EAST	Unemployed	01-Jan-1983
1195	20008421	VAGI MOREA	M	POREBADA EAST	Unemployed	01-Jan-1978
1196	20130977	Vagi Morea	M	POREBADA EAST	Household Duties	01-Jan-1996
1197	20125782	Vagi Peter	M	POREBADA EAST	Worker	01-Sep-1963
1198	20131114	Vagi Peter	M	POREBADA EAST	Fisherman	22-Jun-1995
1199	20197936	Vagi Peter	M	POREBADA EAST	Subsistence Farmer	24-Apr-1996
1200	20227852	Vagi Sioni	M	POREBADA EAST	Fisherman	15-Jun-1997
1201	20008282	VAGI TAUMAKU	M	POREBADA EAST	Unemployed	01-Jan-1985
1202	20123398	Vagi Vagi	M	POREBADA EAST	Self Employed	28-Feb-1979
1203	20064497	Vagi Vagi Snr	M	POREBADA EAST	Self Employed	03-Dec-1973
1204	20130633	Vagi Vele	M	POREBADA EAST	Fisherman	15-May-1998
1205	20197962	Vagi Vele	M	POREBADA EAST	Fisherman	25-Jun-1998
1206	20034146	Vagi Arere Baru	M	POREBADA EAST	Not Specified	12-Apr-1969
1207	20034143	Vagi Arere Kelly	M	POREBADA EAST	Self Employed	22-Jul-1963
1208	20035504	Vagi Arere Momoru	M	POREBADA EAST	Clerk	07-Dec-1950
1209	20079084	Vagi Asi Arere	M	POREBADA EAST	Policeman	11-Jul-1970
1210	20227854	Vagi Dimere Koani	M	POREBADA EAST	Fisherman	27-Jul-1999
1211	20087403	Vagi Gari Gari	M	POREBADA EAST	Self Employed	07-Feb-1967
1212	20087383	Vagi Gari Vele	M	POREBADA EAST	Self Employed	17-Oct-1969
1213	20227855	Vagi Gau Gau	M	POREBADA EAST	Security	21-Apr-1995
1214	20022705	Vagi Heau Heau	M	POREBADA EAST	Student	17-Jun-1991
1215	20003354	VAGI HENI JORDAN	M	POREBADA EAST	Self Employed	07-Dec-1991
1216	20092606	Vagi Heni Seri	M	POREBADA EAST	Self Employed	23-Aug-1978
1217	20090490	Vagi Heni Simon	M	POREBADA EAST	Self Employed	23-Mar-1981
1218	20003292	VAGI IGO IGO	M	POREBADA EAST	Unemployed	15-May-1971
1219	20054510	Vagi Igo Tau	M	POREBADA EAST	Self Employed	17-Jul-1983
1220	20081589	Vagi Koani Anai	M	POREBADA EAST	Self Employed	02-Feb-1976
1221	20083612	Vagi Koani Kevau	M	POREBADA EAST	Student	28-Aug-1985
1222	20083584	Vagi Koani Koani	M	POREBADA EAST	Self Employed	09-Apr-1961
1223	20083655	Vagi Koani Pune	M	POREBADA EAST	Pastor	12-May-1972
1224	20227856	Vagi Lohia Isaiah	M	POREBADA EAST	Fisherman	18-Jun-2001
1225	20083505	Vagi Lohia Morea	M	POREBADA EAST	Self Employed	21-Nov-1945
1226	20008252	VAGI ODA TAUEDEA	M	POREBADA EAST	Self Employed	09-May-1976
1227	20033505	Vagi Pune Koani	M	POREBADA EAST	Carpenter	06-Apr-1972
1228	20004507	VAGI PUNE PUNE	M	POREBADA EAST	Worker	03-Apr-1979
1229	20003331	VAGI PUNE MEA PUNE	M	POREBADA EAST	Unemployed	02-May-1992
1230	20227857	Vagi Tau Henao	M	POREBADA EAST	Student	22-Jan-2004
1231	20131404	Vani Siai	M	POREBADA EAST	Fisherman	24-Dec-1956
1232	20003334	VANUA NEVILLE	M	POREBADA EAST	Contractor	13-Feb-1992
1233	20197945	Vanua Rupa	M	POREBADA EAST	Student	06-Mar-2000
1234	20003886	VARUBI MEA ARUA	M	POREBADA EAST	Fisherman	05-Jul-1970
1235	20076553	Varuko Goata	M	POREBADA EAST	Self Employed	02-Oct-1963
1236	20089866	Varuko Heagi	M	POREBADA EAST	Fisherman	02-Mar-1973
1237	20008258	VARUKO HITOLO	M	POREBADA EAST	Unemployed	15-Sep-1988
1238	20125714	Varuko Koani	M	POREBADA EAST	Fisherman	11-Dec-1995
1239	20094525	Varuko Igo Igo	M	POREBADA EAST	Subsistence Farmer	06-Sep-1987
1240	20047888	Vasiri Gavera	M	POREBADA EAST	Self Employed	13-Jan-1970
1241	20227859	Vasiri Iobi	M	POREBADA EAST	Worker	16-Jun-1968
1242	20227860	Vasiri Ovia	M	POREBADA EAST	Student	12-Aug-1998
1243	20047103	Vasiri Ronnie	M	POREBADA EAST	Self Employed	25-Jan-1981
1244	20007897	VASIRI VABURI	M	POREBADA EAST	Unemployed	01-Jan-1985
1245	20034390	Vasiri Gavera Vaburi	M	POREBADA EAST	Self Employed	24-Nov-1947
1246	20081561	Vaso Graham	M	POREBADA EAST	Security	12-Oct-1976
1247	20067882	Vele Busina  James	M	POREBADA EAST	Self Employed	05-Nov-1950
1248	20072897	Vele Dairi	M	POREBADA EAST	Subsistence Farmer	15-Jun-1942
1249	20123546	VELE DIMESI	M	POREBADA EAST	Student	06-Nov-1995
1250	20054274	Vele Josaia	M	POREBADA EAST	Self Employed	06-Jun-1984
1251	20123544	Vele Kovae	M	POREBADA EAST	Worker	07-Feb-1989
1252	20008221	VELE LAHUI	M	POREBADA EAST	Worker	01-Jan-1993
1253	20076451	Vele Leva	M	POREBADA EAST	Subsistence Farmer	15-Mar-1980
1254	20078738	Vele Moale	M	POREBADA EAST	Subsistence Farmer	14-Nov-1987
1255	20054750	Vele Momoru	M	POREBADA EAST	Self Employed	25-Nov-1982
1256	20079118	Vele Morea	M	POREBADA EAST	Self Employed	15-Mar-1976
1257	20227862	Vele Peter	M	POREBADA EAST	Student	15-Jan-2002
1258	20094471	Vele Tarupa Moale	M	POREBADA EAST	Subsistence Farmer	15-Apr-1950
1259	20023224	Vele Terence	M	POREBADA EAST	Worker	07-Sep-1977
1260	20123545	Vele Vele	M	POREBADA EAST	Worker	08-Jun-1972
1261	20092819	Vele  Arua Arua	M	POREBADA EAST	Self Employed	08-Jun-1987
1262	20003514	VELE ASI JACK	M	POREBADA EAST	Panel Beater	17-Apr-1972
1263	20003294	VELE ASI VARUKO	M	POREBADA EAST	Panel Beater	18-Oct-1974
1264	20005506	VELE BUSINA BURANA	M	POREBADA EAST	Worker	14-Nov-1991
1265	20062596	Vele Gari Arua	M	POREBADA EAST	Self Employed	08-Jun-1986
1267	20003652	VELE KOVAE KOVAE	M	POREBADA EAST	Student	01-Jan-1994
1268	20130731	Vincent Pako	M	POREBADA EAST	Worker	19-Mar-1992
1269	20072570	Wakeya Kini	M	POREBADA EAST	Teacher	29-Jan-1969
1270	20124239	Wau Wau Bemu	M	POREBADA EAST	Self Employed	13-Mar-1982
1271	20090392	Wiki Noho	M	POREBADA EAST	Self Employed	01-Jan-1980
1272	20123550	Willie Ilo	M	POREBADA EAST	Self Employed	24-May-1985
1273	20069272	Willie Lohia	M	POREBADA EAST	Student	01-Jan-1988
1274	20007136	WILLIE MABA	M	POREBADA EAST	Unemployed	14-Nov-1992
1275	20227865	Willie Tarube	M	POREBADA EAST	Fisherman	16-Sep-1990
\.


--
-- Data for Name: porebada_ward_economics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_ward_economics (ward_id, primary_economic_activity, employment_rate, avg_household_income, poverty_rate, small_businesses_count, market_centers_count) FROM stdin;
\.


--
-- Data for Name: porebada_ward_education; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_ward_education (ward_id, elementary_schools, high_schools, vocational_centers, total_students, teacher_count, literacy_rate, school_attendance_rate) FROM stdin;
\.


--
-- Data for Name: porebada_ward_geography; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_ward_geography (ward_id, latitude, longitude, total_area_sqkm, terrain_type, elevation_meters, boundary_geojson) FROM stdin;
\.


--
-- Data for Name: porebada_ward_health; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_ward_health (ward_id, health_centers, aid_posts, medical_staff_count, vaccination_rate, maternal_mortality_rate, infant_mortality_rate, life_expectancy) FROM stdin;
\.


--
-- Data for Name: porebada_ward_infrastructure; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_ward_infrastructure (ward_id, road_length_km, paved_roads_percent, water_access_percent, electricity_access_percent, internet_coverage_percent, public_buildings_count) FROM stdin;
\.


--
-- Data for Name: porebada_west_male_female; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.porebada_west_male_female (seq, electoral_id, name, gender, location, occupation, dob) FROM stdin;
1	20218158	Abdul Gahusi	M	POREBADA WEST	Not Specified	10-Sep-2000
2	20218159	Abdul Vincent	M	POREBADA WEST	Not Specified	03-Oct-2002
3	20057187	Agi Tapa	M	POREBADA WEST	Self Employed	02-Jan-2000
4	20131338	Ahuta Kele	M	POREBADA WEST	Student	09-Jan-1998
5	20092615	Ahuta Igo Morea	M	POREBADA WEST	Self Employed	05-Nov-1981
6	20009492	AISI BUSINA LOHIA	M	POREBADA WEST	Driver	10-May-1989
7	20009468	AISI LOHIA PETER	M	POREBADA WEST	Carpenter	26-Jul-1989
8	20218161	Aitsi Simon	M	POREBADA WEST	Not Specified	16-Apr-1994
9	20051346	Allan Heau	M	POREBADA WEST	Self Employed	30-Jun-1967
10	20073009	Anai Araidi	M	POREBADA WEST	Student	18-May-1989
11	20072518	Anai Arere	M	POREBADA WEST	Subsistence Farmer	18-Oct-1976
12	20072510	Anai Gaudi	M	POREBADA WEST	Security	14-Feb-1980
13	20003358	ANAI GAUDI ARAIDI	M	POREBADA WEST	Driver	05-Mar-1989
14	20083700	Arere Gavera	M	POREBADA WEST	Self Employed	29-Mar-1985
15	20124873	Arere Heau	M	POREBADA WEST	Student	08-Nov-1995
16	20058974	Arere Morea Mikes	M	POREBADA WEST	Clerk	05-Aug-1961
17	20131302	Arere Oda	M	POREBADA WEST	Household Duties	31-Aug-1977
18	20131303	Arere Vagi	M	POREBADA WEST	Security	06-Dec-1973
19	20064962	Arere   Vagi John	M	POREBADA WEST	Self Employed	05-Jan-1984
20	20218164	Arere Arua Arua	M	POREBADA WEST	Not Specified	24-Dec-2002
21	20218165	Arere Arua Igo	M	POREBADA WEST	Not Specified	24-Jan-1997
22	20218167	Arere Morea Arua	M	POREBADA WEST	Not Specified	30-Sep-1939
23	20083954	Arere Vagi Aeari	M	POREBADA WEST	Self Employed	29-Oct-1983
24	20123354	Arerevagi Oda	M	POREBADA WEST	Worker	20-Sep-1970
25	20054505	Arua Arere	M	POREBADA WEST	Self Employed	19-Jul-1999
26	20197971	Arua Arere	M	POREBADA WEST	Unemployed	19-Jul-1999
27	20003543	ARUA BARU REV	M	POREBADA WEST	Pastor	25-Aug-1957
28	20008322	ARUA DAIRI	M	POREBADA WEST	Not Specified	27-Jul-1973
29	20124116	Arua Dairi Gege	M	POREBADA WEST	Self Employed	04-Sep-1971
30	20218170	Arua Gabe	M	POREBADA WEST	Not Specified	12-Dec-2003
31	20076738	Arua Gau	M	POREBADA WEST	Student	13-Sep-1986
32	20081580	Arua Gege	M	POREBADA WEST	Self Employed	01-Jan-1972
33	20081582	Arua Hera	M	POREBADA WEST	Self Employed	01-Jan-1970
34	20057193	Arua Hitolo	M	POREBADA WEST	Pastor	18-May-1960
35	20087390	Arua Inara	M	POREBADA WEST	Self Employed	01-Jan-1984
36	20003341	ARUA LAHUI	M	POREBADA WEST	Student	16-Aug-1988
37	20031838	Arua Nono Lahui	M	POREBADA WEST	Security	01-Jan-1971
38	20083643	Arua Rakatani Jnr	M	POREBADA WEST	Self Employed	21-May-1967
39	20131368	Arua Raymond	M	POREBADA WEST	Pastor	13-Oct-1960
40	20076009	Arua Tara	M	POREBADA WEST	Subsistence Farmer	08-Feb-1959
41	20083610	Arua Taumaku	M	POREBADA WEST	Self Employed	17-May-1960
42	20081590	Arua Vaburi	M	POREBADA WEST	Self Employed	01-Jan-1976
43	20131396	Arua Vagi	M	POREBADA WEST	Driver	08-Jan-1976
44	20076445	Arua Arere Arere	M	POREBADA WEST	Self Employed	08-Mar-1970
45	20085714	Arua Auani Vaburi	M	POREBADA WEST	Self Employed	06-Jul-1976
46	20031804	Arua Auani Vagi Nono	M	POREBADA WEST	Security	22-Jun-1972
47	20090273	Arua Dabara Dabara	M	POREBADA WEST	Student	03-Oct-1987
48	20087428	Arua Dabara Morea Dikana	M	POREBADA WEST	Self Employed	27-Nov-1977
49	20092604	Arua Dairi Morea Nohokau	M	POREBADA WEST	Self Employed	07-Apr-1965
50	20051153	Arua Dairi Vaburi	M	POREBADA WEST	Subsistence Farmer	04-Oct-1974
51	20032186	Arua Dairi Vagi	M	POREBADA WEST	Self Employed	28-Jan-1977
52	20067903	Arua Gorogo Morea	M	POREBADA WEST	Self Employed	27-May-1967
53	20067910	Arua Karua Mea	M	POREBADA WEST	Self Employed	23-Dec-1956
54	20004176	ARUA LAHUI KOHU	M	POREBADA WEST	Self Employed	09-Jun-1993
55	20054797	Arua Siage Mea	M	POREBADA WEST	Self Employed	12-Jul-1983
56	20056644	Arua Siage Siage	M	POREBADA WEST	Subsistence Farmer	02-Apr-1980
57	20069289	Arua Tolo Igo	M	POREBADA WEST	Auditor	02-Oct-1974
58	20067963	Arua Tolo Simon	M	POREBADA WEST	Security	07-Jul-1978
59	20069284	Arua Tolo Tolo	M	POREBADA WEST	Security	28-May-1981
60	20079056	Arua Vele Hitolo	M	POREBADA WEST	Self Employed	20-Nov-1980
61	20085481	Arua Vele Mea	M	POREBADA WEST	Self Employed	01-Jan-1963
62	20004617	ARUA VELE SIONI	M	POREBADA WEST	Worker	06-Nov-1990
63	20197986	Asi Dairi	M	POREBADA WEST	Unemployed	30-Jun-1997
64	20094928	Asi Gau	M	POREBADA WEST	Self Employed	04-Nov-1964
65	20054506	Asi Morea	M	POREBADA WEST	Self Employed	11-Jul-1950
66	20197989	Asi Seoli	M	POREBADA WEST	Unemployed	21-May-1996
67	20078636	Asi Seri	M	POREBADA WEST	Financial Officer	08-Mar-1954
68	20005510	ASI ISAIAH ISAIAH	M	POREBADA WEST	Self Employed	19-Jun-1992
69	20131111	Aua Morea	M	POREBADA WEST	Worker	04-Aug-1978
70	20131110	Aua Naime	M	POREBADA WEST	Security	14-Feb-1985
71	20131113	Aua Raho	M	POREBADA WEST	Student	30-Jan-1996
72	20218172	Auani Siage jack	M	POREBADA WEST	Not Specified	25-May-1980
73	20092799	Audabi Kovea Arnold	M	POREBADA WEST	Self Employed	11-Feb-1987
74	20218173	Awala Dattern	M	POREBADA WEST	Not Specified	18-Mar-1972
75	20218175	Baru Billy	M	POREBADA WEST	Not Specified	12-Oct-1996
76	20058868	Baru Dairi	M	POREBADA WEST	Self Employed	06-Jul-1975
77	20131346	Baru Dairi	M	POREBADA WEST	Fisherman	05-Apr-1966
78	20062408	Baru Gau	M	POREBADA WEST	Self Employed	17-May-1974
79	20079103	Baru Judah Mathew	M	POREBADA WEST	Clerk	23-Nov-1963
80	20090247	Baru Karua	M	POREBADA WEST	Self Employed	22-Dec-1983
81	20058977	Baru Mea	M	POREBADA WEST	Subsistence Farmer	26-Sep-1975
82	20050661	Baru Morea	M	POREBADA WEST	Subsistence Farmer	05-Feb-1962
83	20056524	Baru Oda	M	POREBADA WEST	Self Employed	08-Jul-1946
84	20007889	BARU TAU	M	POREBADA WEST	Lecturer	11-Sep-1951
85	20004693	BARU TAUEDEA	M	POREBADA WEST	Student	07-Mar-1989
86	20059233	Baru Taumaku	M	POREBADA WEST	Household Duties	12-Oct-1969
87	20197966	Baru Taumaku Jnr	M	POREBADA WEST	Unemployed	03-Jun-1996
88	20008226	BARU TAUMAKU TAU	M	POREBADA WEST	Worker	27-Sep-1982
89	20062411	Baru Varuko	M	POREBADA WEST	Subsistence Farmer	11-Dec-1986
90	20062149	Baru Dairi Raka	M	POREBADA WEST	Self Employed	16-Apr-1970
91	20088158	Baru Dairi Sioni	M	POREBADA WEST	Retired	01-Sep-2000
92	20081390	Baru Tau Taumaku	M	POREBADA WEST	Engineer	16-Jun-1968
93	20069286	Bemu Hitolo Taumaku	M	POREBADA WEST	Self Employed	01-Jan-1968
94	20092607	Benson Igo	M	POREBADA WEST	Student	14-Apr-1987
95	20081131	Bitu Bodibo Seri	M	POREBADA WEST	Clerk	20-Oct-1971
96	20089780	Bitu Gavera	M	POREBADA WEST	Accountant	19-Mar-1956
97	20005171	BITU GAVERA JUNIOR	M	POREBADA WEST	Manager	15-Jun-1981
98	20005182	BITU SERI	M	POREBADA WEST	Self Employed	08-Nov-1985
99	20061953	Bodibo Dorido	M	POREBADA WEST	Self Employed	27-Apr-1986
100	20081122	Bodibo Edea	M	POREBADA WEST	Accountant	12-Jun-1952
101	20094543	Bodibo Enere	M	POREBADA WEST	Self Employed	20-Jun-1971
102	20218182	Bodibo Heau	M	POREBADA WEST	Not Specified	22-Sep-2001
103	20218183	Bodibo Isaiah	M	POREBADA WEST	Not Specified	11-Jan-1997
104	20085718	Bodibo Lohia	M	POREBADA WEST	Subsistence Farmer	03-May-1960
105	20003360	BODIBO SERI KOVAE	M	POREBADA WEST	Student	03-Feb-1994
106	20092370	Boroma Ovia	M	POREBADA WEST	Self Employed	31-Dec-1979
107	20031359	Bua Nono Bua	M	POREBADA WEST	Student	21-Apr-1987
108	20032485	Bua Nono Nono	M	POREBADA WEST	Self Employed	03-Dec-1975
109	20123369	Busina Daera	M	POREBADA WEST	Self Employed	22-Jan-1985
110	20069755	Busina John	M	POREBADA WEST	Self Employed	27-Aug-1987
111	20051166	Busina Karua Tabe	M	POREBADA WEST	Customs Officer	24-Dec-1958
112	20069754	Busina Loa	M	POREBADA WEST	Self Employed	23-Nov-1979
113	20022366	Busina Tony	M	POREBADA WEST	Student	09-May-1992
114	20076585	Busina Dairi Lohia	M	POREBADA WEST	Self Employed	01-Jan-1978
115	20218186	Busina Karua Morea	M	POREBADA WEST	Not Specified	20-Oct-1993
116	20009572	BUSINA LOHIA HAVATA	M	POREBADA WEST	Worker	04-May-1990
117	20218187	Busina Lohia Jimmy	M	POREBADA WEST	Not Specified	05-Sep-1998
118	20218188	Busina Lohia Lohia	M	POREBADA WEST	Not Specified	13-Jul-2002
119	20090274	Dabara Arere	M	POREBADA WEST	Self Employed	01-Jan-1969
120	20087432	Dabara Arua	M	POREBADA WEST	Teacher	10-Jul-1954
121	20089871	Dabara Koani	M	POREBADA WEST	Security	21-Aug-1964
122	20087418	Dabara Mabata	M	POREBADA WEST	Self Employed	21-Sep-1952
123	20088147	Dabara Tarata	M	POREBADA WEST	Self Employed	01-Jan-1966
124	20035396	Dabara Arere Auda	M	POREBADA WEST	Self Employed	01-Jan-1975
125	20092787	Dadami Hera	M	POREBADA WEST	Self Employed	26-Apr-1983
126	20081498	Dairi Baru	M	POREBADA WEST	Self Employed	03-Aug-1968
127	20094550	Dairi Gege Banige	M	POREBADA WEST	Self Employed	30-Jul-1976
128	20079137	Dairi Gege Jrn	M	POREBADA WEST	Self Employed	30-Jul-1973
129	20092714	Dairi Igo	M	POREBADA WEST	Self Employed	30-Oct-1975
130	20130742	Dairi Lohia	M	POREBADA WEST	Fisherman	03-Oct-1993
131	20079148	Dairi Sioni	M	POREBADA WEST	Self Employed	15-Feb-1957
132	20059413	Dairi Taumaku	M	POREBADA WEST	Policeman	15-Aug-1977
133	20218192	Dairi Vaburi	M	POREBADA WEST	Not Specified	06-Dec-2000
134	20003533	DAIRI VAGI	M	POREBADA WEST	Unemployed	01-Jan-1993
135	20004590	DAIRI BARU BARU	M	POREBADA WEST	Self Employed	23-Mar-1990
136	20004532	DAIRI BARU IGO	M	POREBADA WEST	Not Specified	16-Oct-1993
137	20004679	DAIRI DAIRI HEAU	M	POREBADA WEST	Pastor	31-Dec-1954
138	20004614	DAIRI KOKO TAUMAKU	M	POREBADA WEST	Self Employed	07-Jun-1992
139	20076596	Dairi Morea Baru	M	POREBADA WEST	Subsistence Farmer	01-Jan-1987
140	20076457	Dairi Morea Busina	M	POREBADA WEST	Self Employed	11-Sep-1980
141	20005183	DAIRI MOREA JACK	M	POREBADA WEST	Student	04-Mar-1990
142	20032067	Dairi Morea Lohia	M	POREBADA WEST	Self Employed	19-Sep-1978
143	20078747	Dairi Morea Morea	M	POREBADA WEST	Self Employed	01-Jan-1986
144	20004711	DAIRI MOREA TAISI	M	POREBADA WEST	Student	14-Dec-1993
145	20068069	Dairi Taumaku Arua	M	POREBADA WEST	Councillor	15-Jan-1952
146	20218193	Dakman Leigh	M	POREBADA WEST	Not Specified	06-Apr-1998
147	20003644	DAMIAN SAGAP GABE	M	POREBADA WEST	Self Employed	24-Oct-1972
148	20069299	Daroa Hera	M	POREBADA WEST	Self Employed	22-Sep-1975
149	20069295	Daroa Manoka	M	POREBADA WEST	Self Employed	20-Jan-1985
150	20009558	DAROA NOHOKAU TAUMAKU	M	POREBADA WEST	Fisherman	12-Feb-1992
151	20034308	Daroa Gahusi Gahusi	M	POREBADA WEST	Self Employed	01-Jan-1976
152	20034312	Daroa Gahusi Oda	M	POREBADA WEST	Self Employed	01-Jan-1977
153	20036664	Daroa Gahusi Tau	M	POREBADA WEST	Self Employed	01-Jan-1975
154	20089836	David Baeau	M	POREBADA WEST	Self Employed	23-Dec-1988
155	20090399	David Harry	M	POREBADA WEST	Self Employed	18-Oct-1986
156	20062517	Dika Morea	M	POREBADA WEST	Self Employed	11-Dec-1987
157	20062176	Dika Vagi	M	POREBADA WEST	Self Employed	11-Aug-1977
158	20218197	Dimere Hitolo	M	POREBADA WEST	Not Specified	28-Nov-1998
159	20087416	Dorido Bodibo	M	POREBADA WEST	Subsistence Farmer	02-Jan-2000
160	20085508	Dorido Gaudi	M	POREBADA WEST	Subsistence Farmer	15-Mar-1951
161	20061884	Dorido Lohia	M	POREBADA WEST	Self Employed	24-Nov-1984
162	20003598	DOURA HEAU	M	POREBADA WEST	Unemployed	01-Jan-1984
163	20017852	Doura Vagi	M	POREBADA WEST	Self Employed	17-Jun-1989
164	20092711	Ebo John	M	POREBADA WEST	Self Employed	01-Jan-1978
165	20092707	Ebo Kauna	M	POREBADA WEST	Self Employed	01-Jan-1972
166	20094488	Ebo Kovea Ebo	M	POREBADA WEST	Subsistence Farmer	02-Jan-2000
167	20054791	Eguta Igo	M	POREBADA WEST	Self Employed	15-Feb-1942
168	20218202	Eguta Jnr Maraga	M	POREBADA WEST	Not Specified	02-Apr-1994
169	20004598	FRANSIS MOREA	M	POREBADA WEST	Self Employed	10-Sep-1987
170	20022352	Gabae Billy	M	POREBADA WEST	Fisherman	03-Apr-1977
171	20218206	Gabaho Kari	M	POREBADA WEST	Not Specified	21-Aug-2002
172	20018021	Gabaho Nanai	M	POREBADA WEST	Self Employed	28-Jun-1993
173	20130989	Gabaho Norman	M	POREBADA WEST	Fisherman	11-Aug-1995
174	20218207	Gabe Arua Arua	M	POREBADA WEST	Not Specified	06-Oct-1978
175	20218208	Gadei Rua Baru	M	POREBADA WEST	Not Specified	21-Apr-1998
176	20218209	Gahusi Abdul Lohia	M	POREBADA WEST	Not Specified	24-Aug-1971
177	20064956	Gahusi Maraga	M	POREBADA WEST	Self Employed	02-Jan-2000
178	20067973	Gahusi Gure Dairi	M	POREBADA WEST	Self Employed	18-Oct-1954
179	20034293	Gahusi Hera Daroa	M	POREBADA WEST	Self Employed	02-Jan-2000
180	20004237	GAHUSI TAU GOROGO	M	POREBADA WEST	Fisherman	26-Oct-1989
181	20054211	Gaigo Bagu	M	POREBADA WEST	Self Employed	10-Jan-1985
182	20050650	Gaigo Tara	M	POREBADA WEST	Self Employed	21-Jan-1989
183	20218210	Gari Arua	M	POREBADA WEST	Not Specified	23-Feb-2000
184	20019027	Gari Eari	M	POREBADA WEST	Self Employed	02-Apr-1993
185	20218211	Gari Fredy	M	POREBADA WEST	Not Specified	05-Jul-1982
186	20083594	Gari Gari	M	POREBADA WEST	Self Employed	15-Jun-1976
187	20023158	Gari Igo	M	POREBADA WEST	Self Employed	30-Apr-1990
188	20092685	Gari Kauna	M	POREBADA WEST	Pastor	23-Jun-1978
189	20218213	Gari Kovae	M	POREBADA WEST	Not Specified	27-Sep-1975
190	20218214	Gari Morea	M	POREBADA WEST	Not Specified	26-Aug-1997
191	20094357	Gari Kauna Bodibo	M	POREBADA WEST	Student	20-Dec-1986
192	20092675	Gari Kauna Lohia	M	POREBADA WEST	Self Employed	30-Nov-1980
193	20057023	Gary O-ou	M	POREBADA WEST	Doctor	11-Oct-1959
194	20083590	Gau Bitu	M	POREBADA WEST	Self Employed	15-Apr-1973
195	20092286	Gau Dairi	M	POREBADA WEST	Subsistence Farmer	27-Jan-1971
196	20123387	GAU DAVID PATRICK	M	POREBADA WEST	Student	24-Jan-1992
197	20094542	Gau Edea	M	POREBADA WEST	Self Employed	19-Jan-1984
198	20003504	GAU GAU PATRICK	M	POREBADA WEST	Worker	18-May-1985
199	20056779	Gau Hitolo	M	POREBADA WEST	Self Employed	07-Jul-1964
200	20076552	Gau Kauna	M	POREBADA WEST	Self Employed	29-Apr-1959
201	20079080	Gau Kokoro	M	POREBADA WEST	Self Employed	01-Jan-1974
202	20008283	GAU MAKO	M	POREBADA WEST	Unemployed	01-Jan-1988
203	20083588	Gau Pako	M	POREBADA WEST	Self Employed	11-Jun-1965
204	20218215	Gau Pako	M	POREBADA WEST	Not Specified	29-Dec-2001
205	20124137	Gau Pako Patrick	M	POREBADA WEST	Pastor	01-Jan-1955
206	20072980	Gau Simon	M	POREBADA WEST	Subsistence Farmer	12-Mar-1975
207	20003507	GAU VAGI	M	POREBADA WEST	Farm worker	01-Jan-1987
208	20197987	Gau Vagi	M	POREBADA WEST	Unemployed	05-Oct-1998
209	20218216	Gau Asi Seri	M	POREBADA WEST	Not Specified	07-Jan-1990
210	20218218	Gau Eguta Homoka	M	POREBADA WEST	Not Specified	01-Jan-2000
211	20002535	GAU EGUTA IGO	M	POREBADA WEST	Casual Worker	06-Jan-1990
212	20218219	Gau Eguta Kaia	M	POREBADA WEST	Not Specified	07-Mar-2004
213	20218221	Gau Eguta Vagi	M	POREBADA WEST	Not Specified	24-Jan-1992
214	20218222	Gau Heau Bua	M	POREBADA WEST	Not Specified	24-Nov-1995
215	20004571	GAU HEAU VAGI	M	POREBADA WEST	Worker	08-Nov-1988
216	20005042	GAU HENAO GAU	M	POREBADA WEST	Subsistence Farmer	10-Oct-1989
217	20003653	GAU HENAO HENAO	M	POREBADA WEST	Student	17-Sep-1991
218	20076015	Gau Igo Lahui	M	POREBADA WEST	Subsistence Farmer	15-Jul-1963
219	20218223	Gau Kokoro Lohia	M	POREBADA WEST	Not Specified	25-Apr-1962
220	20218224	Gau Loa Gau	M	POREBADA WEST	Not Specified	12-Sep-1983
221	20218225	Gau morea Charlie	M	POREBADA WEST	Not Specified	04-Jul-1993
222	20064575	Gau Raka Heni	M	POREBADA WEST	Self Employed	09-Sep-1959
223	20061897	Gau Raka Morea	M	POREBADA WEST	Self Employed	13-Feb-2010
224	20004565	GAU RAKA RAKA	M	POREBADA WEST	Self Employed	29-Jun-1989
225	20076487	Gau Rei Hitolo	M	POREBADA WEST	Subsistence Farmer	20-Nov-1984
226	20022426	Gau Simon Gaudi	M	POREBADA WEST	Security	06-Mar-1986
227	20218226	Gau Simon Heagi	M	POREBADA WEST	Not Specified	13-Oct-1987
228	20018622	Gau Simon Raka	M	POREBADA WEST	Worker	03-Dec-1976
229	20076101	Gaudi Anai	M	POREBADA WEST	Accountant	01-Jan-1949
230	20106232	Gaudi Kohu	M	POREBADA WEST	Self Employed	02-Jan-2000
231	20054214	Gaudi Lohia	M	POREBADA WEST	Subsistence Farmer	16-Jun-1981
232	20050674	Gaudi Morea	M	POREBADA WEST	Self Employed	24-Aug-1987
233	20085715	Gaudi Dorido Igo	M	POREBADA WEST	Subsistence Farmer	18-Dec-1987
234	20085737	Gaudi Dorido Maraga	M	POREBADA WEST	Subsistence Farmer	04-Feb-1982
235	20089849	Gaudi Kohu Kohu	M	POREBADA WEST	Self Employed	02-Jan-2000
236	20001422	GAVERA BITU	M	POREBADA WEST	Self Employed	19-Aug-1989
237	20003525	GAVERA BITU	M	POREBADA WEST	Unemployed	19-Aug-1989
238	20079139	Gege Ahuta	M	POREBADA WEST	Self Employed	02-Dec-1969
239	20081493	Gege Dairi  Jrn	M	POREBADA WEST	Self Employed	18-Nov-1984
240	20081476	Gege Gure	M	POREBADA WEST	Self Employed	29-Aug-1976
241	20079159	Gege Hitolo	M	POREBADA WEST	Self Employed	18-Feb-1970
242	20079145	Gege Iana	M	POREBADA WEST	Self Employed	20-May-1971
243	20081495	Gege Igo	M	POREBADA WEST	Self Employed	15-Feb-1964
244	20079069	Gege Vaburi	M	POREBADA WEST	Self Employed	17-Sep-1984
245	20081491	Gege Willie	M	POREBADA WEST	Self Employed	08-Aug-1980
246	20009353	GEGE DAIRI KEVAU	M	POREBADA WEST	Worker	28-Apr-1972
247	20081413	Goasa Goasa	M	POREBADA WEST	Self Employed	03-Dec-1972
248	20131414	Goasa Heagi	M	POREBADA WEST	Student	22-Jun-1997
249	20087412	Goasa Isaiah	M	POREBADA WEST	Self Employed	11-Feb-1984
250	20069301	Goasa Ova	M	POREBADA WEST	Self Employed	05-Aug-1960
251	20094511	Goasa Ova Homoka	M	POREBADA WEST	Customs Officer	06-May-1956
252	20079091	Goata David Isaiah	M	POREBADA WEST	Worker	03-Aug-1956
253	20218228	Goata Gabe	M	POREBADA WEST	Not Specified	16-Jul-1998
254	20003613	GOATA KENI	M	POREBADA WEST	Worker	27-Dec-1972
255	20072952	Goata Busina Busina	M	POREBADA WEST	Self Employed	23-Oct-1978
256	20072903	Goata Busina Karua	M	POREBADA WEST	Self Employed	23-Oct-1976
257	20003954	GOATA BUSINA PETER	M	POREBADA WEST	Unemployed	11-Dec-1991
258	20076010	Goata Busina Tau	M	POREBADA WEST	Self Employed	07-Aug-1978
259	20018022	Goata Morea Lohia	M	POREBADA WEST	Self Employed	02-Apr-1990
260	20022404	Goata Morea Morea	M	POREBADA WEST	Self Employed	06-May-1989
261	20005528	GOROGO GAHUSI	M	POREBADA WEST	Self Employed	20-Aug-1992
262	20081573	Gorogo Lohia	M	POREBADA WEST	Self Employed	01-Jan-1961
263	20078737	Gorogo Sioni	M	POREBADA WEST	Subsistence Farmer	01-Jan-1954
264	20125720	Gorogo Terry	M	POREBADA WEST	Student	07-Feb-1994
265	20130980	Gorogo Terry	M	POREBADA WEST	Student	20-May-1997
266	20130978	Gorogo Vaburi	M	POREBADA WEST	Not Specified	20-Aug-1998
267	20089711	Gorogo Koani Arua	M	POREBADA WEST	Self Employed	18-Sep-1969
268	20089763	Gorogo Koani Toea	M	POREBADA WEST	Subsistence Farmer	07-Jun-1975
269	20218232	Guba Gari	M	POREBADA WEST	Not Specified	10-Jul-1998
270	20218233	Guba Gavera	M	POREBADA WEST	Not Specified	02-Feb-2002
271	20007115	GUBA HENI	M	POREBADA WEST	Unemployed	25-Mar-1991
272	20124143	Guba Heni Tau	M	POREBADA WEST	Self Employed	02-Mar-1976
273	20218234	Guba Maba	M	POREBADA WEST	Not Specified	25-Jun-1993
274	20067972	Guba Heni Lahui	M	POREBADA WEST	Self Employed	10-Oct-1980
275	20067906	Guba Heni Morea	M	POREBADA WEST	Self Employed	03-Jan-1981
276	20032479	Guba Sisia Sisia	M	POREBADA WEST	Self Employed	01-Jan-1982
277	20004572	GUNI WAULA TOEA	M	POREBADA WEST	Worker	27-Aug-1987
278	20079073	Gure Gege	M	POREBADA WEST	Self Employed	01-May-2000
279	20218237	Gure Moi	M	POREBADA WEST	Not Specified	06-Jan-1999
280	20079134	Gure Morea	M	POREBADA WEST	Self Employed	28-Oct-1952
281	20005155	GURE HERA HERA	M	POREBADA WEST	Student	05-Jan-1994
282	20218239	Harry Micheal	M	POREBADA WEST	Not Specified	12-Dec-2000
283	20131360	Heagi Gary	M	POREBADA WEST	Student	18-Apr-1997
284	20124857	Heagi Lohia	M	POREBADA WEST	Fisherman	08-Sep-1980
285	20058975	Heagi Morea	M	POREBADA WEST	Self Employed	27-Jan-1950
286	20218240	Heagi Varuko	M	POREBADA WEST	Not Specified	28-Oct-1999
287	20054800	Heagi Gari Morea	M	POREBADA WEST	Self Employed	01-Jan-1958
288	20033591	Heagi Isaiah Vagi	M	POREBADA WEST	Driver	01-Jan-1977
289	20054478	Heagi Lahui Heagi	M	POREBADA WEST	Subsistence Farmer	08-May-1962
290	20032049	Heagi Ranu Morea	M	POREBADA WEST	Self Employed	03-Dec-1955
291	20025290	Heagi Riu Gari	M	POREBADA WEST	Self Employed	01-Jan-1978
292	20003355	HEAGI RIU SIMON	M	POREBADA WEST	Self Employed	29-Mar-1988
293	20032490	Heagi Tabe Busina	M	POREBADA WEST	Self Employed	01-Nov-1968
294	20061843	Heagi Tabe Morea	M	POREBADA WEST	Subsistence Farmer	21-Aug-1963
295	20218241	Heagi Tara John	M	POREBADA WEST	Not Specified	01-May-2001
296	20004518	HEAGI TARA TARA	M	POREBADA WEST	Fisherman	09-Feb-1991
297	20069554	Heau Arua	M	POREBADA WEST	Self Employed	04-Dec-1976
298	20123412	Heau David Kauna	M	POREBADA WEST	Fisherman	01-Jan-1981
299	20129885	Heau Dimere	M	POREBADA WEST	Student	18-Sep-1998
300	20124150	Heau Heau Vagi	M	POREBADA WEST	Worker	14-Feb-1967
301	20057196	Heau Kauna	M	POREBADA WEST	Subsistence Farmer	05-Jul-1980
302	20081139	Heau Kevau	M	POREBADA WEST	Self Employed	06-Oct-1986
303	20129882	Heau Kokoro	M	POREBADA WEST	Fisherman	10-Apr-1992
304	20079020	Heau Riu	M	POREBADA WEST	Self Employed	01-Feb-1980
305	20005136	HEAU BARU GAU	M	POREBADA WEST	Worker	22-Nov-1963
306	20004703	HEAU BARU VAGI	M	POREBADA WEST	Worker	16-Oct-1968
307	20004193	HEAU DAIRI HEAGI	M	POREBADA WEST	Self Employed	25-Jan-1984
308	20059474	Heau Dairi Riu	M	POREBADA WEST	Self Employed	01-Feb-1980
309	20003363	HEAU HEAU GAU	M	POREBADA WEST	Worker	01-May-1970
310	20072875	Heau Vagi Arere	M	POREBADA WEST	Self Employed	25-Mar-1985
311	20025280	Heau Vagi Homoka	M	POREBADA WEST	Self Employed	21-Nov-1971
312	20069553	Heau Vagi Vagi	M	POREBADA WEST	Self Employed	09-Dec-1968
313	20067971	Hegora Bua	M	POREBADA WEST	Self Employed	31-May-1983
314	20002808	HEGORA GAVERA	M	POREBADA WEST	Contractor	22-Nov-1989
315	20069556	Hegora Sibona	M	POREBADA WEST	Self Employed	11-Feb-1977
316	20045653	Helai Gau	M	POREBADA WEST	Self Employed	01-Jun-2000
317	20218245	Helai Jackson	M	POREBADA WEST	Not Specified	29-Jan-2001
318	20054203	Helai Rakatani	M	POREBADA WEST	Accountant	06-Jun-1955
319	20092722	Henao Gau	M	POREBADA WEST	Worker	12-Apr-1966
320	20085723	Henao Koita	M	POREBADA WEST	Subsistence Farmer	01-Jan-1957
321	20089768	Henao Maraga	M	POREBADA WEST	Not Specified	08-Aug-1953
322	20087393	Henao Maraga Seri	M	POREBADA WEST	Self Employed	25-Apr-1956
323	20089858	Heni Gari	M	POREBADA WEST	Subsistence Farmer	16-Oct-1973
324	20092342	Heni Guba	M	POREBADA WEST	Self Employed	09-Sep-1965
325	20218247	Heni Ilimo	M	POREBADA WEST	Not Specified	09-May-2002
326	20079043	Heni Koru	M	POREBADA WEST	Subsistence Farmer	26-Mar-1976
327	20009350	HENI MICKY MIKI	M	POREBADA WEST	Driver	13-Jun-1963
328	20092346	Heni Rosi	M	POREBADA WEST	Self Employed	17-Apr-1972
329	20218248	Heni Gau Kenny	M	POREBADA WEST	Not Specified	21-Mar-1997
330	20079096	Heni Igo Igo	M	POREBADA WEST	Security	19-Jul-1983
331	20079019	Heni Igo Lohia	M	POREBADA WEST	Subsistence Farmer	04-Oct-1985
332	20003874	HENI SISIA KONE	M	POREBADA WEST	Fisherman	01-Jan-1991
333	20031997	Heni Sisia Thomas	M	POREBADA WEST	Subsistence Farmer	13-Jul-1987
334	20022672	Henry Abel	M	POREBADA WEST	Self Employed	24-Feb-1991
335	20094516	Henry Rakatani	M	POREBADA WEST	Self Employed	14-Jan-1959
336	20036668	Henry Dorido Tabe	M	POREBADA WEST	Self Employed	01-Jan-1964
337	20094910	Henry Rakatani Gahusi	M	POREBADA WEST	Self Employed	21-Feb-1979
338	20069300	Hera Gahusi	M	POREBADA WEST	Self Employed	09-Sep-1963
339	20085733	Hera Guba	M	POREBADA WEST	Self Employed	16-Mar-1985
340	20069680	Hera Gure	M	POREBADA WEST	Self Employed	23-Nov-1963
341	20090500	Hera Iana	M	POREBADA WEST	Self Employed	01-Jan-1952
342	20085732	Hera Lohia	M	POREBADA WEST	Self Employed	24-Dec-1981
343	20085734	Hera Morea	M	POREBADA WEST	Self Employed	01-Jan-1989
344	20090483	Hera Gahusi Dadami	M	POREBADA WEST	Self Employed	24-Feb-1953
345	20076528	Hera Gahusi Dairi	M	POREBADA WEST	Self Employed	10-Apr-1974
346	20076525	Hera Gahusi Gahusi	M	POREBADA WEST	Self Employed	01-Jan-1960
347	20072899	Hera Gahusi Koani	M	POREBADA WEST	Self Employed	01-Jan-1972
348	20076527	Hera Gahusi Ova	M	POREBADA WEST	Self Employed	17-Jul-1969
349	20072958	Hera Gahusi Rakatani	M	POREBADA WEST	Self Employed	20-Jun-1966
350	20197988	Hitolo Arua	M	POREBADA WEST	Unemployed	07-Mar-1996
351	20069290	Hitolo Dairi	M	POREBADA WEST	Worker	16-Apr-1969
352	20197979	Hitolo Lohia	M	POREBADA WEST	Student	27-Apr-2000
353	20003969	HITOLO PETER	M	POREBADA WEST	Farm worker	01-Jan-1990
354	20072504	Hitolo Tara	M	POREBADA WEST	Consultant	21-Feb-1948
355	20094497	Hitolo Taumaku	M	POREBADA WEST	Student	17-Apr-1985
356	20031850	Hitolo Arua Nohokau	M	POREBADA WEST	Student	01-Jan-1988
357	20032480	Hitolo Arua Oda	M	POREBADA WEST	Student	01-Jan-1989
358	20005035	HITOLO AUANI IOA	M	POREBADA WEST	Subsistence Farmer	14-Apr-1992
359	20218254	Hitolo Homoka Morea	M	POREBADA WEST	Not Specified	05-Mar-1991
360	20005059	HITOLO JUNIOR PETER	M	POREBADA WEST	Self Employed	10-Oct-1988
361	20034604	Hitolo Kovea Homoka	M	POREBADA WEST	Clerk	28-Aug-1969
362	20092788	Hitolo Kovea Peter	M	POREBADA WEST	Self Employed	01-Jan-1962
363	20069682	Homoka Bitu	M	POREBADA WEST	Salesman	10-Feb-1981
364	20218255	Homoka Goasa	M	POREBADA WEST	Not Specified	13-Sep-2002
365	20069294	Homoka Heagi	M	POREBADA WEST	Self Employed	08-Feb-1979
366	20056631	Homoka Hitolo	M	POREBADA WEST	Self Employed	21-Sep-1962
367	20131383	Homoka Isaiah	M	POREBADA WEST	Student	27-Dec-1997
368	20054404	Homoka John	M	POREBADA WEST	Driver	21-Aug-1957
369	20092282	Homoka Kokoro	M	POREBADA WEST	Self Employed	01-May-1952
370	20218256	Homoka Kovae	M	POREBADA WEST	Not Specified	21-Mar-2003
371	20090390	Homoka Lohia	M	POREBADA WEST	Subsistence Farmer	19-Aug-1975
372	20092876	Homoka Goasa Mairi	M	POREBADA WEST	Self Employed	09-Sep-1978
373	20094504	Homoka Goasa Ova	M	POREBADA WEST	Self Employed	03-Mar-1983
374	20087372	Homoka Ova Arua	M	POREBADA WEST	Self Employed	01-Jan-1966
375	20089772	Homoka Ova Kauna	M	POREBADA WEST	Self Employed	01-Aug-1964
376	20087373	Homoka Ova Ova	M	POREBADA WEST	Self Employed	01-Jan-1968
377	20092862	Homoka Seri Heagi	M	POREBADA WEST	Self Employed	25-Jan-1973
378	20031885	Homoka Seri Seri	M	POREBADA WEST	Self Employed	15-Dec-1974
379	20131347	Iana Hera	M	POREBADA WEST	Fisherman	30-Mar-1989
380	20218258	Iana Koita	M	POREBADA WEST	Not Specified	03-Sep-1996
381	20218259	Iana Tama	M	POREBADA WEST	Not Specified	12-May-1995
382	20092275	Iana Hera Arere	M	POREBADA WEST	Clerk	29-Apr-1983
383	20092301	Iana Hera Charlie	M	POREBADA WEST	Security	29-Nov-1979
384	20003950	IDAU ARUA	M	POREBADA WEST	Unemployed	01-Jan-1987
385	20078632	Idau Arua Mea	M	POREBADA WEST	Security	20-Sep-1983
386	20087394	Idau Seri Maba	M	POREBADA WEST	Self Employed	17-Jan-1982
387	20073003	Igo Arere	M	POREBADA WEST	Self Employed	09-Jul-1984
388	20218260	Igo Chris	M	POREBADA WEST	Not Specified	27-Apr-2000
389	20124156	Igo Eguta Igo	M	POREBADA WEST	Self Employed	13-Oct-1985
390	20079167	Igo Heni Henry	M	POREBADA WEST	Subsistence Farmer	24-Jan-1953
391	20123427	Igo Igo	M	POREBADA WEST	Unemployed	19-Mar-1986
392	20124159	Igo Koani Arua	M	POREBADA WEST	Store Keeper	26-Mar-1979
393	20078999	Igo Lahui	M	POREBADA WEST	Self Employed	14-Aug-1982
394	20079000	Igo Lawrence	M	POREBADA WEST	Self Employed	01-Jan-1984
395	20131389	Igo Morea	M	POREBADA WEST	Self Employed	14-Aug-1957
396	20067967	Igo Morea Tele	M	POREBADA WEST	Self Employed	15-Mar-1985
397	20083659	Igo Raymond	M	POREBADA WEST	Self Employed	07-May-1979
398	20008713	IGO RIU	M	POREBADA WEST	Unemployed	01-Jan-1988
399	20123428	Igo Tarupa	M	POREBADA WEST	Worker	10-Apr-1988
400	20123429	Igo Tarupa	M	POREBADA WEST	Self Employed	14-Mar-1953
401	20023160	Igo Tom	M	POREBADA WEST	Student	21-Jun-1990
402	20054763	Igo Eguta Gau	M	POREBADA WEST	Unemployed	19-Oct-1969
403	20087413	Igo Koani Varuko	M	POREBADA WEST	Auditor	23-Mar-1984
404	20092687	Igo Rei Gau	M	POREBADA WEST	Subsistence Farmer	23-Nov-1975
405	20076604	Igo Siage Koru	M	POREBADA WEST	Self Employed	01-Jan-1951
406	20079172	Igo Siage Tolo	M	POREBADA WEST	Self Employed	28-Dec-1964
407	20054494	Igo Tolo Tolo	M	POREBADA WEST	Self Employed	27-May-1973
408	20081533	Igo Varuko Rapu	M	POREBADA WEST	Self Employed	24-Aug-1953
409	20094424	Igua Irua	M	POREBADA WEST	Subsistence Farmer	16-Sep-1972
410	20131420	Ikau Sioni	M	POREBADA WEST	Fisherman	10-Jun-1996
411	20006138	IKUPU AIHI	M	POREBADA WEST	Fisherman	25-May-1965
412	20085717	Ilagi Sisia	M	POREBADA WEST	Self Employed	25-Jun-1986
413	20085513	Ilagi Tapa	M	POREBADA WEST	Self Employed	15-Apr-1984
414	20087694	Imunu Jack	M	POREBADA WEST	Self Employed	24-Sep-1946
415	20083941	Imunu John	M	POREBADA WEST	Self Employed	01-Jan-1967
416	20083942	Imunu Lavi	M	POREBADA WEST	Self Employed	01-Jan-1967
417	20083665	Imunu Tau	M	POREBADA WEST	Self Employed	01-Jan-1978
418	20083944	Imunu Ugu	M	POREBADA WEST	Self Employed	01-Jan-1974
419	20004215	IOA MIRIA	M	POREBADA WEST	Unemployed	18-Mar-1989
420	20087692	Ioa Nelson	M	POREBADA WEST	Security	08-Aug-1972
421	20095003	Ioa Vada	M	POREBADA WEST	Subsistence Farmer	23-Apr-1981
422	20090396	Ioa Vagi	M	POREBADA WEST	Self Employed	30-Jan-1987
423	20218261	Irua Dabara	M	POREBADA WEST	Not Specified	09-Dec-2003
424	20218262	Irua Hitolo	M	POREBADA WEST	Not Specified	12-Apr-2002
425	20197990	Irua Igua	M	POREBADA WEST	Student	01-Jul-1998
426	20092596	Isaiah Oda	M	POREBADA WEST	Self Employed	31-Jan-1969
427	20022675	Isaiah Saimon	M	POREBADA WEST	Student	21-Jan-1993
428	20092392	Isaiah Vele	M	POREBADA WEST	Mechanic	17-Nov-1959
429	20083560	Isaiah Goata Goata	M	POREBADA WEST	Self Employed	09-Jul-1978
430	20078752	Isaiah Goata Lohia	M	POREBADA WEST	Self Employed	09-Apr-1981
431	20078996	Isaiah Goata Peter	M	POREBADA WEST	Self Employed	27-Apr-1987
432	20089846	Isaiah Oda Asi	M	POREBADA WEST	Self Employed	07-Sep-1970
433	20022389	Isaiah Oda Isaiah	M	POREBADA WEST	Self Employed	08-Feb-1991
434	20090395	Isaiah Oda Willie	M	POREBADA WEST	Self Employed	03-Sep-1979
435	20083945	Jack Arua	M	POREBADA WEST	Self Employed	18-Aug-1975
436	20081116	Jack Homoka	M	POREBADA WEST	Self Employed	09-Aug-1988
437	20087683	Jack Lega	M	POREBADA WEST	Teacher	21-Jan-1979
438	20083575	Jack Seri	M	POREBADA WEST	Banker	09-Apr-1981
439	20087679	Jack Sibona	M	POREBADA WEST	Self Employed	26-Oct-1976
440	20003394	JACK IMUNU LEGA JACK	M	POREBADA WEST	Teacher	21-Jan-1979
441	20197973	Jerom Gau	M	POREBADA WEST	Student	13-May-2000
442	20069564	Jnr Hera Gahusi	M	POREBADA WEST	Manager	12-Sep-1963
443	20218268	Joe Billy	M	POREBADA WEST	Not Specified	23-May-1997
444	20218269	Joe Francis	M	POREBADA WEST	Not Specified	05-Feb-1997
445	20006505	JOE SISIA	M	POREBADA WEST	Unemployed	01-Jan-1991
446	20218271	Joe Tony	M	POREBADA WEST	Not Specified	16-Sep-2002
447	20218272	John Aisi	M	POREBADA WEST	Not Specified	14-Jun-1997
448	20009467	JOHN DABARA	M	POREBADA WEST	Unemployed	01-Jan-1986
449	20009480	JOHN LOHIA	M	POREBADA WEST	Worker	01-Jan-1990
450	20009573	JOHN NAMAGU	M	POREBADA WEST	Unemployed	01-Jan-1984
451	20072514	John Oda	M	POREBADA WEST	Self Employed	27-Jun-1977
452	20218275	John Pala Isaiah	M	POREBADA WEST	Not Specified	26-Sep-1994
453	20092715	Kaekae Peter	M	POREBADA WEST	Self Employed	01-Jan-1961
454	20003873	KAIMA VANUA	M	POREBADA WEST	Business man	28-Apr-1967
455	20009448	KARUA BUSINA	M	POREBADA WEST	Student	01-Jan-1993
456	20031994	Karua Busina	M	POREBADA WEST	Self Employed	31-Aug-1982
457	20009440	KARUA DAMANI	M	POREBADA WEST	Unemployed	09-Jul-1990
458	20054298	Karua Busina Arua	M	POREBADA WEST	Self Employed	07-Dec-1986
459	20003645	KARUA SISIA TAUEDEA OA	M	POREBADA WEST	Worker	23-Aug-1975
460	20003648	KARUA WALO PETER	M	POREBADA WEST	Student	07-Apr-1991
461	20218278	Kauna Aihi	M	POREBADA WEST	Not Specified	02-Jul-2000
462	20094401	Kauna Gari	M	POREBADA WEST	Teacher	25-Oct-1955
463	20022403	Kauna Gau	M	POREBADA WEST	Self Employed	30-May-1989
464	20218279	Kauna Heni	M	POREBADA WEST	Not Specified	24-Aug-2003
465	20081140	Kauna Homoka	M	POREBADA WEST	Self Employed	27-Feb-1981
466	20218280	Kauna Kauna Moi	M	POREBADA WEST	Not Specified	02-Feb-1995
467	20081577	Kauna Kokoro	M	POREBADA WEST	Security	06-Jun-1967
468	20131342	Kauna Lohia	M	POREBADA WEST	Student	18-Aug-1998
469	20131361	Kauna Lohia	M	POREBADA WEST	Fisherman	16-Sep-1995
470	20218281	Kauna Russel	M	POREBADA WEST	Not Specified	21-Jul-1998
471	20218282	Kauna Gau David	M	POREBADA WEST	Not Specified	07-Jul-1995
472	20069648	Kauna Gau Homoka	M	POREBADA WEST	Self Employed	27-Feb-1981
473	20025211	Kauna Gau Kokoro	M	POREBADA WEST	Self Employed	13-Aug-1983
474	20218283	Kauna Gau Morea	M	POREBADA WEST	Not Specified	14-Mar-1994
475	20005016	KAUNA GAU RENAGI	M	POREBADA WEST	Self Employed	02-Mar-1991
476	20008723	KEITH LAHUI	M	POREBADA WEST	Student	01-Jan-1991
477	20008350	KEITH MOREA	M	POREBADA WEST	Student	01-Jan-1993
478	20087370	Kevau Arere	M	POREBADA WEST	Self Employed	01-Jan-1978
479	20051348	Kevau Igo	M	POREBADA WEST	Self Employed	05-Mar-1960
480	20054818	Kevau Arere Hitolo	M	POREBADA WEST	Pastor	02-Aug-1972
481	20124855	Kila Fabian	M	POREBADA WEST	Student	03-Dec-1998
482	20218285	Kila Jimmy	M	POREBADA WEST	Not Specified	17-Jan-1987
483	20089790	Kila Saufa	M	POREBADA WEST	Subsistence Farmer	01-Jan-1963
484	20084083	Kinawi Emmanuel	M	POREBADA WEST	Worker	01-Jan-1972
485	20023637	Koani Arua	M	POREBADA WEST	Subsistence Farmer	19-Jul-1969
486	20094514	Koani Mea	M	POREBADA WEST	Worker	01-Jun-2000
487	20089913	Koani Wayne Igo	M	POREBADA WEST	Clerk	31-May-1957
488	20009508	KOANI BARU ASI	M	POREBADA WEST	Worker	14-Aug-1987
489	20009345	Koani Baru Baru	M	POREBADA WEST	Worker	19-Feb-1991
490	20072890	Koani Igo Tara	M	POREBADA WEST	Self Employed	17-Nov-1983
491	20050678	Kohu Hera	M	POREBADA WEST	Store Keeper	05-Jul-1983
492	20054205	Kohu Simon  Jnr	M	POREBADA WEST	Mechanic	13-Dec-1983
493	20092321	Kohu Simon  Snr	M	POREBADA WEST	Self Employed	06-Jun-1974
494	20197992	Kohu Tauedel	M	POREBADA WEST	Unemployed	20-Jul-2000
495	20033461	Kohu Gaudi Gorogo	M	POREBADA WEST	Subsistence Farmer	01-Jan-1976
496	20034641	Kohu Gaudi Koani	M	POREBADA WEST	Self Employed	01-Jan-1972
497	20035422	Kohu Gaudi Morea	M	POREBADA WEST	Self Employed	01-Jan-1985
498	20085724	Koita Maraga	M	POREBADA WEST	Subsistence Farmer	29-Jun-1978
499	20092280	Koita Kovea Gau	M	POREBADA WEST	Self Employed	14-Jan-1975
500	20092281	Koita Kovea Rohi	M	POREBADA WEST	Self Employed	20-Oct-1978
501	20081417	Kokoro Gau	M	POREBADA WEST	Self Employed	02-Jan-2000
502	20083545	Kokoro Morea	M	POREBADA WEST	Self Employed	02-Jan-2000
503	20092730	Kokoro Homoka Homoka	M	POREBADA WEST	Self Employed	03-Sep-1983
504	20123450	Koru Ige Toea	M	POREBADA WEST	Self Employed	02-Mar-1972
505	20054191	Kovae Dairi	M	POREBADA WEST	Self Employed	01-Jan-1965
506	20123451	Kovae Mea	M	POREBADA WEST	Self Employed	29-Sep-1958
507	20033544	Kovae Seri Homoka	M	POREBADA WEST	Subsistence Farmer	14-Oct-1978
508	20079060	Kovea Maba	M	POREBADA WEST	Self Employed	02-Jan-2000
509	20092813	Kovea Kauna Audabi	M	POREBADA WEST	Self Employed	01-Jan-1945
510	20033779	Kovea Kauna Koita	M	POREBADA WEST	Subsistence Farmer	02-Jan-2000
511	20092790	Kovea Kauna Nono	M	POREBADA WEST	Self Employed	01-Jan-1958
512	20033589	Kovea Kauna Walo	M	POREBADA WEST	Subsistence Farmer	15-Mar-1930
513	20076547	Lahui Allan	M	POREBADA WEST	Subsistence Farmer	13-Mar-1983
514	20008500	LAHUI KEITH	M	POREBADA WEST	Worker	01-Jan-1968
515	20218292	Lahui Lohia	M	POREBADA WEST	Not Specified	05-Mar-2004
516	20218293	Lahui Taumaku	M	POREBADA WEST	Not Specified	05-Feb-2001
517	20085502	Lahui Igo Gau	M	POREBADA WEST	Self Employed	05-May-1973
518	20218294	Lahui Karoho Karoho	M	POREBADA WEST	Not Specified	02-Nov-1999
519	20034244	Lahui Morea Asi	M	POREBADA WEST	Self Employed	13-Jun-1970
520	20005164	LAHUI MOREA GAHUSI	M	POREBADA WEST	Self Employed	01-Jan-1956
521	20218295	Lahui Morea Isaiah	M	POREBADA WEST	Not Specified	02-Aug-1992
522	20033852	Lahui Morea Joe	M	POREBADA WEST	Self Employed	23-Sep-1975
523	20218297	Lenda Jeremaiah	M	POREBADA WEST	Not Specified	15-May-1983
524	20054249	Loa Busina	M	POREBADA WEST	Self Employed	17-Sep-1982
525	20056641	Loa Madi	M	POREBADA WEST	Subsistence Farmer	20-May-1944
526	20087392	Lohia Busina	M	POREBADA WEST	Clerk	05-Jan-1966
527	20218299	Lohia Heagi	M	POREBADA WEST	Not Specified	11-Nov-1989
528	20218300	Lohia Hitolo Sauga	M	POREBADA WEST	Not Specified	28-Dec-2000
529	20123455	Lohia Homoka	M	POREBADA WEST	Subsistence Farmer	07-Oct-1933
530	20106208	Lohia Koani	M	POREBADA WEST	Self Employed	18-Aug-1989
531	20081576	Lohia Koani M	M	POREBADA WEST	Self Employed	14-May-1970
532	20051168	Lohia Maraga	M	POREBADA WEST	Clerk	14-Jun-1973
533	20085726	Lohia Nohokau	M	POREBADA WEST	Clerk	18-Mar-1963
534	20004601	LOHIA ARUA TAUMAKU	M	POREBADA WEST	Student	03-Aug-1992
535	20009494	LOHIA BEN JIMMY	M	POREBADA WEST	Carpenter	20-Jul-1990
536	20085713	Lohia Bodibo Bodibo	M	POREBADA WEST	Student	21-Aug-1988
537	20085735	Lohia Bodibo Maraga	M	POREBADA WEST	Student	25-Mar-1986
538	20022382	Lohia G Homoka	M	POREBADA WEST	Fisherman	07-Apr-1990
539	20090329	Lohia Havata Jim	M	POREBADA WEST	Clerk	09-Sep-1952
540	20218302	Lohia havata Morea	M	POREBADA WEST	Not Specified	13-Aug-1962
541	20051149	Lohia Heagi Homoka	M	POREBADA WEST	Subsistence Farmer	01-Jan-1976
542	20051142	Lohia Heagi Morea	M	POREBADA WEST	Self Employed	20-Jan-1977
543	20004566	LOHIA HEAGI RANU	M	POREBADA WEST	Self Employed	04-Sep-1980
544	20050673	Lohia Heagi Ranu	M	POREBADA WEST	Subsistence Farmer	01-Jan-1974
545	20076438	Lohia Maraga Busina	M	POREBADA WEST	Subsistence Farmer	10-Apr-1965
546	20034363	Lohia Morea John	M	POREBADA WEST	Self Employed	27-Nov-1987
547	20022432	Lohia Peter Billy	M	POREBADA WEST	Self Employed	01-May-1991
548	20035417	Lohia Peter Peter	M	POREBADA WEST	Self Employed	16-Jan-1985
549	20003898	LOHIA SIMON KOANI	M	POREBADA WEST	Student	09-Sep-1993
550	20090467	Lohia Taumaku Koani	M	POREBADA WEST	Student	29-Apr-1985
551	20218304	Lohia Taumaku Seri	M	POREBADA WEST	Not Specified	20-Apr-1995
552	20090465	Lohia Taumaku Taumaku	M	POREBADA WEST	Self Employed	07-Mar-1984
553	20218306	Loke Edward	M	POREBADA WEST	Not Specified	16-Sep-1975
554	20008232	MABA ARUA SALUA	M	POREBADA WEST	Student	14-Nov-1989
555	20218308	Maba Derek	M	POREBADA WEST	Not Specified	22-May-2000
556	20008738	Maba Riu	M	POREBADA WEST	Clerk	23-Oct-1990
557	20079055	Maba Tana	M	POREBADA WEST	Self Employed	01-Jan-1960
558	20035513	Maba Kovea Heagi	M	POREBADA WEST	Teacher	13-Sep-1967
559	20092692	Maba Kovea Morea	M	POREBADA WEST	Self Employed	28-Feb-1973
560	20054496	Madi Ginate	M	POREBADA WEST	Student	13-Oct-1986
561	20064277	Mako Aua	M	POREBADA WEST	Self Employed	21-Apr-1984
562	20005027	MAKO AUA GAU	M	POREBADA WEST	Fisherman	28-Aug-1989
563	20087395	Mali Manape	M	POREBADA WEST	Self Employed	08-Oct-1984
564	20007141	MALI SERI	M	POREBADA WEST	Student	10-Jun-1993
565	20085727	Maraga Arere	M	POREBADA WEST	Subsistence Farmer	04-May-1978
566	20034638	Maraga Gaudi	M	POREBADA WEST	Self Employed	01-Jan-1984
567	20072568	Maraga Anai Morea	M	POREBADA WEST	Clerk	12-Dec-1958
568	20094400	Maraga Miki Kauna	M	POREBADA WEST	Self Employed	02-Jan-2000
569	20022381	Marita Stanley	M	POREBADA WEST	Self Employed	01-Jul-1953
570	20009410	MATAIO RAKATANI TAUMAKU	M	POREBADA WEST	Villager	02-Feb-2000
571	20002523	MATAIO TAU RAKATANI	M	POREBADA WEST	Villager	22-Feb-1944
572	20031932	Mea Arua	M	POREBADA WEST	Self Employed	01-Jan-1981
573	20094907	Mea Guba	M	POREBADA WEST	Supervisor	10-Dec-1976
574	20094348	Mea Koani	M	POREBADA WEST	Worker	09-Sep-1979
575	20094402	Mea Patrick	M	POREBADA WEST	Student	23-Jul-1985
576	20008257	MEA RAKA	M	POREBADA WEST	Unemployed	01-Jan-1991
577	20130937	Mea Taumaku	M	POREBADA WEST	Fisherman	23-Mar-1995
578	20076099	Mea Veri	M	POREBADA WEST	Self Employed	28-Jun-1986
579	20067976	Mea Arua Lohia	M	POREBADA WEST	Self Employed	12-Oct-1983
580	20069280	Mea Arua Raymond	M	POREBADA WEST	Self Employed	21-Nov-1985
581	20218312	Mea Baru Vagi	M	POREBADA WEST	Not Specified	15-Feb-1999
582	20094512	Mea Koani Morea	M	POREBADA WEST	Self Employed	01-Nov-1984
583	20072526	Mea Kovae Gari	M	POREBADA WEST	Self Employed	04-Jun-1982
584	20218313	Meia Dairi	M	POREBADA WEST	Not Specified	15-Jul-1997
585	20092739	Miki Rakatani  Jnr	M	POREBADA WEST	Subsistence Farmer	15-May-1986
586	20092731	Miki Rakatani  Snr	M	POREBADA WEST	Self Employed	01-Aug-2000
587	20009358	MIKI HENI KOANI	M	POREBADA WEST	Store Keeper	08-Jul-1991
588	20090401	Moia Dabara	M	POREBADA WEST	Self Employed	21-Feb-1975
589	20083585	Moia Gavera	M	POREBADA WEST	Self Employed	31-May-1979
590	20081592	Moia George	M	POREBADA WEST	Student	11-Jul-1989
591	20090394	Moia Oa	M	POREBADA WEST	Self Employed	27-Jul-1977
592	20076575	Momoru Dadami	M	POREBADA WEST	Self Employed	25-Apr-1966
593	20078982	Momoru Igo	M	POREBADA WEST	Self Employed	01-Jan-1956
594	20022355	Momoru Ioa	M	POREBADA WEST	Unemployed	26-Dec-1990
595	20076564	Momoru Karua	M	POREBADA WEST	Self Employed	08-Mar-1973
596	20124848	Momoru Oda	M	POREBADA WEST	Teacher	02-Mar-1979
597	20218315	Momoru Oda	M	POREBADA WEST	Not Specified	17-May-2000
598	20218316	Momoru Siage	M	POREBADA WEST	Not Specified	20-Aug-2000
599	20032650	Momoru Oda Peter	M	POREBADA WEST	Self Employed	12-Aug-1987
600	20004576	MOMORU TABE DAERA	M	POREBADA WEST	Worker	12-Nov-1988
601	20197981	Morea Arere	M	POREBADA WEST	Unemployed	10-Mar-1973
602	20124193	Morea Arua Tauedea	M	POREBADA WEST	Subsistence Farmer	07-Jun-1982
603	20064769	Morea Aua	M	POREBADA WEST	Self Employed	23-May-1983
604	20079013	Morea Auani	M	POREBADA WEST	Self Employed	01-Jan-1977
605	20054755	Morea Dogodo Igua	M	POREBADA WEST	Self Employed	22-Aug-1978
606	20081411	Morea Gari	M	POREBADA WEST	Self Employed	03-Jul-1970
607	20076735	Morea Gau	M	POREBADA WEST	Self Employed	01-Jan-1985
608	20081118	Morea Gure	M	POREBADA WEST	Self Employed	30-Aug-1977
609	20124198	Morea Igo Lesi	M	POREBADA WEST	Worker	01-Jan-1977
610	20218317	Morea Jambram	M	POREBADA WEST	Not Specified	01-Feb-2002
611	20197980	Morea Jerome	M	POREBADA WEST	Unemployed	15-Jan-1998
612	20076137	Morea John	M	POREBADA WEST	Self Employed	12-Jun-1955
613	20218318	Morea Joshua	M	POREBADA WEST	Not Specified	30-Oct-2000
614	20124199	Morea Kokoro Mea	M	POREBADA WEST	Fisherman	12-Mar-1965
615	20004697	MOREA LOHIA	M	POREBADA WEST	Worker	18-Nov-1985
616	20023228	Morea Lohia	M	POREBADA WEST	Student	24-Sep-1986
617	20085515	Morea Maba	M	POREBADA WEST	Clerk	25-Oct-1964
618	20059410	Morea Morea	M	POREBADA WEST	Policeman	04-Jul-1975
619	20124201	Morea Morea Tara	M	POREBADA WEST	Self Employed	01-Jan-1988
620	20090323	Morea Oda Paul	M	POREBADA WEST	Student	05-Oct-1984
621	20050676	Morea Ravu	M	POREBADA WEST	Self Employed	07-Dec-1975
622	20092812	Morea Rea	M	POREBADA WEST	Self Employed	18-Mar-1968
623	20124818	Morea Riu	M	POREBADA WEST	Clerk	28-Feb-1985
624	20092719	Morea Simon	M	POREBADA WEST	Mechanic	13-Jun-1982
625	20130927	Morea Simon	M	POREBADA WEST	Fisherman	12-May-1979
626	20124204	Morea Simona Dairi	M	POREBADA WEST	Self Employed	02-Jul-1978
627	20051349	Morea Sisia	M	POREBADA WEST	Worker	08-Apr-1957
628	20088165	Morea Tara	M	POREBADA WEST	Self Employed	16-Jul-1971
629	20124205	Morea Tauedea Gorogo	M	POREBADA WEST	Subsistence Farmer	17-Oct-1958
630	20073007	Morea Taumaku	M	POREBADA WEST	Self Employed	24-Jul-1973
631	20123481	Morea Taumaku	M	POREBADA WEST	Worker	13-Feb-1983
632	20007463	MOREA THOMAS	M	POREBADA WEST	Unemployed	01-Jan-1991
633	20076729	Morea Vagi	M	POREBADA WEST	Self Employed	01-Jan-1987
634	20094744	Morea Varuko	M	POREBADA WEST	Subsistence Farmer	15-Jul-1977
635	20004147	MOREA ARUA PAUL	M	POREBADA WEST	Worker	13-May-1991
636	20002937	MOREA ARUA THOMAS	M	POREBADA WEST	Contractor	15-Jul-1991
637	20031426	Morea Arua Vagi	M	POREBADA WEST	Self Employed	30-Nov-1986
638	20022692	Morea Baru Baru	M	POREBADA WEST	Self Employed	23-Oct-1987
639	20034157	Morea Dairi Lohia	M	POREBADA WEST	Self Employed	01-Jan-1962
640	20058869	Morea Dairi Morea	M	POREBADA WEST	Self Employed	01-Jan-1966
641	20032474	Morea Dairi Keni Lohia	M	POREBADA WEST	Self Employed	12-Mar-1957
642	20003650	MOREA GAHUSI BITU	M	POREBADA WEST	Subsistence Farmer	20-Sep-1990
643	20003409	MOREA GAHUSI LENI	M	POREBADA WEST	Student	12-Aug-1993
644	20087698	Morea Gau Baru	M	POREBADA WEST	Clerk	01-Apr-1971
645	20064300	Morea Gau Raka	M	POREBADA WEST	Self Employed	01-Aug-1983
646	20064309	Morea Gorogo Ipi	M	POREBADA WEST	Self Employed	26-May-1972
647	20064305	Morea Gorogo Riu	M	POREBADA WEST	Subsistence Farmer	18-Jun-1976
648	20067600	Morea Heagi Baru	M	POREBADA WEST	Seaman	03-Aug-1979
649	20003957	MOREA HEAGI GAVERA	M	POREBADA WEST	Student	20-Nov-1992
650	20064668	Morea Heagi Heagi Jnr	M	POREBADA WEST	Subsistence Farmer	01-Mar-1988
651	20089840	Morea Heagi Heagi Snr	M	POREBADA WEST	Mechanic	01-Jan-1964
652	20054196	Morea Heagi Igo	M	POREBADA WEST	Self Employed	15-May-1986
653	20054199	Morea Heagi Tara	M	POREBADA WEST	Subsistence Farmer	17-Jul-1971
654	20061891	Morea Hitolo Hitolo	M	POREBADA WEST	Self Employed	18-Dec-1974
655	20081537	Morea Igo Varuko	M	POREBADA WEST	Self Employed	08-Jan-1987
656	20218324	Morea Jack Jack	M	POREBADA WEST	Not Specified	01-Jan-1992
657	20076453	Morea John Dairi	M	POREBADA WEST	Subsistence Farmer	01-Jan-1952
658	20007577	MOREA KOI BITU	M	POREBADA WEST	Fisherman	19-Sep-1990
659	20085505	Morea Koi Gari	M	POREBADA WEST	Self Employed	03-Oct-1987
660	20087700	Morea Koi Hitolo	M	POREBADA WEST	Self Employed	24-Jun-1984
661	20218325	Morea Kokoro Gau	M	POREBADA WEST	Not Specified	06-May-1987
662	20076467	Morea Maraga Hitolo	M	POREBADA WEST	Student	26-Aug-1987
663	20072561	Morea Maraga Karoho	M	POREBADA WEST	Self Employed	21-Nov-1982
664	20005040	MOREA MEA HITOLO	M	POREBADA WEST	Unemployed	13-Apr-1978
665	20094416	Morea Morea Lohia	M	POREBADA WEST	Student	01-Jan-1986
666	20005508	MOREA NONO VAGI	M	POREBADA WEST	Self Employed	09-May-1989
667	20089864	Morea Ray Aquila	M	POREBADA WEST	Self Employed	01-Jan-1982
668	20025742	Morea Ray Ray	M	POREBADA WEST	Clerk	01-Jan-1969
669	20079097	Morea Tabe Goata	M	POREBADA WEST	Self Employed	11-Aug-1964
670	20218326	Morea Tara Andy	M	POREBADA WEST	Not Specified	08-Dec-1994
671	20076407	Morea Tauedea Heau	M	POREBADA WEST	Self Employed	28-Jan-1966
672	20092721	Morea Taumaku Anai	M	POREBADA WEST	Self Employed	21-Mar-1986
673	20218328	Morea Taumaku Baru	M	POREBADA WEST	Not Specified	28-Sep-1981
674	20090446	Morea Taumaku Lohia	M	POREBADA WEST	Self Employed	13-Jul-1976
675	20019026	Morea Taumaku Taumaku	M	POREBADA WEST	Fisherman	01-Jan-1980
676	20090447	Morea Taumaku Vaburi	M	POREBADA WEST	Security	13-Jan-1979
677	20022406	Naime Hera	M	POREBADA WEST	Student	05-Jan-1991
678	20130968	Naime Hitolo	M	POREBADA WEST	Student	27-Jan-1997
679	20123487	NANAI GABAHO	M	POREBADA WEST	Not Specified	08-Jan-1973
680	20123488	NANAI VARUKO	M	POREBADA WEST	Not Specified	20-Feb-1979
681	20023633	Noho Thomas	M	POREBADA WEST	Driver	05-May-1958
682	20124817	Nohokau Arere	M	POREBADA WEST	Fisherman	06-Sep-1998
683	20197965	Nohokau Arere	M	POREBADA WEST	Worker	06-Sep-1998
684	20062547	Nohokau Arua	M	POREBADA WEST	Self Employed	07-Jul-1978
685	20088139	Nohokau Gahusi	M	POREBADA WEST	Self Employed	10-Jun-1984
686	20218330	Nohokau Hitolo	M	POREBADA WEST	Not Specified	26-Jul-2001
687	20131334	Nohokau Igo	M	POREBADA WEST	Driver	24-Feb-1987
688	20072963	Nohokau Karoho	M	POREBADA WEST	Student	02-Sep-1982
689	20087713	Nohokau Lohia	M	POREBADA WEST	Clerk	13-Dec-1982
690	20131335	Nohokau Morea	M	POREBADA WEST	Fisherman	18-Jul-1995
691	20131387	Nono Bua	M	POREBADA WEST	Student	10-Aug-1998
692	20054248	Nono Hegora John	M	POREBADA WEST	Self Employed	14-Mar-1955
693	20131381	Nono Maba	M	POREBADA WEST	Security	15-Jun-1964
694	20092276	Nono Kovea Hitolo	M	POREBADA WEST	Self Employed	26-Oct-1979
695	20092794	Nono Kovea Koita	M	POREBADA WEST	Self Employed	01-Jan-1982
696	20092742	Nono Kovea Manu	M	POREBADA WEST	Self Employed	01-Apr-1987
697	20002542	NONO KOVEA MOREA	M	POREBADA WEST	Driver	16-Mar-1961
698	20092329	Oa Homoka	M	POREBADA WEST	Self Employed	16-Sep-1972
699	20006234	OA JOHN	M	POREBADA WEST	Worker	17-Oct-1964
700	20031834	Oa Meauri	M	POREBADA WEST	Clerk	01-Jan-1950
701	20087697	Oa Moia	M	POREBADA WEST	Self Employed	14-Dec-1952
702	20092389	Oa Raka	M	POREBADA WEST	Soldier	17-Jul-1977
703	20092324	Oa Richard	M	POREBADA WEST	Self Employed	19-Aug-1975
704	20092314	Oa Robert	M	POREBADA WEST	Self Employed	29-Jul-1982
705	20022689	Oa Seri	M	POREBADA WEST	Self Employed	02-Dec-1990
706	20085494	Oda David	M	POREBADA WEST	Self Employed	05-Apr-1978
707	20131385	Oda Gorogo	M	POREBADA WEST	Fisherman	04-Aug-1995
708	20085493	Oda Inara	M	POREBADA WEST	Self Employed	21-Mar-1980
709	20218333	Oda Lohia	M	POREBADA WEST	Not Specified	14-Jan-2003
710	20085709	Oda Mea	M	POREBADA WEST	Self Employed	06-May-1987
711	20054811	Oda Patrick	M	POREBADA WEST	Self Employed	05-Aug-1985
712	20131388	Oda Tauedea	M	POREBADA WEST	Fisherman	09-Nov-1990
713	20087402	Oda Vele Joshua	M	POREBADA WEST	Student	01-Jan-1988
714	20056529	Oda Baru Tau	M	POREBADA WEST	Self Employed	09-Apr-1980
715	20019014	Oda Lohia Morea	M	POREBADA WEST	Self Employed	10-Oct-1989
716	20092360	Oda Rei Hitolo	M	POREBADA WEST	Self Employed	08-Dec-1981
717	20005173	OVA GOASA GUNI	M	POREBADA WEST	Fisherman	07-Oct-1992
718	20006146	OVA KAUNA KAUNA	M	POREBADA WEST	Worker	01-Jan-1972
719	20094419	Pala Edward	M	POREBADA WEST	Student	01-Jan-1983
720	20092713	Pala Gari	M	POREBADA WEST	Teacher	12-Oct-1973
721	20094428	Pala John	M	POREBADA WEST	Subsistence Farmer	01-Jan-1959
722	20123500	Pala John Jnr	M	POREBADA WEST	Student	01-Jan-1988
723	20218335	Pala Kevin	M	POREBADA WEST	Not Specified	13-Dec-2002
724	20131353	Pala Kila	M	POREBADA WEST	Carpenter	10-Jun-1959
725	20022410	Pala Robin	M	POREBADA WEST	Self Employed	20-Feb-1992
726	20054270	Parakis Lus	M	POREBADA WEST	Student	01-Jun-1987
727	20054268	Parakis Mathew	M	POREBADA WEST	Teacher	04-Jan-1957
728	20054287	Parakis Ramsey	M	POREBADA WEST	Student	29-Jun-1984
729	20218340	Peter Ahuta	M	POREBADA WEST	Not Specified	01-Nov-1963
730	20001463	PETER JOHN	M	POREBADA WEST	Unemployed	19-May-1991
731	20131398	Peter Kailo	M	POREBADA WEST	Student	08-May-1998
732	20218341	Peter Lahui	M	POREBADA WEST	Not Specified	10-Jul-2003
733	20092718	Peter Natali	M	POREBADA WEST	Security	01-Jan-1981
734	20033846	Peter Lohia Lohia	M	POREBADA WEST	Clerk	15-Nov-1960
735	20056512	Pune Gure	M	POREBADA WEST	Seaman	01-Jan-1960
736	20054784	Pune Morea	M	POREBADA WEST	Self Employed	02-Jun-1968
737	20054812	Pune Taumaku	M	POREBADA WEST	Self Employed	01-Jan-1971
738	20085707	Ragana Bitu	M	POREBADA WEST	Self Employed	01-Jan-1986
739	20003340	RAGANA LEVA	M	POREBADA WEST	Student	07-Sep-1992
740	20085738	Ragana Pala	M	POREBADA WEST	Self Employed	01-Jan-1984
741	20085510	Ragana Rigo	M	POREBADA WEST	Self Employed	16-Jun-1982
742	20088143	Ragana Taravatu	M	POREBADA WEST	Self Employed	21-Nov-1979
743	20087701	Ragana Vagi	M	POREBADA WEST	Self Employed	29-Sep-1977
744	20090316	Ragu Ite	M	POREBADA WEST	Self Employed	09-Jun-1975
745	20218343	Raka Sioni	M	POREBADA WEST	Not Specified	24-Feb-1983
746	20130952	Raka Stanley	M	POREBADA WEST	Bricklayer	05-Mar-1993
747	20054198	Raka Toea	M	POREBADA WEST	Self Employed	26-Sep-1972
748	20089764	Raka I Sioni Morea	M	POREBADA WEST	Clerk	27-Jun-1972
749	20123509	Rakagau Gau	M	POREBADA WEST	Self Employed	09-Oct-1968
750	20064774	Rakatani Bodibo	M	POREBADA WEST	Self Employed	15-May-1953
751	20064670	Rakatani Dorido	M	POREBADA WEST	Self Employed	20-Sep-1961
752	20064480	Rakatani Hitolo	M	POREBADA WEST	Self Employed	01-Jan-1967
753	20083702	Rakatani Pilu	M	POREBADA WEST	Self Employed	26-Feb-1981
754	20064950	Rakatani Richard	M	POREBADA WEST	Policeman	01-Mar-1972
755	20081437	Rakatani Soni	M	POREBADA WEST	Self Employed	02-Apr-1972
756	20218346	Rakatani Helai Goata	M	POREBADA WEST	Not Specified	22-May-1995
757	20067613	Rakatani Helai Morea	M	POREBADA WEST	Self Employed	17-Sep-1988
758	20005180	RAKATANI HENRY HENRY	M	POREBADA WEST	Student	10-Oct-1993
759	20094540	Rakatani Mataio Mataio	M	POREBADA WEST	Self Employed	21-Jan-1975
760	20094532	Rakatani Mataio Seri	M	POREBADA WEST	Self Employed	07-Jul-1977
761	20090475	Rakatani Miki Asigau	M	POREBADA WEST	Self Employed	14-Jan-1982
762	20092733	Rakatani Miki Gahusi	M	POREBADA WEST	Mechanic	14-Jun-1979
763	20090391	Rakatani Miki Kailo	M	POREBADA WEST	Student	17-Oct-1988
764	20092380	Rakatani Miki Peter	M	POREBADA WEST	Self Employed	16-Jan-1978
765	20106231	Ranu Heagi Heagi	M	POREBADA WEST	Security	15-May-1972
766	20068076	Ray Igo	M	POREBADA WEST	Worker	27-Apr-1956
767	20089845	Ray Peter	M	POREBADA WEST	Technician	01-Jan-1972
768	20130973	Ray Sigi	M	POREBADA WEST	Student	26-Sep-1998
769	20092373	Ray Havata Morea	M	POREBADA WEST	Self Employed	01-Oct-2000
770	20004577	RAY HENI GERRY	M	POREBADA WEST	Self Employed	29-Jul-1993
771	20004609	RAY HENI HEAGI	M	POREBADA WEST	Self Employed	08-Aug-1989
772	20004241	RAY MOREA PHILEMON	M	POREBADA WEST	Student	19-Jan-1994
773	20124213	Raymond Arua Raka	M	POREBADA WEST	Contractor	03-Nov-1990
774	20131369	Raymond Mea	M	POREBADA WEST	Driver	07-May-1982
775	20124929	Rea Morea	M	POREBADA WEST	Fisherman	28-Sep-1995
776	20090261	Rei Oda	M	POREBADA WEST	Self Employed	16-Feb-1954
777	20218348	Richard Rakatani	M	POREBADA WEST	Not Specified	28-Sep-2001
778	20218349	Richard Tombaike	M	POREBADA WEST	Not Specified	05-Feb-2003
779	20218350	Riu Baru	M	POREBADA WEST	Not Specified	03-Jun-1998
780	20088144	Riu Gari	M	POREBADA WEST	Security	04-Aug-1959
781	20036021	Riu Gau Arua	M	POREBADA WEST	Self Employed	01-Jan-1975
782	20076480	Riu Heagi Gau	M	POREBADA WEST	Self Employed	01-Jan-1963
783	20072995	Riu Heagi Heagi	M	POREBADA WEST	Subsistence Farmer	01-Jan-1957
784	20076408	Riu Heagi Igo	M	POREBADA WEST	Self Employed	01-Jan-1961
785	20079094	Romano Kila	M	POREBADA WEST	Self Employed	05-Jul-1984
786	20058991	Rosi Heni	M	POREBADA WEST	Subsistence Farmer	01-Feb-1976
787	20058993	Rosi Hera	M	POREBADA WEST	Self Employed	14-Jul-1972
788	20057202	Rosi Homo	M	POREBADA WEST	Self Employed	15-Jan-1978
789	20058860	Rosi Kohu	M	POREBADA WEST	Self Employed	25-Mar-1974
790	20058861	Rosi Sisia	M	POREBADA WEST	Self Employed	19-Mar-1970
791	20036193	Rua Gadei	M	POREBADA WEST	Teacher	01-Jan-1980
792	20218353	Rua Ruben	M	POREBADA WEST	Not Specified	02-Oct-2002
793	20064771	Rui Morea Riu	M	POREBADA WEST	Self Employed	05-Dec-1984
794	20089759	Ruma Sioni	M	POREBADA WEST	Student	10-Jun-1986
795	20035509	Sabadi Gill	M	POREBADA WEST	Clerk	01-Aug-1973
796	20036694	Sagap Karua	M	POREBADA WEST	Self Employed	01-Jan-1989
797	20054197	Sagap Teddy	M	POREBADA WEST	Security	05-Jul-1975
798	20007259	SAILOR PETER	M	POREBADA WEST	Unemployed	10-Oct-1988
799	20092317	Saini Baru	M	POREBADA WEST	Subsistence Farmer	13-Jun-1988
800	20087400	Saini Morea Andrew	M	POREBADA WEST	Subsistence Farmer	15-Aug-1980
801	20005162	SAMUEL AREBO	M	POREBADA WEST	Student	31-Dec-1992
802	20130748	Sarea Igo Rabu	M	POREBADA WEST	Worker	26-Sep-1994
803	20090402	Seri Arere	M	POREBADA WEST	Self Employed	01-Jan-1964
804	20131337	Seri Arere	M	POREBADA WEST	Peace Officer	15-Aug-1964
805	20078629	Seri Asi	M	POREBADA WEST	Self Employed	31-Dec-1982
806	20008731	SERI BODIBO	M	POREBADA WEST	Student	01-Jan-1993
807	20089855	Seri Gau	M	POREBADA WEST	Self Employed	21-Sep-1972
808	20069538	Seri Homoka	M	POREBADA WEST	Salesman	21-Oct-1942
809	20085469	Seri Jack	M	POREBADA WEST	Student	10-Mar-1986
810	20089854	Seri Koani	M	POREBADA WEST	Self Employed	01-Jan-1969
811	20218357	Seri Vaburi	M	POREBADA WEST	Not Specified	13-Mar-1998
812	20088166	Seri Arere Vagi	M	POREBADA WEST	Self Employed	01-Jan-1959
813	20218358	Seri Asi Igo	M	POREBADA WEST	Not Specified	23-Oct-1978
814	20003872	SERI ASI PETER	M	POREBADA WEST	Self Employed	12-Feb-1990
815	20033834	Seri Bitu Kovae	M	POREBADA WEST	Subsistence Farmer	16-Apr-1952
816	20069674	Seri Bitu Vagi	M	POREBADA WEST	Self Employed	13-Mar-1962
817	20073004	Siage Lohia	M	POREBADA WEST	Clerk	01-Jan-1967
818	20072998	Siage Momoru	M	POREBADA WEST	Mechanic	01-Jan-1973
819	20076123	Siage Morea	M	POREBADA WEST	Self Employed	01-Jul-1963
820	20031790	Siage Loa Arua	M	POREBADA WEST	Self Employed	01-Jan-1958
821	20218359	Sibo Sisia	M	POREBADA WEST	Not Specified	14-Apr-1995
822	20094410	Simon Gau	M	POREBADA WEST	Pastor	01-Jan-1953
823	20051337	Simon Gaudi	M	POREBADA WEST	Self Employed	02-Feb-1959
824	20129894	Simon Isaiah	M	POREBADA WEST	Not Specified	24-May-1997
825	20054215	Simon Kohu	M	POREBADA WEST	Self Employed	21-Mar-1963
826	20076481	Simon Lohia	M	POREBADA WEST	Electrician	18-Jan-1965
827	20094486	Simon Morea	M	POREBADA WEST	Self Employed	28-Feb-1948
828	20031822	Simon Kohu Ovia	M	POREBADA WEST	Subsistence Farmer	02-Jan-2000
829	20045626	Simon Lohia Lohia	M	POREBADA WEST	Self Employed	20-May-1977
830	20002828	SIMON LOHIA TAU	M	POREBADA WEST	Unemployed	31-Jan-1988
831	20059393	Sioni Gau	M	POREBADA WEST	Self Employed	28-Aug-1988
832	20004506	SIONI HITOLO	M	POREBADA WEST	Fisherman	11-Jun-1992
833	20076603	Sioni Igo	M	POREBADA WEST	Subsistence Farmer	01-Jan-1982
834	20067958	Sioni Ikau	M	POREBADA WEST	Self Employed	01-Jan-1964
835	20088162	Sioni Baru Riu	M	POREBADA WEST	Self Employed	19-Jun-1973
836	20005157	SISIA K AUDABI	M	POREBADA WEST	Self Employed	27-Jul-1990
837	20033002	Sisia Kovea Audabi	M	POREBADA WEST	Self Employed	21-Jun-1981
838	20005151	SISIA MOREA GURE	M	POREBADA WEST	Worker	07-Apr-1985
839	20218360	Soge David	M	POREBADA WEST	Not Specified	16-May-2001
840	20131433	Sony Doura	M	POREBADA WEST	Student	07-May-1998
841	20131305	Soso Albert	M	POREBADA WEST	Worker	11-Sep-1968
842	20017844	Stanley Keith	M	POREBADA WEST	Self Employed	04-Nov-1990
843	20197964	Tabe Tabe	M	POREBADA WEST	Student	30-May-1999
844	20032616	Tabe Henry Goasa	M	POREBADA WEST	Self Employed	01-Jan-1988
845	20032068	Tabe Henry Taumaku	M	POREBADA WEST	Household Duties	01-Jan-1981
846	20025476	Tana Wari	M	POREBADA WEST	Self Employed	12-Mar-1979
847	20057189	Tapa Arere	M	POREBADA WEST	Self Employed	17-Jul-1984
848	20056778	Tapa Willie	M	POREBADA WEST	Self Employed	20-Nov-1977
849	20072960	Tara Arua	M	POREBADA WEST	Subsistence Farmer	04-May-1985
850	20081408	Tara Barry	M	POREBADA WEST	Self Employed	18-Aug-1984
851	20078987	Tara Dimere	M	POREBADA WEST	Self Employed	27-Aug-1972
852	20081424	Tara Gau	M	POREBADA WEST	Self Employed	12-Aug-1977
853	20054299	Tara Heagi	M	POREBADA WEST	Subsistence Farmer	13-Oct-1968
854	20072505	Tara Morea	M	POREBADA WEST	Driver	07-Nov-1973
855	20051327	Tara Pune	M	POREBADA WEST	Self Employed	24-Nov-1974
856	20051160	Tara Vele	M	POREBADA WEST	Self Employed	22-Sep-1972
857	20005524	TARA VELE LOHIA	M	POREBADA WEST	Pastor	30-Sep-1963
858	20087703	Taravatu Bitu	M	POREBADA WEST	Self Employed	02-Feb-1963
859	20087708	Taravatu Sisia	M	POREBADA WEST	Self Employed	09-Nov-1966
860	20085500	Taravatu Taravatu Jr	M	POREBADA WEST	Self Employed	04-Mar-1981
861	20076414	Tarupa Morea	M	POREBADA WEST	Student	27-Jun-1989
862	20009166	TAU BARU	M	POREBADA WEST	Unemployed	02-Jan-2000
863	20067605	Tau Gahusi	M	POREBADA WEST	Self Employed	20-Apr-1964
864	20218364	Tau Micheal	M	POREBADA WEST	Not Specified	10-Mar-1993
865	20018017	Tau Baru Morea	M	POREBADA WEST	Self Employed	04-Apr-1990
866	20079116	Tau Vaburi Baru	M	POREBADA WEST	Pastor	02-Jan-2000
867	20072990	Tauedea Lesile	M	POREBADA WEST	Self Employed	13-Mar-1972
868	20072936	Tauedea Oda	M	POREBADA WEST	Self Employed	25-Jan-1970
869	20005044	TAUEDEA VABURI MURAMURA	M	POREBADA WEST	Worker	15-May-1970
870	20123518	Taumaku Arua	M	POREBADA WEST	Security	03-Apr-1964
871	20197991	Taumaku Cooper	M	POREBADA WEST	Student	21-Dec-1999
872	20129887	Taumaku Guba	M	POREBADA WEST	Student	28-Apr-1997
873	20094431	Taumaku Hitolo	M	POREBADA WEST	Inspector	28-Feb-1959
874	20197968	Taumaku Morea	M	POREBADA WEST	Student	24-Feb-2000
875	20008597	TAUMAKU MOREA LOHIA	M	POREBADA WEST	Student	05-Nov-1989
876	20001456	TAUMAKU SAMUEL	M	POREBADA WEST	Subsistence Farmer	02-Aug-1993
877	20031939	Taumaku Hitolo Morea	M	POREBADA WEST	Clerk	01-Jan-1962
878	20068070	Taumaku Vaburi Kovae	M	POREBADA WEST	Self Employed	21-Aug-1974
879	20061938	Taunao Hitolo	M	POREBADA WEST	Self Employed	10-Oct-1973
880	20218366	Tika Jimmy	M	POREBADA WEST	Not Specified	20-Dec-2000
881	20131386	Toea Igo	M	POREBADA WEST	Fisherman	08-May-1995
882	20005174	TOEA MOREA BILLY BUSINA	M	POREBADA WEST	Student	18-Aug-1993
883	20094463	Toea Morea Lindsy	M	POREBADA WEST	Self Employed	28-Oct-1984
884	20092295	Toea Morea Morea	M	POREBADA WEST	Self Employed	22-Sep-1980
885	20092670	Toea Morea Peter	M	POREBADA WEST	Self Employed	28-Oct-1984
886	20009355	TOEA RAKA ARERE	M	POREBADA WEST	Self Employed	16-Nov-1993
887	20068063	Tolo Arua	M	POREBADA WEST	Pastor	07-Mar-1952
888	20218368	Tolo Baru	M	POREBADA WEST	Not Specified	15-May-1999
889	20092387	Tolo Frank	M	POREBADA WEST	Linesman	01-Jan-1957
890	20068074	Tolo Seri	M	POREBADA WEST	Self Employed	25-Jan-1969
891	20069550	Tolo Vagi	M	POREBADA WEST	Self Employed	25-Sep-1969
892	20130944	Tom Sanjay	M	POREBADA WEST	Household Duties	05-Apr-1998
893	20031828	Tom Aniani Kelly	M	POREBADA WEST	Self Employed	01-Jan-1982
894	20087676	Vaburi Dairi	M	POREBADA WEST	Subsistence Farmer	29-Mar-1967
895	20218369	Vaburi Dairi Taumaku	M	POREBADA WEST	Not Specified	28-Apr-2003
896	20069565	Vaburi Dairi Taumaku	M	POREBADA WEST	Teacher	28-Jul-1964
897	20090407	Vagi David	M	POREBADA WEST	Self Employed	25-Dec-1957
898	20218371	Vagi Gorogo	M	POREBADA WEST	Not Specified	25-Feb-2003
899	20130911	Vagi Heau Lohia	M	POREBADA WEST	Unemployed	24-Oct-1994
900	20002923	VAGI HOMOKA	M	POREBADA WEST	Contractor	31-Jul-1990
901	20131397	Vagi Igi	M	POREBADA WEST	Fisherman	05-May-1992
902	20218373	Vagi Lahui	M	POREBADA WEST	Not Specified	14-Jul-1964
903	20124232	Vagi Siage Lohia	M	POREBADA WEST	Self Employed	08-Dec-1952
904	20002537	VAGI TAUMAKU	M	POREBADA WEST	Unemployed	11-Sep-1992
905	20083727	Vagi Arere Arere	M	POREBADA WEST	Worker	24-May-1960
906	20062155	Vagi Heau Arere	M	POREBADA WEST	Self Employed	05-Jul-1953
907	9920022705	Vagi Heau Heau	M	POREBADA WEST	Student	17-Jun-1991
908	20076469	Vagi Heau Viropo Heau	M	POREBADA WEST	Self Employed	14-Nov-1959
909	20003295	VAGI IGO HARORO	M	POREBADA WEST	Worker	22-Jul-1987
910	20218376	Vagi Tauedea Tauedea	M	POREBADA WEST	Not Specified	08-Jan-1999
911	20123541	Vaino Gahusi	M	POREBADA WEST	Pastor	16-Aug-1978
912	20057186	Vaino Hau	M	POREBADA WEST	Manager	26-Sep-1975
913	20130921	Vanere Gemona	M	POREBADA WEST	Worker	24-Jun-1972
914	20006513	VARO HEAU	M	POREBADA WEST	Subsistence Farmer	01-Jan-1985
915	20089769	Varuko Heau	M	POREBADA WEST	Plumber	18-Aug-1958
916	20007905	VELE TOM	M	POREBADA WEST	Worker	01-Jan-1984
917	20085488	Vele Tara Arua	M	POREBADA WEST	Self Employed	02-Jan-2000
918	20090245	Virobo Asi	M	POREBADA WEST	Self Employed	24-Apr-1969
919	20130924	Virobo Bae	M	POREBADA WEST	Clerk	20-Jun-1975
920	20123549	Virobo JOHN BODIBO	M	POREBADA WEST	Fisherman	14-Jan-1962
921	20035405	Virobo Peter	M	POREBADA WEST	Self Employed	01-Jan-1972
922	20067596	Walo Karua	M	POREBADA WEST	Self Employed	01-Jun-1963
923	20218382	Walo Tau	M	POREBADA WEST	Not Specified	25-Sep-1981
924	20218383	Willie John	M	POREBADA WEST	Not Specified	03-Apr-1999
925	20001423	WILLIE VAGI	M	POREBADA WEST	Subsistence Farmer	02-Mar-1992
926	20218384	Willie Veata	M	POREBADA WEST	Not Specified	31-Dec-2001
927	20092679	Willie Vagi Gari	M	POREBADA WEST	Self Employed	08-Jan-1987
928	20094468	Willie Vagi Gorogo	M	POREBADA WEST	Self Employed	26-Dec-1981
929	20125738	Wilson Caleb	M	POREBADA WEST	Not Specified	18-Jul-1994
930	20009501	YORIS LAHUI PETER	M	POREBADA WEST	Clerk	03-Sep-1969
931	20057188	Agi Geua	F	POREBADA WEST	Household Duties	04-Mar-1956
932	20218160	Ahuta Hane	F	POREBADA WEST	Not Specified	11-Jun-1994
933	20090495	Ahuta Igo Geno	F	POREBADA WEST	Household Duties	01-Jan-1983
934	20090492	Ahuta Igo Henao	F	POREBADA WEST	Household Duties	08-Aug-1979
935	20092601	Aihi Isi	F	POREBADA WEST	Household Duties	03-Jul-1976
936	20131351	Aisi Annie	F	POREBADA WEST	Household Duties	01-Dec-1990
937	20218162	Ako Kari	F	POREBADA WEST	Not Specified	25-Jul-1990
938	20218163	Amatio Rakatani	F	POREBADA WEST	Not Specified	23-Jan-2000
939	20059271	Anai Maria	F	POREBADA WEST	Household Duties	02-Jan-2000
940	20003541	ARERE DORIGA	F	POREBADA WEST	Unemployed	01-Jan-1989
941	20218166	Arere Arua Kevau	F	POREBADA WEST	Not Specified	09-Dec-1990
942	20009356	KEVAU CHRISTINE	F	POREBADA WEST	Teacher	05-Oct-1984
943	20218168	Arere Vagi Henao	F	POREBADA WEST	Not Specified	08-Jul-1979
944	20083642	Arere Vagi Idau	F	POREBADA WEST	Student	29-Nov-1988
945	20061894	Arere Vagi Kaia	F	POREBADA WEST	Self Employed	01-Oct-1986
946	20061911	Arere Vagi Muraka	F	POREBADA WEST	Self Employed	30-Aug-1981
947	20058987	Arua Dobi	F	POREBADA WEST	Worker	14-Aug-1969
948	20123355	Arua Edith Mea	F	POREBADA WEST	Household Duties	10-Aug-1971
949	20218169	Arua Eme	F	POREBADA WEST	Not Specified	11-Nov-1995
950	20062508	Arua Geua	F	POREBADA WEST	Self Employed	02-Jan-2000
951	20197969	Arua Kore	F	POREBADA WEST	Unemployed	07-Feb-2000
952	20058981	Arua Koura	F	POREBADA WEST	Household Duties	23-Sep-1962
953	20076531	Arua Loa	F	POREBADA WEST	Household Duties	27-Aug-1965
954	20197970	ARUA Manoka	F	POREBADA WEST	Unemployed	08-Mar-1996
955	20056795	Arua Matile	F	POREBADA WEST	Sister	02-Apr-1970
956	20003637	ARUA MEA	F	POREBADA WEST	Household Duties	01-Jan-1988
957	20131367	Arua Sisia	F	POREBADA WEST	Pastor	15-Oct-1963
958	20197982	Arua Susan	F	POREBADA WEST	Unemployed	30-Oct-1976
959	20124118	Arua Vagi Asiaitaia	F	POREBADA WEST	Household Duties	17-Jun-1973
960	20087367	Arua Arere Hebou	F	POREBADA WEST	Household Duties	14-May-1960
961	20088138	Arua Arere Iru	F	POREBADA WEST	Household Duties	18-Aug-1962
962	20022420	Arua Arere Marina	F	POREBADA WEST	Household Duties	12-Feb-1982
963	20076448	Arua Arere Taumaku	F	POREBADA WEST	Household Duties	06-Mar-1976
964	20006144	ARUA AUANI NOHOKAVA	F	POREBADA WEST	Household Duties	16-Mar-1979
965	20087429	Arua Dabara Hane	F	POREBADA WEST	Self Employed	14-Feb-1984
966	20036672	Arua Dabara Susie	F	POREBADA WEST	Household Duties	01-Jan-1975
967	20088150	Arua Dairi Bede	F	POREBADA WEST	Household Duties	08-Sep-1979
968	20088148	Arua Dairi Geua	F	POREBADA WEST	Self Employed	09-Dec-1972
969	20003620	ARUA DAIRI MEA EDITH	F	POREBADA WEST	Household Duties	10-Aug-1971
970	20005127	ARUA DAIRI RAKA	F	POREBADA WEST	Student	06-Oct-1993
971	20035506	Arua Igo Mere	F	POREBADA WEST	Household Duties	26-Jan-1966
972	20090424	Arua Lahui Geua	F	POREBADA WEST	Household Duties	02-Jan-2000
973	20067887	Arua Loke Boio	F	POREBADA WEST	Household Duties	17-Sep-1976
974	20008241	ARUA MARAGA GEUA	F	POREBADA WEST	Pastor	16-Dec-1950
975	20067979	Arua Morea Boio	F	POREBADA WEST	Household Duties	15-Sep-1969
976	20089784	Arua Morea Kopi	F	POREBADA WEST	Household Duties	25-Jul-1980
977	20081371	Arua Riu Kila	F	POREBADA WEST	Self Employed	31-May-1983
978	20034387	Arua Tarupa Geua	F	POREBADA WEST	Household Duties	02-Jan-2000
979	20069277	Arua Tolo Mea	F	POREBADA WEST	Student	28-Feb-1989
980	20094914	Asi Hebou	F	POREBADA WEST	Household Duties	01-Jan-1956
981	20126024	Asi Keruma	F	POREBADA WEST	Student	21-Aug-1993
982	20056780	Asi Kori	F	POREBADA WEST	Secretary	11-Apr-1968
983	20124879	Asi Susan	F	POREBADA WEST	Household Duties	17-Jul-1993
984	20094924	Asi Virobo	F	POREBADA WEST	Household Duties	07-May-1951
985	20064743	Auani Bisi	F	POREBADA WEST	Self Employed	20-Nov-1959
986	20218171	Auani Boio	F	POREBADA WEST	Not Specified	10-Oct-1997
987	20069570	Auani Geua	F	POREBADA WEST	Self Employed	13-Aug-1976
988	20069569	Auani Tolo	F	POREBADA WEST	Self Employed	29-Aug-1970
989	20094555	Auani Asi Kari	F	POREBADA WEST	Household Duties	15-Jul-1965
990	20092798	Audabi Kovea Loa	F	POREBADA WEST	Household Duties	27-Sep-1978
991	20092613	Audabi Kovea Sibo	F	POREBADA WEST	Household Duties	19-May-1973
992	20003364	AUDABI MOREA DORIGA	F	POREBADA WEST	Household Duties	18-Nov-1992
993	20218174	Barti Hanneh	F	POREBADA WEST	Not Specified	12-Feb-1990
994	20064285	Baru Bede	F	POREBADA WEST	Household Duties	13-Oct-1975
995	20058870	Baru Boio	F	POREBADA WEST	Household Duties	06-Mar-1979
996	20089758	Baru Kila	F	POREBADA WEST	Teacher	27-Nov-1980
997	20058996	Baru Koura	F	POREBADA WEST	Household Duties	24-Aug-1972
998	20019017	Baru Lee	F	POREBADA WEST	Banker	24-Mar-1955
999	20005023	BARU LOHIA	F	POREBADA WEST	Household Duties	18-Dec-1990
1000	20001476	BARU LUCY	F	POREBADA WEST	Student	04-Mar-1993
1001	20079176	Baru Margaret	F	POREBADA WEST	Nurse	20-May-1965
1002	20092866	Baru Noi	F	POREBADA WEST	Household Duties	20-Aug-1985
1003	20088160	Baru Rama	F	POREBADA WEST	Retired	19-Sep-1957
1004	20003655	BARU SERI	F	POREBADA WEST	Receptionist	01-Jan-1986
1005	20031368	Baru Arua Idau	F	POREBADA WEST	Clerk	05-Jul-1978
1006	20005041	BARU GAU LUCY	F	POREBADA WEST	Student	04-Mar-1993
1007	20218176	Baru Morea Geua	F	POREBADA WEST	Not Specified	15-Jan-1997
1008	20072874	Baru Tolo Geua	F	POREBADA WEST	Worker	26-Nov-1958
1009	20218177	Batawi Kota Elizabeth	F	POREBADA WEST	Not Specified	28-Oct-1985
1010	20031888	Bemu Hitolo Mea	F	POREBADA WEST	Household Duties	09-Nov-1974
1011	20092291	Benson Ossie	F	POREBADA WEST	Self Employed	31-Aug-1985
1012	20005527	BILLY KORI	F	POREBADA WEST	Self Employed	16-Aug-1991
1013	20218178	Bitu Bonnie	F	POREBADA WEST	Not Specified	07-Feb-1997
1014	20083586	Bitu Dorido	F	POREBADA WEST	Household Duties	01-Sep-2000
1015	20004246	BITU KOTILDA	F	POREBADA WEST	Self Employed	01-Mar-1986
1016	20087397	Bitu Lucy	F	POREBADA WEST	Household Duties	09-May-1967
1017	20033053	Bitu Bodibo Dimere	F	POREBADA WEST	Household Duties	02-Jan-2000
1018	20003337	BITU TARAVATU TARAVATU	F	POREBADA WEST	Household Duties	19-Sep-1992
1019	20218179	Boa Geua	F	POREBADA WEST	Not Specified	13-Oct-2002
1020	20218180	Boa Maiva	F	POREBADA WEST	Not Specified	27-May-2001
1021	20094440	Bodibo Boge	F	POREBADA WEST	Household Duties	01-Nov-1965
1022	20218181	Bodibo Gau	F	POREBADA WEST	Not Specified	13-Jan-2001
1023	20067964	Bodibo Kaia	F	POREBADA WEST	Household Duties	30-Dec-1974
1024	20218184	Bodibo Koura	F	POREBADA WEST	Not Specified	11-Aug-2002
1025	20062174	Bodibo Mea	F	POREBADA WEST	Self Employed	07-Sep-1981
1026	20064492	Bodibo Vada	F	POREBADA WEST	Self Employed	15-Aug-1987
1027	20094454	Bodibo Taumaku Koi	F	POREBADA WEST	Self Employed	18-Aug-1986
1028	20090275	Boge Dabara Idau	F	POREBADA WEST	Household Duties	23-Sep-1959
1029	20031879	Boiori Haraka	F	POREBADA WEST	Clerk	01-Jan-1962
1030	20092336	Boroma Gima	F	POREBADA WEST	Household Duties	06-Jul-1974
1031	20218185	Brown Jacika	F	POREBADA WEST	Not Specified	25-Aug-1985
1032	20051333	Bua Bagara	F	POREBADA WEST	Floor Sander	11-Nov-1972
1033	20090466	Bua Tarupa	F	POREBADA WEST	Household Duties	10-Feb-1978
1034	20076464	Buruka Muraka	F	POREBADA WEST	Household Duties	24-Jul-1960
1035	20035424	Buruka Dogodo Idau	F	POREBADA WEST	Household Duties	06-Jun-1974
1036	20069753	Busina Bagara	F	POREBADA WEST	Household Duties	27-Apr-1982
1037	20069747	Busina Beso	F	POREBADA WEST	Carpenter	18-Mar-1985
1038	20067884	Busina Dogodo Arere	F	POREBADA WEST	Household Duties	11-Dec-1955
1039	20081107	Busina Iga	F	POREBADA WEST	Self Employed	02-Jun-1989
1040	20076455	Busina Kevau	F	POREBADA WEST	Household Duties	01-Jan-1961
1041	20072985	Busina Sisia	F	POREBADA WEST	Household Duties	28-Aug-1965
1042	20124849	Busina Vagi	F	POREBADA WEST	Pastor	11-Apr-1961
1043	20072951	Busina Vagi Dobi	F	POREBADA WEST	Student	23-Jan-1986
1044	20089707	Busina Arere Dogodo	F	POREBADA WEST	Household Duties	01-Jan-1958
1045	20218189	Busina lohia Maria	F	POREBADA WEST	Not Specified	20-Mar-2001
1046	20004197	BUSINA PUNE VAGI	F	POREBADA WEST	Household Duties	26-Apr-1985
1047	20090437	Camillo Marryann	F	POREBADA WEST	Self Employed	18-Apr-1986
1048	20123375	Dabara Sibona	F	POREBADA WEST	Household Duties	01-Jan-1967
1049	20081109	Dadami Maria	F	POREBADA WEST	Household Duties	30-Dec-1980
1050	20090449	Dadami Bodibo Kila	F	POREBADA WEST	Household Duties	07-Aug-1979
1051	20085516	Daera Hekure	F	POREBADA WEST	Household Duties	05-Apr-1984
1052	20081399	Daera Kaia	F	POREBADA WEST	Self Employed	16-Sep-1972
1053	20131345	Dairi Bede	F	POREBADA WEST	Student	06-Oct-1997
1054	20008339	DAIRI GAHUSI	F	POREBADA WEST	Unemployed	01-Jan-1981
1055	20064304	Dairi Gima	F	POREBADA WEST	Household Duties	11-Oct-1973
1056	20218190	Dairi Helen	F	POREBADA WEST	Not Specified	27-Apr-2000
1057	20009510	DAIRI KARI	F	POREBADA WEST	Self Employed	15-Jul-1990
1058	20197978	Dairi Kari	F	POREBADA WEST	Student	10-Jul-2000
1059	20081389	Dairi Keruma	F	POREBADA WEST	Household Duties	06-Jan-1980
1060	20061942	Dairi Koi	F	POREBADA WEST	Store Keeper	23-Sep-1982
1061	20064664	Dairi Loa	F	POREBADA WEST	Household Duties	17-Nov-1965
1062	20072940	Dairi Lucy	F	POREBADA WEST	Household Duties	11-Oct-1955
1063	20129886	Dairi Maggie	F	POREBADA WEST	Household Duties	01-Jan-1998
1064	20218191	Dairi Mareta	F	POREBADA WEST	Not Specified	29-Jan-1999
1065	20032560	Dairi Mauri	F	POREBADA WEST	Household Duties	03-Oct-1977
1066	20081483	Dairi Raka	F	POREBADA WEST	Household Duties	15-Sep-1970
1067	20002818	DAIRI GAHUSI IDAU	F	POREBADA WEST	Household Duties	20-Jan-1991
1068	20067901	Dairi Gahusi Mauri	F	POREBADA WEST	Household Duties	08-Nov-1984
1069	20018624	Dairi Vaburi Kari	F	POREBADA WEST	Cashier	15-Jul-1990
1070	20218194	Dakman Monica	F	POREBADA WEST	Not Specified	16-Jan-1978
1071	20069659	Daroa Kaia	F	POREBADA WEST	Household Duties	17-Jan-1973
1072	20069296	Daroa Maraga	F	POREBADA WEST	Household Duties	22-Jan-1969
1073	20009457	DAROA GAHUSI BO'O	F	POREBADA WEST	Household Duties	28-Dec-1976
1074	20007469	DAROA GAHUSI RENAGI G	F	POREBADA WEST	Worker	07-Aug-1988
1075	20197974	David Cathy	F	POREBADA WEST	Unemployed	15-Feb-1986
1076	20087442	David Dairi	F	POREBADA WEST	Household Duties	08-Aug-1976
1077	20131340	David Elizaberth	F	POREBADA WEST	Household Duties	09-Jun-1990
1078	20072541	David Kari	F	POREBADA WEST	Self Employed	18-Oct-1987
1079	20083947	David Margret	F	POREBADA WEST	Household Duties	30-Apr-1975
1080	20061893	Dika Loa	F	POREBADA WEST	Student	22-Dec-1984
1081	20125736	Dika Puro	F	POREBADA WEST	Household Duties	14-May-1993
1082	20062178	Dika Sibo	F	POREBADA WEST	Sister	28-Nov-1974
1083	20218195	Dikana Orani	F	POREBADA WEST	Not Specified	10-Jan-1986
1084	20218196	Dimere Boge	F	POREBADA WEST	Not Specified	10-Aug-2003
1085	20051175	Dimere Geua	F	POREBADA WEST	Household Duties	24-Dec-1968
1086	20218198	Dimere Raka	F	POREBADA WEST	Not Specified	21-Oct-1996
1087	20090445	Dimere Taumaku Hane	F	POREBADA WEST	Self Employed	15-Aug-1964
1088	20218199	Dirona Vada	F	POREBADA WEST	Not Specified	12-Mar-1984
1089	20061929	Dorido Rakatani	F	POREBADA WEST	Self Employed	07-Aug-1983
1090	20067908	Dorido Raka Raka	F	POREBADA WEST	Household Duties	01-Jan-1964
1091	20009428	DORIDO RAKATANI KEVAU	F	POREBADA WEST	Student	02-Dec-1995
1092	20009471	DOROTHY LOHIA	F	POREBADA WEST	Chef	26-Jul-1974
1093	20033592	Douna Igo	F	POREBADA WEST	Clerk	01-Jan-1958
1094	20092709	Doura Morea Kari	F	POREBADA WEST	Student	18-Mar-1988
1095	20083543	Doura Rakatani Hua	F	POREBADA WEST	Household Duties	18-Apr-1972
1096	20089782	Doura Seri Tola	F	POREBADA WEST	Subsistence Farmer	01-Nov-2000
1097	20031401	Doura Vagi Dairi	F	POREBADA WEST	Household Duties	10-Apr-1985
1098	20218200	Ebo Georgina	F	POREBADA WEST	Not Specified	13-Aug-2000
1099	20017848	Ebo Kalo	F	POREBADA WEST	Household Duties	27-Jul-1975
1100	20218201	Ebo Nou	F	POREBADA WEST	Not Specified	11-May-2002
1101	20023634	Egi Heni	F	POREBADA WEST	Librarian	12-Apr-1954
1102	20072543	Eguta Abi Boio	F	POREBADA WEST	Household Duties	06-Feb-1960
1103	20068085	Eguta Lahui Boio	F	POREBADA WEST	Household Duties	18-Apr-1948
1104	20218203	Eli Kaia	F	POREBADA WEST	Not Specified	28-Jun-2000
1105	20218204	Elimo Mauri Lois	F	POREBADA WEST	Not Specified	08-Aug-1969
1106	20218205	Francis Agata	F	POREBADA WEST	Not Specified	03-Jun-1977
1107	20069751	Francis Puro	F	POREBADA WEST	Household Duties	24-Aug-1984
1108	20089853	Gahusi Geua	F	POREBADA WEST	Self Employed	03-Jan-1989
1109	20089770	Gahusi Kaia	F	POREBADA WEST	Household Duties	01-Jan-1958
1110	20197994	Gahusi Kori	F	POREBADA WEST	Unemployed	24-Jun-1998
1111	20032990	Gahusi Hera Dika	F	POREBADA WEST	Household Duties	01-Jan-1950
1112	20004158	GAHUSI RAKATANI MARLENE	F	POREBADA WEST	Student	09-Dec-1992
1113	20197984	Gahusi Sai Rita	F	POREBADA WEST	Student	01-May-1963
1114	20054212	Gaigo Kaia	F	POREBADA WEST	Self Employed	25-Apr-1987
1115	20076479	Gari Geua	F	POREBADA WEST	Household Duties	09-Jan-1970
1116	20218212	Gari Henao	F	POREBADA WEST	Not Specified	22-Oct-1990
1117	20004171	GARI MOREA BOIO	F	POREBADA WEST	Student	06-Apr-1994
1118	20094535	Gau Arua	F	POREBADA WEST	Household Duties	26-Sep-1996
1119	20123389	GAU Geua Patrick	F	POREBADA WEST	Student	08-Sep-1987
1120	20131123	Gau Hebou	F	POREBADA WEST	Household Duties	12-Oct-1993
1121	20051143	Gau Hua	F	POREBADA WEST	Clerk	24-Mar-1967
1122	20003427	GAU IDAU R	F	POREBADA WEST	Household Duties	13-Jun-1991
1123	20004630	GAU MARAMA VAGI	F	POREBADA WEST	Worker	24-Nov-1990
1124	20123391	GAU MEA PATRICK	F	POREBADA WEST	Carpenter	27-Jul-1989
1125	20083648	Gau Samuel	F	POREBADA WEST	Unemployed	04-Dec-1991
1126	20008250	GAU SIBO ASI	F	POREBADA WEST	Receptionist	01-Jan-1985
1127	20003973	GAU ASI ASI	F	POREBADA WEST	Student	05-Nov-1993
1128	20218217	Gau Baru Maria	F	POREBADA WEST	Not Specified	12-Mar-1999
1129	20002524	GAU EGUTA Geua	F	POREBADA WEST	Student	16-Feb-1993
1130	20218220	Gau Eguta Rose	F	POREBADA WEST	Not Specified	07-Oct-1996
1131	20008222	GAU HENAO BARU	F	POREBADA WEST	Worker	15-Aug-1993
1132	20032516	Gau Kokoro Raka	F	POREBADA WEST	Household Duties	01-Jan-1965
1133	20076422	Gau Rei Hoi	F	POREBADA WEST	Self Employed	20-Jun-1988
1134	20008400	GAU REI MARAGA	F	POREBADA WEST	Unemployed	01-Jan-1981
1135	20007913	GAU REI MOREA	F	POREBADA WEST	Unemployed	18-Dec-1993
1136	20018620	Gau Simon Henao	F	POREBADA WEST	Household Duties	02-Jan-1989
1137	20076000	Gau Simon Maryann	F	POREBADA WEST	Student	21-Oct-1982
1138	20051150	Gaudi Boio	F	POREBADA WEST	Household Duties	22-Jul-1979
1139	20022362	Gaudi Iru	F	POREBADA WEST	Household Duties	16-May-1989
1140	20197972	Gaudi Kari	F	POREBADA WEST	Unemployed	04-Apr-1999
1141	20003523	GAVERA BONI	F	POREBADA WEST	Unemployed	01-Jan-1990
1142	20001483	GAVERA DAIRI LOHIA	F	POREBADA WEST	Household Duties	13-Jul-1989
1143	20003526	GAVERA GRACE	F	POREBADA WEST	Student	08-Aug-1992
1144	20004213	GAVERA HUA	F	POREBADA WEST	Student	22-Jan-1991
1145	20073010	Gege Kaia	F	POREBADA WEST	Household Duties	06-Aug-1975
1146	20218227	Gege Gure Kaia	F	POREBADA WEST	Not Specified	18-Mar-1974
1147	20083577	Goasa Dia	F	POREBADA WEST	Household Duties	16-Jul-1967
1148	20002809	GOASA DIKA	F	POREBADA WEST	Household Duties	10-Oct-1969
1149	20076558	Goasa Garia	F	POREBADA WEST	Household Duties	24-Apr-1959
1150	20130603	Goasa Geua	F	POREBADA WEST	Student	03-Apr-1998
1151	20081574	Goasa Hekoi	F	POREBADA WEST	Household Duties	07-Jun-1973
1152	20087374	Goasa Hoi	F	POREBADA WEST	Self Employed	01-Jan-1987
1153	20087411	Goasa Manoka	F	POREBADA WEST	Self Employed	01-Jan-1982
1154	20123394	Goasa Maraga	F	POREBADA WEST	Household Duties	26-Nov-1962
1155	20004596	GOASA HOMOKA DIA	F	POREBADA WEST	Household Duties	14-Apr-1989
1156	20034314	Goasa Ova Idau	F	POREBADA WEST	Household Duties	01-Jan-1965
1157	20218229	Goata Gari	F	POREBADA WEST	Not Specified	23-Jul-1995
1158	20075992	Goata Busina Naomi	F	POREBADA WEST	Self Employed	14-Sep-1986
1159	20092623	Goata Eguta Gabae	F	POREBADA WEST	Household Duties	21-Oct-1956
1160	20218230	Gorogo Eli	F	POREBADA WEST	Not Specified	25-Jul-1999
1161	20131325	Gorogo Geua	F	POREBADA WEST	Unemployed	06-Oct-1985
1162	20081479	Gorogo Kalo	F	POREBADA WEST	Household Duties	06-Mar-1980
1163	20076726	Gorogo Molong	F	POREBADA WEST	Household Duties	28-Mar-1974
1164	20218231	Gorogo Susie	F	POREBADA WEST	Not Specified	31-May-1998
1165	20031373	Guba Heni Hitolo	F	POREBADA WEST	Household Duties	16-Sep-1973
1166	20094524	Guba Koani Arere	F	POREBADA WEST	Household Duties	10-Oct-1954
1167	20067981	Guba Sisia Maria	F	POREBADA WEST	Household Duties	12-Jan-1977
1168	20218235	Gudia Vagi	F	POREBADA WEST	Not Specified	30-Sep-1968
1169	20218236	Gure Homoka	F	POREBADA WEST	Not Specified	27-Sep-2000
1170	20085497	Gure Mauri	F	POREBADA WEST	Household Duties	17-Sep-1957
1171	20031443	Gure Renagi	F	POREBADA WEST	Household Duties	01-Jan-1963
1172	20218238	Haraka Miriam	F	POREBADA WEST	Not Specified	27-Jan-2001
1173	20007763	HAVATA HITOLO REI	F	POREBADA WEST	Sister	01-Jan-1964
1174	20087421	Havata Rakatani	F	POREBADA WEST	Subsistence Farmer	02-Jan-2000
1175	20069681	Heagi Kevau	F	POREBADA WEST	Household Duties	12-Jun-1955
1176	20123407	Heagi Kila	F	POREBADA WEST	Self Employed	27-Jan-1983
1177	20031840	Heagi Tabe Ranu	F	POREBADA WEST	Sales Women	01-Jan-1965
1178	20218242	Heagi Varuko Morea	F	POREBADA WEST	Not Specified	25-Apr-2001
1179	20129881	Heau Boge	F	POREBADA WEST	Self Employed	08-Feb-1989
1180	20218243	Heau Emily	F	POREBADA WEST	Not Specified	06-Jun-2002
1181	20131364	Heau Iru	F	POREBADA WEST	Student	15-Oct-1997
1182	20130948	Heau Karoho	F	POREBADA WEST	Household Duties	06-Dec-1996
1183	20218244	Heau Kori	F	POREBADA WEST	Not Specified	19-Oct-2002
1184	20050684	Heau Loulai	F	POREBADA WEST	Household Duties	24-Nov-1980
1185	20094503	Heau Mea	F	POREBADA WEST	Self Employed	26-Apr-1961
1186	20056534	Heau Mere	F	POREBADA WEST	Household Duties	19-Feb-1979
1187	20056623	Heau Dairi Geua	F	POREBADA WEST	Household Duties	28-Jan-1978
1188	20067589	Heau Heau Geua	F	POREBADA WEST	Household Duties	01-Jan-1957
1189	20009372	HEAU LOHIA BOIO	F	POREBADA WEST	Household Duties	16-Apr-1987
1190	20076511	Heau Varuko Kevau	F	POREBADA WEST	Household Duties	14-Oct-1987
1191	20069557	Hegora Naomi	F	POREBADA WEST	Teacher	04-May-1977
1192	20083580	Helai Henao	F	POREBADA WEST	Household Duties	01-Jan-1953
1193	20218246	Helai Konio	F	POREBADA WEST	Not Specified	06-Oct-1987
1194	20022354	Heni Geua	F	POREBADA WEST	Self Employed	02-Aug-1993
1195	20009589	HENI KONIO RAY TOM	F	POREBADA WEST	Household Duties	18-Aug-1993
1196	20089842	Heni Lahui	F	POREBADA WEST	Household Duties	07-Sep-1977
1197	20089859	Heni Ranu	F	POREBADA WEST	Household Duties	22-Sep-1979
1198	20018611	Heni Sibona	F	POREBADA WEST	Student	22-Aug-1992
1199	20085350	Heni Gorogo Iana	F	POREBADA WEST	Household Duties	02-May-1975
1200	20078640	Heni Igo Loulai	F	POREBADA WEST	Household Duties	16-Aug-1978
1201	20005186	HENRY BODIBO BOGE	F	POREBADA WEST	Student	07-Sep-1993
1202	20218249	Henry Gari Barbara	F	POREBADA WEST	Not Specified	11-Apr-1978
1203	20094403	Henry Rakatani Konio	F	POREBADA WEST	Self Employed	05-May-1989
1204	20079074	Hera Hane	F	POREBADA WEST	Household Duties	01-Mar-2000
1205	20067616	Hera Nou	F	POREBADA WEST	Household Duties	09-Feb-1964
1206	20094493	Hera Sibo	F	POREBADA WEST	Household Duties	01-Jan-1962
1207	20003642	HERA SISIA GEUA	F	POREBADA WEST	Student	02-Jul-1992
1208	20087712	Hera Sisia Manoka	F	POREBADA WEST	Self Employed	21-Jun-1979
1209	20218250	Hevigi Grace	F	POREBADA WEST	Not Specified	18-Aug-1996
1210	20087399	Hitolo Bagara	F	POREBADA WEST	Self Employed	02-Nov-1986
1211	20068073	Hitolo Gari	F	POREBADA WEST	Household Duties	08-Apr-1970
1212	20003966	HITOLO GEUA	F	POREBADA WEST	Farm worker	16-Sep-1991
1213	20005012	HITOLO HEBOU	F	POREBADA WEST	Unemployed	01-Jan-1993
1214	20197967	Hitolo Hekoi	F	POREBADA WEST	Student	08-Mar-1998
1215	20218251	Hitolo Joyce Boge	F	POREBADA WEST	Not Specified	12-Sep-2003
1216	20072352	Hitolo Kaia	F	POREBADA WEST	Household Duties	10-Oct-1988
1217	20197993	Hitolo Naime	F	POREBADA WEST	Unemployed	01-Aug-1994
1218	20218252	Hitolo Norah	F	POREBADA WEST	Not Specified	31-Dec-1996
1219	20218253	Hitolo Tamara	F	POREBADA WEST	Not Specified	20-Nov-2001
1220	20054757	Hitolo Homoka Hebou	F	POREBADA WEST	Household Duties	05-Jul-1989
1221	20090486	Hitolo Kovea Kevau	F	POREBADA WEST	Household Duties	03-Apr-1964
1222	20005053	HITOLO KOVEA KILA TOVO	F	POREBADA WEST	Household Duties	24-Sep-1974
1223	20090484	Hitolo Kovea Vahu	F	POREBADA WEST	Self Employed	22-Oct-1972
1224	20033473	Hitolo Lohia Ranu	F	POREBADA WEST	Household Duties	20-Sep-1956
1225	20090464	Homoka Boge	F	POREBADA WEST	Worker	06-Feb-1963
1226	20069304	Homoka Geua	F	POREBADA WEST	Household Duties	23-Oct-1980
1227	20051159	Homoka Gobuta	F	POREBADA WEST	Household Duties	20-Jun-1961
1228	20068072	Homoka Hoi	F	POREBADA WEST	Household Duties	30-Jul-1969
1229	20002521	HOMOKA HOMOKA	F	POREBADA WEST	Salesman	05-Jul-1991
1230	20051141	Homoka Kauna	F	POREBADA WEST	Household Duties	13-Nov-1959
1231	20079135	Homoka Kevau	F	POREBADA WEST	Household Duties	16-Sep-1960
1232	20069559	Homoka Koura	F	POREBADA WEST	Self Employed	15-May-1972
1233	20078638	Homoka Maraga	F	POREBADA WEST	Household Duties	05-May-1976
1234	20088164	Homoka Maraga	F	POREBADA WEST	Household Duties	01-Jan-1951
1235	20094458	Homoka Goasa Geua	F	POREBADA WEST	Household Duties	23-Oct-1980
1236	20094460	Homoka Goasa Kaia	F	POREBADA WEST	Household Duties	01-Jan-1985
1237	20003351	HOMOKA GOASA MARAGA	F	POREBADA WEST	Self Employed	22-Oct-1983
1238	20079129	Homoka Goata Bagara	F	POREBADA WEST	Household Duties	20-Aug-1955
1239	20087378	Homoka Ova Dika	F	POREBADA WEST	Clerk	09-Apr-1962
1240	20031934	Homoka Ova Geua	F	POREBADA WEST	Household Duties	02-Jan-2000
1241	20005154	HOMOKA SERI HOMOKA	F	POREBADA WEST	Household Duties	04-Jul-1991
1242	20130630	Hooper Rosaselyn	F	POREBADA WEST	Household Duties	03-Mar-1998
1243	20218257	Iana Kaia	F	POREBADA WEST	Not Specified	20-Nov-2002
1244	20094353	Iana Lohia	F	POREBADA WEST	Household Duties	19-Dec-1975
1245	20004289	IDAU JANE	F	POREBADA WEST	Unemployed	01-Jan-1986
1246	20094480	Igo Hitolo Kerry	F	POREBADA WEST	Household Duties	19-Jun-1982
1247	20056627	Igo Igua	F	POREBADA WEST	Self Employed	29-May-1976
1248	20003953	IGO KAIA	F	POREBADA WEST	Self Employed	01-Jan-1982
1249	20003410	IGO KILA	F	POREBADA WEST	Worker	01-Jan-1976
1250	20051341	Igo Kone	F	POREBADA WEST	Student	25-Aug-1987
1251	20003978	IGO MARAGA	F	POREBADA WEST	Unemployed	01-Jan-1992
1252	20124850	Igo Sadlyn	F	POREBADA WEST	Policewomen	10-May-1986
1253	20076125	Igo Theresa	F	POREBADA WEST	Self Employed	15-Jun-1986
1254	20079177	Igo Udu	F	POREBADA WEST	Household Duties	31-Jul-1967
1255	20131365	Igo Wilma	F	POREBADA WEST	Household Duties	09-Mar-1992
1256	20090250	Igo Winifred	F	POREBADA WEST	Clerk	06-Oct-1980
1257	20087702	Igo Ahuta Boio	F	POREBADA WEST	Household Duties	26-Dec-1962
1258	20092808	Igo Ahuta Torea	F	POREBADA WEST	Household Duties	16-Apr-1960
1259	20088170	Igo Dairi Kari	F	POREBADA WEST	Self Employed	01-Dec-2000
1260	20002925	IGO DAIRI KONE	F	POREBADA WEST	Household Duties	02-Feb-2000
1261	20087414	Igo Koani Kaia	F	POREBADA WEST	Household Duties	26-Nov-1957
1262	20002924	IGO REI MAIVA	F	POREBADA WEST	Household Duties	26-Mar-1992
1263	20054796	Igo Tolo Gari	F	POREBADA WEST	Household Duties	21-Jul-1970
1264	20054805	Igo Tolo Kaia	F	POREBADA WEST	Teacher	23-Mar-1979
1265	20064952	Igo Vagi Lahui	F	POREBADA WEST	Household Duties	24-Dec-1956
1266	20087686	Imunu Heni	F	POREBADA WEST	Household Duties	04-Mar-1954
1267	20090254	Inara Edith Mea	F	POREBADA WEST	Secretary	20-Jan-1968
1268	20069292	Ioa Henao	F	POREBADA WEST	Self Employed	23-Apr-1977
1269	20064485	Irua Raka	F	POREBADA WEST	Household Duties	02-Jan-2000
1270	20092600	Isaiah Dobi	F	POREBADA WEST	Household Duties	07-Oct-1965
1271	20022685	Isaiah Kaia	F	POREBADA WEST	Worker	17-Nov-1964
1272	20079158	Isaiah Loa	F	POREBADA WEST	Household Duties	24-May-1972
1273	20078622	Isaiah Maraga	F	POREBADA WEST	Self Employed	11-Nov-1983
1274	20031996	Isaiah Vagi Kevau	F	POREBADA WEST	Household Duties	28-Aug-1973
1275	20036192	Isaiah Vagi Mary	F	POREBADA WEST	Clerk	09-Nov-1963
1276	20218263	Ite Gleneyse	F	POREBADA WEST	Not Specified	03-Jul-1999
1277	20218264	Ite Iru	F	POREBADA WEST	Not Specified	26-Sep-2001
1278	20218265	Ite Lyan	F	POREBADA WEST	Not Specified	29-Nov-2003
1279	20218266	Jack Ainessah	F	POREBADA WEST	Not Specified	20-Oct-1990
1280	20087436	Jack Hitolo	F	POREBADA WEST	Self Employed	31-Jan-1977
1281	20123437	Jack Mauri	F	POREBADA WEST	Household Duties	01-Dec-1977
1282	20087682	Jack Morea	F	POREBADA WEST	Household Duties	01-Jan-1984
1283	20083593	Jack Rhonda	F	POREBADA WEST	Household Duties	21-Sep-1973
1284	20003871	JACK IMUNU CATHY	F	POREBADA WEST	Teacher	14-Dec-1982
1285	20003396	JACK IMUNU HITOLO	F	POREBADA WEST	Household Duties	31-Dec-1977
1286	20131371	James Sevina	F	POREBADA WEST	Not Specified	01-Jun-1994
1287	20218267	Jerome Miriam	F	POREBADA WEST	Not Specified	30-Nov-1995
1288	20079101	Jerry Lohia Seri	F	POREBADA WEST	Accountant	06-Apr-1977
1289	20085370	Jimmy Gaua	F	POREBADA WEST	Household Duties	07-Jun-1992
1290	20085498	Jimmy Ranu	F	POREBADA WEST	Household Duties	25-Dec-1983
1291	20218270	Joe Joyce	F	POREBADA WEST	Not Specified	18-Aug-1987
1292	20006130	JOE KALA	F	POREBADA WEST	Unemployed	19-Feb-1987
1293	20022368	John Hitolo	F	POREBADA WEST	Student	03-Sep-1992
1294	20218273	John Maba	F	POREBADA WEST	Not Specified	21-Jan-2002
1295	20130739	John Maggie	F	POREBADA WEST	Household Duties	24-Nov-1998
1296	20006235	JOHN MAGRET	F	POREBADA WEST	Household Duties	15-Dec-1987
1297	20006141	JOHN MOLI	F	POREBADA WEST	Unemployed	01-Jan-1980
1298	20130988	John Morea	F	POREBADA WEST	Worker	09-Jul-1996
1299	20218274	John Muila	F	POREBADA WEST	Not Specified	25-Sep-1991
1300	20073012	John Rogana	F	POREBADA WEST	Student	01-Jun-1988
1301	20004531	JOHN JACK MEA	F	POREBADA WEST	Household Duties	26-Jun-1992
1302	20092318	John Oa Annette	F	POREBADA WEST	Household Duties	01-Jan-1976
1303	20054772	Jonh Geua	F	POREBADA WEST	Household Duties	28-Mar-1976
1304	20123438	Josaiah Eare	F	POREBADA WEST	Household Duties	13-Jun-1980
1305	20218276	Kaiulo Igo Cynthia	F	POREBADA WEST	Not Specified	23-Sep-1986
1306	20003407	KARI ILAGI KOVEA	F	POREBADA WEST	Household Duties	09-Oct-1991
1307	20218277	Karua Birua	F	POREBADA WEST	Not Specified	18-Jan-1994
1308	20064548	Karua Kori	F	POREBADA WEST	Self Employed	05-May-1987
1309	20069749	Karua Loa	F	POREBADA WEST	Self Employed	01-Jan-1959
1310	20085736	Karua Maria	F	POREBADA WEST	Household Duties	23-May-1987
1311	20076418	Karua Mea	F	POREBADA WEST	Household Duties	30-Sep-1967
1312	20054295	Karua Nanai	F	POREBADA WEST	Household Duties	26-Jun-1978
1313	20073001	Karua Variva	F	POREBADA WEST	Household Duties	26-Jul-1981
1314	20033051	Karua Dairi Boio	F	POREBADA WEST	Household Duties	07-Oct-1949
1315	20003527	KARUA GOATA GARIA	F	POREBADA WEST	Household Duties	27-Jan-1990
1316	20092306	Karua Mea Koi	F	POREBADA WEST	Self Employed	12-Mar-1986
1317	20003398	KARUA SISIA GRACE KARUA	F	POREBADA WEST	Household Duties	17-Oct-1975
1318	20036163	Karua Sisia Loa	F	POREBADA WEST	Clerk	06-Jun-1973
1319	20004573	KARUA SISIA Mauri ARUA	F	POREBADA WEST	Household Duties	23-Jan-1979
1320	20003404	KARUA WALO HITOLO	F	POREBADA WEST	Household Duties	13-Apr-1994
1321	20069567	Karua Walo Kori	F	POREBADA WEST	Self Employed	05-May-1987
1322	20081422	Kauna Boio	F	POREBADA WEST	Household Duties	08-Aug-1968
1323	20064961	Kauna Konio	F	POREBADA WEST	Household Duties	07-Oct-1979
1324	20131357	Kauna Vagi	F	POREBADA WEST	Pastor	31-Oct-1973
1325	20069677	Kauna Gau Maria	F	POREBADA WEST	Self Employed	25-Apr-1986
1326	20019018	Kauna Homoka Bagara	F	POREBADA WEST	Household Duties	18-Feb-1991
1327	20218284	Kavna Sioro	F	POREBADA WEST	Not Specified	09-Nov-1995
1328	20130755	Kelly Kari	F	POREBADA WEST	Household Duties	22-May-1995
1329	20061926	Keni Gorogo	F	POREBADA WEST	Household Duties	03-May-1973
1330	20087690	Keni Nono	F	POREBADA WEST	Household Duties	05-May-1978
1331	20124167	Kevau Lohia Kari	F	POREBADA WEST	Household Duties	15-Oct-1982
1332	20062151	Kevau  Vagi Baru	F	POREBADA WEST	Household Duties	01-Jul-2000
1333	20009354	KEVAU GEGE JEROLYN	F	POREBADA WEST	Household Duties	10-Oct-1969
1334	20124168	Kila Kone Dia	F	POREBADA WEST	Household Duties	14-Oct-1989
1335	20218286	Kila Mary	F	POREBADA WEST	Not Specified	05-Dec-1998
1336	20087401	Kila Sete	F	POREBADA WEST	Self Employed	21-Jun-1987
1337	20218287	Kiri Lucy	F	POREBADA WEST	Not Specified	11-May-1995
1338	20123447	Koani Biru	F	POREBADA WEST	Self Employed	10-Jan-1980
1339	20218288	Koani Garia	F	POREBADA WEST	Not Specified	30-Oct-2002
1340	20092344	Koani Geua	F	POREBADA WEST	Household Duties	02-Jan-2000
1341	20089766	Koani Henao	F	POREBADA WEST	Teacher	16-Oct-1975
1342	20031291	Kohu Dairi	F	POREBADA WEST	Household Duties	01-Jan-1956
1343	20092594	Kohu Kaia	F	POREBADA WEST	Household Duties	26-Jul-1968
1344	20035419	Kohu Gaudi Naomi	F	POREBADA WEST	Household Duties	01-Jan-1979
1345	20076139	Kohu Kovae Toutu	F	POREBADA WEST	Household Duties	06-Jul-1962
1346	20081438	Koita Mellin	F	POREBADA WEST	Household Duties	26-Oct-1972
1347	20054308	Kokoro Rose	F	POREBADA WEST	Teacher	12-Oct-1978
1348	20218289	Kottu Idau	F	POREBADA WEST	Not Specified	29-Aug-1992
1349	20081555	Kovae Hoi	F	POREBADA WEST	Household Duties	02-Jan-2000
1350	20005077	KOVAE SERI LUSY	F	POREBADA WEST	Worker	16-Oct-1990
1351	20131333	Kovea Homoka	F	POREBADA WEST	Household Duties	26-Nov-1988
1352	20092804	Kovea Morea Buruka	F	POREBADA WEST	Household Duties	01-Jan-1952
1353	20218290	Laho Vele	F	POREBADA WEST	Not Specified	19-Jun-1999
1354	20218291	Lahui Kevau	F	POREBADA WEST	Not Specified	09-Nov-2001
1355	20022367	Lahui Rose	F	POREBADA WEST	Household Duties	28-Aug-1973
1356	20131394	Lahui Ume	F	POREBADA WEST	Household Duties	13-Jul-1987
1357	20087408	Lahui Morea Mary	F	POREBADA WEST	Household Duties	02-Jan-2000
1358	20218296	Lahui Vagi Kaia	F	POREBADA WEST	Not Specified	17-Nov-1995
1359	20085705	Leke Taravatu Boio	F	POREBADA WEST	Household Duties	03-Aug-1974
1360	20218298	Leva Serah	F	POREBADA WEST	Not Specified	16-Sep-1996
1361	20056643	Loa Miriam	F	POREBADA WEST	Household Duties	28-Jan-1958
1362	20022702	Lohia Doriga	F	POREBADA WEST	Household Duties	29-Oct-1992
1363	20089852	Lohia Dulcie	F	POREBADA WEST	Household Duties	09-Jul-1981
1364	20022370	Lohia Geua	F	POREBADA WEST	Household Duties	21-Apr-1988
1365	20003353	LOHIA GILDA	F	POREBADA WEST	Student	08-Jun-1993
1366	20090342	Lohia Goata	F	POREBADA WEST	Clerk	13-Aug-1964
1367	20081420	Lohia Itapo	F	POREBADA WEST	Household Duties	02-Jan-2000
1368	20064565	Lohia Keruma	F	POREBADA WEST	Household Duties	01-Jan-1982
1369	20130935	Lohia Maraga	F	POREBADA WEST	Household Duties	20-Oct-1998
1370	20083924	Lohia Mary	F	POREBADA WEST	Household Duties	06-Jun-1972
1371	20051140	Lohia Ranu	F	POREBADA WEST	Household Duties	01-Feb-1960
1372	20054479	Lohia Valerie Igo	F	POREBADA WEST	Clerk	23-Jan-1985
1373	20009439	LOHIA AISI MOLINA	F	POREBADA WEST	Student	14-Jul-1993
1374	20218301	Lohia Bodibo Mea	F	POREBADA WEST	Not Specified	02-Dec-1981
1375	20004229	LOHIA DAIRI BEDE	F	POREBADA WEST	Household Duties	01-Jan-1965
1376	20003512	LOHIA GAVERA BITU DAIRI	F	POREBADA WEST	Household Duties	13-Jul-1989
1377	20090345	Lohia Havata Dora	F	POREBADA WEST	Self Employed	02-Apr-1980
1378	20090468	Lohia Havata Kaia	F	POREBADA WEST	Self Employed	18-Nov-1985
1379	20035526	Lohia Morea Geua	F	POREBADA WEST	Sales Women	01-Jan-1980
1380	20218303	Lohia Siage Hekoi	F	POREBADA WEST	Not Specified	02-Apr-2001
1381	20054499	Lohia Siage Raka	F	POREBADA WEST	Student	01-Jan-1987
1382	20003634	LOHIA SIMON RAKA	F	POREBADA WEST	Household Duties	15-Jun-1990
1383	20009347	LOHIA TARA SISIA	F	POREBADA WEST	Student	09-Jan-1993
1384	20068094	Lohia Walo Keruma	F	POREBADA WEST	Self Employed	19-Mar-1966
1385	20218305	Loi Morea Vali	F	POREBADA WEST	Not Specified	31-Dec-1967
1386	20218307	Loke Mea	F	POREBADA WEST	Not Specified	02-May-1999
1387	20218309	Maba Hekoi	F	POREBADA WEST	Not Specified	11-Jan-1998
1388	20087706	Maba Mary	F	POREBADA WEST	Household Duties	12-Sep-1960
1389	20004235	MABA NONO	F	POREBADA WEST	Household Duties	20-Feb-1993
1390	20076504	Maba Ranu	F	POREBADA WEST	Household Duties	01-Jan-1958
1391	20033857	Maba Kovea Hitolo	F	POREBADA WEST	Household Duties	03-Mar-1955
1392	20092680	Maba Kovea Nao	F	POREBADA WEST	Household Duties	01-Jan-1968
1393	20002825	MABA NONO ARUA	F	POREBADA WEST	Household Duties	20-Feb-1993
1394	20218310	Maba Nono Hoi	F	POREBADA WEST	Not Specified	07-Jan-2003
1395	20067956	Maba Vaburi Nono	F	POREBADA WEST	Household Duties	10-Aug-1964
1396	20130955	Mabata Alu	F	POREBADA WEST	Self Employed	26-Jun-1995
1397	20087415	Mabata Dabara Idau	F	POREBADA WEST	Household Duties	01-Jan-1983
1398	20022682	Madi Dina	F	POREBADA WEST	Household Duties	17-Nov-1990
1399	20092599	Madi Mauri	F	POREBADA WEST	Household Duties	16-Apr-1975
1400	20072565	Madi Loa Boio	F	POREBADA WEST	Household Duties	09-Oct-1983
1401	20090408	Mali Hoi	F	POREBADA WEST	Self Employed	29-May-1988
1402	20007140	MALI JUDY	F	POREBADA WEST	Student	14-Jan-1990
1403	20087396	Mali Mea	F	POREBADA WEST	Self Employed	12-Jul-1986
1404	20006830	MANAI GAHUSI ROSA	F	POREBADA WEST	Nurse	01-Aug-1970
1405	20124853	Maraga Cindy	F	POREBADA WEST	Household Duties	17-Aug-1997
1406	20087714	Maraga Iru	F	POREBADA WEST	Household Duties	22-Mar-1989
1407	20034634	Maraga Eguta Boio	F	POREBADA WEST	Household Duties	01-Jan-1975
1408	20131377	Mark Nellie	F	POREBADA WEST	Household Duties	25-Dec-1971
1409	20022384	Mea Dobi	F	POREBADA WEST	Household Duties	15-Mar-1991
1410	20218311	Mea Gou	F	POREBADA WEST	Not Specified	25-Sep-2000
1411	20124923	Mea Hua	F	POREBADA WEST	Household Duties	19-Sep-1990
1412	20125721	Mea Kaia	F	POREBADA WEST	Household Duties	04-Feb-1985
1413	20069275	Mea Arua Hua	F	POREBADA WEST	Self Employed	29-Jan-1988
1414	20005130	MEA AUANI MARIA	F	POREBADA WEST	Worker	09-Apr-1993
1415	20003335	MEA DIMERE NAOMI	F	POREBADA WEST	Unemployed	16-Aug-1987
1416	20035397	Mea Koani Konio	F	POREBADA WEST	Household Duties	17-Dec-1972
1417	20094446	Mea Pune Geua	F	POREBADA WEST	Self Employed	01-Jan-1981
1418	20076014	Mea Pune Kedea	F	POREBADA WEST	Household Duties	05-Jul-1975
1419	20009344	MIKI HENI DIKA	F	POREBADA WEST	Worker	04-Sep-1993
1420	20083581	Moia Buruka	F	POREBADA WEST	Household Duties	21-Mar-1983
1421	20083587	Moia Geua	F	POREBADA WEST	Household Duties	23-Feb-1981
1422	20083613	Moia Margret	F	POREBADA WEST	Household Duties	27-Feb-1986
1423	20003635	MOIA HEAU LOA	F	POREBADA WEST	Household Duties	19-Jan-1992
1424	20094547	Moia Igo Dia	F	POREBADA WEST	Household Duties	27-Apr-1973
1425	20076411	Momoru Ahea	F	POREBADA WEST	Household Duties	01-Jan-1968
1426	20078983	Momoru Ibo	F	POREBADA WEST	Household Duties	01-Jan-1968
1427	20090344	Momoru Kaia	F	POREBADA WEST	Household Duties	14-Nov-1974
1428	20218314	Momoru Manoka	F	POREBADA WEST	Not Specified	12-Jul-1995
1429	20056526	Momoru Baru Mareva	F	POREBADA WEST	Household Duties	01-Jan-1955
1430	20025743	Momoru Oda Mareva	F	POREBADA WEST	Household Duties	01-Jan-1976
1431	20005175	MOMORU TABE SIBONA	F	POREBADA WEST	Household Duties	06-Apr-1993
1432	20033853	Momoru Vagi Nancy	F	POREBADA WEST	Clerk	07-Apr-1977
1433	20197996	Morea Alice	F	POREBADA WEST	Unemployed	17-Nov-1998
1434	20131339	Morea Boio	F	POREBADA WEST	Subsistence Farmer	21-Apr-1990
1435	20083731	Morea Gau	F	POREBADA WEST	Household Duties	03-May-1962
1436	20131391	Morea Gaudi	F	POREBADA WEST	Student	19-May-1995
1437	20130986	Morea Geua	F	POREBADA WEST	Household Duties	16-Apr-1987
1438	20067954	Morea Gigi Hitolo	F	POREBADA WEST	Household Duties	01-Jan-1984
1439	20092320	Morea Hebou	F	POREBADA WEST	Household Duties	02-Jan-1988
1440	20218319	Morea Karoho	F	POREBADA WEST	Not Specified	22-May-1973
1441	20007462	MOREA KEVAU	F	POREBADA WEST	Unemployed	01-Jan-1978
1442	20218320	Morea Konio	F	POREBADA WEST	Not Specified	07-Dec-2000
1443	20023229	Morea Loa	F	POREBADA WEST	Teacher	13-Aug-1983
1444	20009160	MOREA LOA CAROLYNE	F	POREBADA WEST	Security	11-May-1989
1445	20131380	Morea Maria	F	POREBADA WEST	Household Duties	01-Jun-1995
1446	20131390	Morea Rakatani	F	POREBADA WEST	Self Employed	08-Nov-1961
1447	20094421	Morea Rebecca	F	POREBADA WEST	Household Duties	12-May-1979
1448	20072513	Morea Taboro	F	POREBADA WEST	Household Duties	16-Aug-1956
1449	20087696	Morea Tarani	F	POREBADA WEST	Household Duties	01-Jan-1968
1450	20218321	Morea Vavine	F	POREBADA WEST	Not Specified	23-Oct-1993
1451	20033007	Morea Asi Hebou	F	POREBADA WEST	Household Duties	20-Oct-1986
1452	20062415	Morea Auani Loa	F	POREBADA WEST	Teacher	18-Jul-1981
1453	20022694	Morea Baru Mareva	F	POREBADA WEST	Student	18-Sep-1992
1454	20218322	Morea Dairi Renagi	F	POREBADA WEST	Not Specified	29-Apr-1986
1455	20034144	Morea Dairi Stella	F	POREBADA WEST	Teacher	01-Jan-1962
1456	20033622	Morea Gari Aro	F	POREBADA WEST	Household Duties	01-Jan-1970
1457	20004705	MOREA GAU BOLO	F	POREBADA WEST	Household Duties	01-Jun-1978
1458	20051350	Morea Gure Ranu	F	POREBADA WEST	Household Duties	28-Oct-1958
1459	20004109	MOREA HEAGI RAKA	F	POREBADA WEST	Household Duties	18-Sep-1990
1460	20085730	Morea Henao Konio	F	POREBADA WEST	Household Duties	02-Nov-1955
1461	20218323	Morea Heni Boio	F	POREBADA WEST	Not Specified	08-Dec-2000
1462	20094430	Morea Hitolo Geua Jnr	F	POREBADA WEST	Household Duties	20-Nov-1977
1463	20059278	Morea Hitolo Heni	F	POREBADA WEST	Librarian	27-Apr-1954
1464	20061888	Morea Hitolo Nohokau Kaia	F	POREBADA WEST	Self Employed	17-May-1972
1465	20076524	Morea Igo Henao	F	POREBADA WEST	Household Duties	17-Feb-1963
1466	20090453	Morea Igo Idau	F	POREBADA WEST	Household Duties	05-May-1954
1467	20090477	Morea Igo Nao	F	POREBADA WEST	Household Duties	03-Mar-1969
1468	20076732	Morea Isaiah Boga	F	POREBADA WEST	Household Duties	13-Jun-1981
1469	20057209	Morea Isaiah Dobi	F	POREBADA WEST	Household Duties	08-Jul-1983
1470	20034300	Morea Koi Kovea	F	POREBADA WEST	Household Duties	31-Jul-1971
1471	20054293	Morea Kokoro Kokoro	F	POREBADA WEST	Household Duties	01-Jan-1960
1472	20032503	Morea Kokoro Raka	F	POREBADA WEST	Household Duties	01-Jan-1963
1473	20067599	Morea Lohia Loa	F	POREBADA WEST	Teacher	11-Aug-1983
1474	20025269	Morea Mea Gaudi	F	POREBADA WEST	Clerk	01-Jan-1965
1475	20032175	Morea Mea Vada	F	POREBADA WEST	Household Duties	01-Jan-1986
1476	20004595	MOREA MOREA NOU	F	POREBADA WEST	Household Duties	13-Aug-1989
1477	20004562	MOREA MOREA RENAGI	F	POREBADA WEST	Self Employed	03-Jan-1992
1478	20002926	MOREA NONO TARUPA	F	POREBADA WEST	Clerk	07-Jul-1986
1479	20008960	MOREA PAUTANI KEVAU	F	POREBADA WEST	Unemployed	12-Jul-1978
1480	20067907	Morea Pautani Mea	F	POREBADA WEST	Household Duties	09-Jul-1976
1481	20032600	Morea Rapu Geua	F	POREBADA WEST	Student	01-Jan-1988
1482	20064507	Morea Riu Mea	F	POREBADA WEST	Household Duties	20-Jan-1968
1483	20033110	Morea Simon Boga	F	POREBADA WEST	Household Duties	10-Jun-1980
1484	20089788	Morea Sioni Boio	F	POREBADA WEST	Household Duties	01-Jun-1978
1485	20054316	Morea Tara Geua Boio	F	POREBADA WEST	Household Duties	11-May-1961
1486	20218327	Morea Tara Hitolo	F	POREBADA WEST	Not Specified	01-Sep-2001
1487	20062438	Morea Taumaku Bede	F	POREBADA WEST	Self Employed	01-Jan-1981
1488	20085496	Morea Taumaku Geua	F	POREBADA WEST	Public Servant	20-Nov-1976
1489	20092377	Morea Taumaku Igo	F	POREBADA WEST	Self Employed	19-Mar-1955
1490	20022691	Morea Taumaku Kone	F	POREBADA WEST	Self Employed	23-Sep-1992
1491	20090349	Morea Taumaku Seri	F	POREBADA WEST	Self Employed	06-Mar-1984
1492	20069271	Morea Taumaku Tara	F	POREBADA WEST	Self Employed	30-Oct-1984
1493	20031897	Morea Taumaku Hitolo Mea	F	POREBADA WEST	Household Duties	08-Sep-1980
1494	20069558	Morea Toea Bede	F	POREBADA WEST	Household Duties	03-Dec-1963
1495	20034377	Morea Toea Geua	F	POREBADA WEST	Household Duties	01-Jan-1955
1496	20008967	MOREA VABURI RAMA	F	POREBADA WEST	Household Duties	15-Apr-1965
1497	20031926	Morea Vagi Kari	F	POREBADA WEST	Household Duties	01-Jan-1971
1498	20197985	Morga Geua	F	POREBADA WEST	Unemployed	16-Apr-1987
1499	20218329	Naime Eunuch Palo	F	POREBADA WEST	Not Specified	28-Nov-1999
1500	20018020	Naime Geua	F	POREBADA WEST	Student	30-Jan-1994
1501	20008327	NANAI RABIA	F	POREBADA WEST	Not Specified	01-Jan-1973
1502	20083504	Nelson Marty	F	POREBADA WEST	Household Duties	18-Aug-1986
1503	20131336	Nohokau Asenagi	F	POREBADA WEST	Fisherman	13-Sep-1997
1504	20124816	Nohokau Dairi	F	POREBADA WEST	Teacher	24-Nov-1984
1505	20008978	NOHOKAU GUNIKA	F	POREBADA WEST	Unemployed	01-Jan-1990
1506	20061937	Nohokau Heni	F	POREBADA WEST	Self Employed	07-Jul-1987
1507	20059301	Nohokau Mere	F	POREBADA WEST	Self Employed	08-Dec-1983
1508	20088142	Nohokau Vagi	F	POREBADA WEST	Self Employed	27-Mar-1987
1509	20124206	Nono Kovea Beni	F	POREBADA WEST	Household Duties	13-Aug-1989
1510	20092350	Oa Rose	F	POREBADA WEST	Student	01-Jun-1987
1511	20085511	Oahui Riu Moro	F	POREBADA WEST	Household Duties	04-Jun-1972
1512	20089781	Oda Bodibo	F	POREBADA WEST	Household Duties	10-Sep-1963
1513	20076739	Oda Dairi	F	POREBADA WEST	Household Duties	08-Aug-1960
1514	20218331	Oda Geva	F	POREBADA WEST	Not Specified	28-Nov-2002
1515	20218332	Oda Hannah	F	POREBADA WEST	Not Specified	06-Sep-2003
1516	20094444	Oda Hitolo	F	POREBADA WEST	Public Servant	01-Jan-1980
1517	20056783	Oda Mea Sisia	F	POREBADA WEST	Self Employed	16-May-1987
1518	20087689	Oda Sibona	F	POREBADA WEST	Subsistence Farmer	02-Jan-2000
1519	20079107	Oda Baru Mebo	F	POREBADA WEST	Subsistence Farmer	27-Sep-1978
1520	20034129	Oda Dairi Bisi	F	POREBADA WEST	Household Duties	02-Oct-1963
1521	20218334	Oda Gorogo Loa	F	POREBADA WEST	Not Specified	25-Feb-1997
1522	20022359	Oda Rei Dobi	F	POREBADA WEST	Household Duties	28-Mar-1979
1523	20092369	Oda Rei Ume	F	POREBADA WEST	Household Duties	10-May-1985
1524	20054766	Oda Vagi Raka	F	POREBADA WEST	Unemployed	31-Oct-1968
1525	20051156	Oda Varuko Dairi	F	POREBADA WEST	Self Employed	01-Sep-2000
1526	20085351	Ora Logea	F	POREBADA WEST	Household Duties	01-Jan-1973
1527	20056624	Ovia Hebou	F	POREBADA WEST	Household Duties	01-Sep-1974
1528	20025282	Ovia Simon Boga	F	POREBADA WEST	Secretary	27-Jun-1982
1529	20001484	PAKO GAU	F	POREBADA WEST	Student	01-Dec-1993
1530	20087404	Pako Kaia Kari	F	POREBADA WEST	Accountant	01-Jan-1970
1531	20094412	Pala Avia	F	POREBADA WEST	Household Duties	07-Jun-1977
1532	20094426	Pala Dorah	F	POREBADA WEST	Teacher	01-Jan-1961
1533	20008744	PALA GARIA	F	POREBADA WEST	Unemployed	01-Jan-1957
1534	20079093	Pala Gohuke	F	POREBADA WEST	Household Duties	19-Aug-1963
1535	20022412	Pala Maryanne	F	POREBADA WEST	Household Duties	08-Feb-1983
1536	20094429	Pala Michelle	F	POREBADA WEST	Teacher	01-Jan-1980
1537	20218336	Pala Morea	F	POREBADA WEST	Not Specified	31-Jan-1996
1538	20123501	PALA Nasareth	F	POREBADA WEST	Household Duties	18-Sep-1993
1539	20218337	Palia Wasita	F	POREBADA WEST	Not Specified	11-Aug-1999
1540	20054269	Parakis Laura	F	POREBADA WEST	Household Duties	01-Jan-1978
1541	20218338	Parau Jnr Philemona	F	POREBADA WEST	Not Specified	08-Oct-1992
1542	20218339	Patrick Gau Konio	F	POREBADA WEST	Not Specified	28-Mar-1994
1543	20008336	PAUTANI KEVAU MOREA	F	POREBADA WEST	Not Specified	01-Jan-1978
1544	20054207	Pautani Arua Mea	F	POREBADA WEST	Household Duties	05-Jul-1974
1545	20079047	Peter Hitolo	F	POREBADA WEST	Household Duties	23-Apr-1967
1546	20131124	Peter Kaia	F	POREBADA WEST	Accountant	25-Nov-1998
1547	20023230	Peter Loa Kone	F	POREBADA WEST	Worker	10-Jul-1960
1548	20023649	Peter Patricia	F	POREBADA WEST	Student	08-Mar-1985
1549	20090335	Peter Seri	F	POREBADA WEST	Household Duties	03-Feb-1981
1550	20124210	Peter Vagi Bisi	F	POREBADA WEST	Administrator	12-Feb-1989
1551	20069278	Peter Goata Gabae	F	POREBADA WEST	Household Duties	21-Sep-1963
1552	20092802	Peter Lohia Buruka	F	POREBADA WEST	Household Duties	01-Jan-1969
1553	20031818	Peter Lohia Gabae	F	POREBADA WEST	Household Duties	21-Sep-1963
1554	20094552	Peter Lohia Geua	F	POREBADA WEST	Household Duties	03-Oct-1986
1555	20064490	Pilu Henao	F	POREBADA WEST	Household Duties	13-Jun-1977
1556	20083936	Pune Toua	F	POREBADA WEST	Household Duties	21-Jan-1975
1557	20218342	Pune Tara Biru	F	POREBADA WEST	Not Specified	09-Feb-2000
1558	20004612	RAGANA VAGI ASI	F	POREBADA WEST	Household Duties	16-May-1989
1559	20094546	Raka Geua  Jrn	F	POREBADA WEST	Household Duties	01-Dec-1975
1560	20081125	Raka Geua  Srn	F	POREBADA WEST	Household Duties	01-Jun-2000
1561	20069656	Raka Rakatani	F	POREBADA WEST	Household Duties	01-Jan-1965
1562	20131376	Raka Rakatani	F	POREBADA WEST	Household Duties	08-Nov-1964
1563	20125726	Raka Vavine	F	POREBADA WEST	Worker	23-Jan-1984
1564	20197983	Rakatani Gege	F	POREBADA WEST	Worker	08-May-1969
1565	20218344	Rakatani Hebou	F	POREBADA WEST	Not Specified	26-Jul-1991
1566	20051339	Rakatani Henao	F	POREBADA WEST	Student	27-May-1985
1567	20061927	Rakatani Isaiah	F	POREBADA WEST	Clerk	24-Mar-1964
1568	20064556	Rakatani Mea	F	POREBADA WEST	Household Duties	20-Sep-1958
1569	20064954	Rakatani Merolyn	F	POREBADA WEST	Household Duties	22-Dec-1978
1570	20218345	Rakatani Susie	F	POREBADA WEST	Not Specified	15-Aug-1972
1571	20094519	Rakatani Henry Arua	F	POREBADA WEST	Not Specified	14-Oct-1977
1572	20033841	Rakatani Henry Geua	F	POREBADA WEST	Household Duties	03-Nov-1986
1573	20005033	RAKATANI HENRY KONIO	F	POREBADA WEST	Household Duties	05-May-1989
1574	20094534	Rakatani Mataio Geua	F	POREBADA WEST	Self Employed	28-Sep-1980
1575	20094551	Rakatani Mataio Henao	F	POREBADA WEST	Student	01-Apr-1986
1576	20094562	Rakatani Mataio Lora	F	POREBADA WEST	Self Employed	01-Jan-1984
1577	20218347	Raki Gege Geno	F	POREBADA WEST	Not Specified	15-Jul-1976
1578	20124852	Ramond Delmai Kila	F	POREBADA WEST	Catering	12-Dec-1992
1579	20090347	Ray Emily	F	POREBADA WEST	Household Duties	21-Dec-1954
1580	20131362	Ray Kori	F	POREBADA WEST	Student	20-Jun-1997
1581	20085514	Ray Heni Hitolo	F	POREBADA WEST	Household Duties	23-Aug-1986
1582	20131395	Raymond Heagi	F	POREBADA WEST	Student	24-Jun-1997
1583	20131370	Raymond Viki	F	POREBADA WEST	Household Duties	27-Jan-1987
1584	20004579	REA MOREA TOREA	F	POREBADA WEST	Household Duties	06-Nov-1990
1585	20009170	REI EMILY ODA	F	POREBADA WEST	Clerk	31-Dec-1976
1586	20092367	Rei Mora	F	POREBADA WEST	Household Duties	01-Jan-1957
1587	20124215	Riu Busina Dobi	F	POREBADA WEST	Household Duties	10-May-1986
1588	20008265	RIU GEGE	F	POREBADA WEST	Worker	01-Jan-1970
1589	20218351	Riu Henao	F	POREBADA WEST	Not Specified	03-Mar-2004
1590	20124218	Riu Morea Mea	F	POREBADA WEST	Household Duties	20-Jan-1969
1591	20023159	Riu Moro	F	POREBADA WEST	Household Duties	04-Jun-1972
1592	20218352	Riu Roselyn	F	POREBADA WEST	Not Specified	17-Jan-2001
1593	20089869	Riu Vagi	F	POREBADA WEST	Household Duties	02-Feb-1970
1594	20002516	RIU EGUTA KONE	F	POREBADA WEST	Household Duties	27-Jun-1990
1595	20050675	Riu Heagi Hebou	F	POREBADA WEST	Household Duties	12-Mar-1972
1596	20076482	Riu Heagi Keruma	F	POREBADA WEST	Teacher	24-Oct-1967
1597	20085504	Riu Maraga Vagi	F	POREBADA WEST	Household Duties	18-May-1945
1598	20083582	Rocky Rerea	F	POREBADA WEST	Household Duties	22-Feb-1979
1599	20057191	Rosi Seri	F	POREBADA WEST	Household Duties	13-Jun-1968
1600	20056798	Rui Dobi	F	POREBADA WEST	Self Employed	10-May-1986
1601	20034368	Sabadi Rose	F	POREBADA WEST	Household Duties	07-Nov-1973
1602	20005039	SAM AHUTA	F	POREBADA WEST	Store Keeper	12-Nov-1992
1603	20218354	Sam Morea Barbara	F	POREBADA WEST	Not Specified	02-Aug-1988
1604	20124921	Sama Keruma	F	POREBADA WEST	Pastor	06-Aug-1974
1605	20218355	Samon Rama	F	POREBADA WEST	Not Specified	07-Jun-2002
1606	20218356	Sariman Lillian	F	POREBADA WEST	Not Specified	09-Nov-1984
1607	20089757	Saufa Lucy	F	POREBADA WEST	Student	14-Mar-1989
1608	20022390	Saura Daro	F	POREBADA WEST	Household Duties	27-Jul-1981
1609	20032152	Sega Maba Geno	F	POREBADA WEST	Household Duties	11-Apr-1977
1610	20124219	Seri Gau Michel	F	POREBADA WEST	Household Duties	17-Jun-1977
1611	20059295	Seri Hitolo	F	POREBADA WEST	Household Duties	06-Apr-1962
1612	20081112	Seri Lucy	F	POREBADA WEST	Self Employed	30-Apr-1985
1613	20081111	Seri Rama	F	POREBADA WEST	Self Employed	26-Sep-1981
1614	20069555	Seri Ranu	F	POREBADA WEST	Household Duties	03-Sep-1957
1615	20072566	Seri Taia	F	POREBADA WEST	Household Duties	19-Sep-1966
1616	20003659	SERI ALESA HARORO	F	POREBADA WEST	Household Duties	20-Nov-1963
1617	20003352	SERI ASI GEUA	F	POREBADA WEST	Student	18-Mar-1993
1618	20079182	Seri Bitu Lucy	F	POREBADA WEST	Household Duties	01-Jan-1959
1619	20094435	Seri Oa Muraka	F	POREBADA WEST	Household Duties	16-Apr-1952
1620	20056654	Seri Oda Virobo	F	POREBADA WEST	Household Duties	07-May-1977
1621	20005024	SERI PUNE GEUA	F	POREBADA WEST	Household Duties	07-Jul-1991
1622	20002804	SERI TOLO MIRIAM	F	POREBADA WEST	Household Duties	21-Aug-1994
1623	20123492	SIAGE BOIO	F	POREBADA WEST	Unemployed	29-Mar-1993
1624	20076434	Siage Doris	F	POREBADA WEST	Household Duties	01-Jan-1969
1625	20076433	Siage Naina	F	POREBADA WEST	Household Duties	01-Jan-1975
1626	20090487	Siage Hera Raka	F	POREBADA WEST	Household Duties	19-Sep-1960
1627	20087678	Siage Vaburi Kari	F	POREBADA WEST	Household Duties	15-May-1969
1628	20022678	Simon Mea	F	POREBADA WEST	Household Duties	30-Oct-1990
1629	20094483	Simon Heagi Geua	F	POREBADA WEST	Church Worker	01-Jan-1955
1630	20004673	SIONI BOIO	F	POREBADA WEST	Household Duties	01-Jun-1978
1631	20090485	Sioni Vagi Lydia	F	POREBADA WEST	Worker	16-Oct-1976
1632	20083929	Sioni Vele Dobi	F	POREBADA WEST	Household Duties	05-Mar-1962
1633	20090269	Siosi Roguro	F	POREBADA WEST	Household Duties	06-Jan-1980
1634	20064550	Sisia Kila	F	POREBADA WEST	Household Duties	29-Sep-1950
1635	20088141	Sisia Bitu Kovea	F	POREBADA WEST	Household Duties	02-Jan-2000
1636	20005518	SISIA KOVEA VAHU	F	POREBADA WEST	Worker	15-Sep-1992
1637	20051351	Sisia Morea Kaia	F	POREBADA WEST	Self Employed	01-Sep-1982
1638	20003406	SISIA TARAVATU KOVEA	F	POREBADA WEST	Household Duties	01-Aug-1992
1639	20123497	Soge Navu	F	POREBADA WEST	Pastor	01-Jan-1965
1640	20131354	Sonny Virobo	F	POREBADA WEST	Student	26-Jun-1996
1641	20022351	Stanislos Pascaline	F	POREBADA WEST	Catering	15-Apr-1984
1642	20218361	Stanley Aida	F	POREBADA WEST	Not Specified	13-Nov-2000
1643	20218362	Stanley Hitolo	F	POREBADA WEST	Not Specified	07-Dec-1994
1644	20130612	Tabe Boio	F	POREBADA WEST	Household Duties	26-Jun-1995
1645	20022361	Tabe Noelin	F	POREBADA WEST	Household Duties	19-Oct-1992
1646	20017854	Tapa Franny	F	POREBADA WEST	Household Duties	01-Feb-1992
1647	20005574	TARA KAIA	F	POREBADA WEST	Unemployed	01-Jan-1962
1648	20022393	Tara Karoho	F	POREBADA WEST	Household Duties	28-Oct-1989
1649	20079086	Tara Mebo	F	POREBADA WEST	Self Employed	12-Feb-1982
1650	20007251	TARA REBECCA	F	POREBADA WEST	Unemployed	01-Jan-1990
1651	20017851	Tara Riku	F	POREBADA WEST	Student	08-Jul-1993
1652	20090333	Tara Henao Hane	F	POREBADA WEST	Worker	12-Nov-1966
1653	20085506	Taravatu Asi	F	POREBADA WEST	Household Duties	24-Aug-1959
1654	20085716	Taravatu Ebo	F	POREBADA WEST	Household Duties	18-Dec-1964
1655	20085499	Taravatu Hua	F	POREBADA WEST	Household Duties	27-Apr-1978
1656	20083925	Taravatu Maraga	F	POREBADA WEST	Household Duties	18-Mar-1975
1657	20085720	Taravatu Seri	F	POREBADA WEST	Household Duties	10-Sep-1957
1658	20067968	Taravatu Bitu Mea	F	POREBADA WEST	Household Duties	10-Aug-1973
1659	20007217	TARAVATU SIMON SERI	F	POREBADA WEST	Household Duties	04-May-1988
1660	20076568	Tarupa Kari	F	POREBADA WEST	Stenographer	14-Sep-1974
1661	20085507	Tau Gamini	F	POREBADA WEST	Household Duties	29-Jul-1969
1662	20218363	Tau Hane	F	POREBADA WEST	Not Specified	02-Sep-1991
1663	20087705	Tau Taravatu Ruta	F	POREBADA WEST	Household Duties	10-Aug-1970
1664	20031438	Tau Vaburi Loa	F	POREBADA WEST	Household Duties	01-Jan-1964
1665	20009453	TAU VABURI GAHUSI LUCY	F	POREBADA WEST	Household Duties	10-May-1999
1666	20123517	Tauedea Boio Maria	F	POREBADA WEST	Household Duties	02-Oct-1986
1667	20072982	Tauedea Gau	F	POREBADA WEST	Household Duties	25-Sep-1989
1668	20002543	TAUEDEA BARU GAU	F	POREBADA WEST	Household Duties	26-Sep-1988
1669	20036014	Tauedea Oda Dobi	F	POREBADA WEST	Self Employed	01-Jan-1974
1670	20197995	Taumaku Bede	F	POREBADA WEST	Student	12-Sep-1997
1671	20008573	TAUMAKU DORIGA LOHIA	F	POREBADA WEST	Worker	29-Oct-1992
1672	20083573	Taumaku Elisa	F	POREBADA WEST	Household Duties	14-Mar-1972
1673	20057204	Taumaku Lohia	F	POREBADA WEST	Typist	29-Sep-1969
1674	20068082	Taumaku Vaburi	F	POREBADA WEST	Clerk	01-Jan-1968
1675	20031825	Taumaku Koitabu Mea	F	POREBADA WEST	Household Duties	18-Nov-1966
1676	20061908	Taumaku Morea Bede	F	POREBADA WEST	Not Specified	08-Dec-1955
1677	20022415	Taumaku Morea Kone	F	POREBADA WEST	Household Duties	05-Mar-1957
1678	20036682	Taunao Dorido Kaia	F	POREBADA WEST	Household Duties	01-Jan-1976
1679	20218365	Taunao Loi Georgina	F	POREBADA WEST	Not Specified	09-Nov-1979
1680	20123516	Tauvaburi Boio	F	POREBADA WEST	Self Employed	23-Sep-1954
1681	20064494	Toea Igo	F	POREBADA WEST	Clerk	30-Dec-1978
1682	20218367	Toea Gorogo Geva	F	POREBADA WEST	Not Specified	06-Oct-1999
1683	20092807	Toea Morea Keruma	F	POREBADA WEST	Self Employed	11-Jun-1988
1684	20004574	TOEA MOREA RAMA	F	POREBADA WEST	Household Duties	04-Dec-1972
1685	20034640	Toea Morea Walo	F	POREBADA WEST	Household Duties	29-Jan-1976
1686	20009425	TOEA RAKA MEA	F	POREBADA WEST	Self Employed	29-Oct-1990
1687	20092334	Tolo Boio	F	POREBADA WEST	Household Duties	09-May-1958
1688	20069287	Tolo Kaia	F	POREBADA WEST	Household Duties	12-Aug-1955
1689	20069282	Tolo Lillian	F	POREBADA WEST	Household Duties	26-Jan-1983
1690	20054770	Tolo Naomi	F	POREBADA WEST	Household Duties	17-Mar-1947
1691	20067965	Tolo Rei	F	POREBADA WEST	Secretary	25-Mar-1965
1692	20090501	Tolo Samoa	F	POREBADA WEST	Self Employed	20-Aug-1988
1693	20064938	Tore Elizabeth	F	POREBADA WEST	Household Duties	01-Jan-1958
1694	20094475	Toua Mea Kari	F	POREBADA WEST	Household Duties	09-Apr-1969
1695	20005063	TOUA MEA TARA KAIA	F	POREBADA WEST	Pastor	12-Mar-1967
1696	20083598	Vaburi Dobi	F	POREBADA WEST	Household Duties	01-Jan-1978
1697	20087425	Vaburi Henao	F	POREBADA WEST	Clerk	12-Dec-1969
1698	20003617	VABURI WALO	F	POREBADA WEST	Household Duties	12-Feb-1993
1699	20085517	Vaburi Morea Rama	F	POREBADA WEST	Household Duties	15-Apr-1965
1700	20218370	Vaburu Keruma	F	POREBADA WEST	Not Specified	03-Aug-2001
1701	20090406	Vagi Boni	F	POREBADA WEST	Self Employed	24-Aug-1955
1702	20197977	Vagi Carolyn	F	POREBADA WEST	Unemployed	23-Nov-1997
1703	20076421	Vagi Cesly	F	POREBADA WEST	Household Duties	01-Jan-1975
1704	20079070	Vagi Garia	F	POREBADA WEST	Household Duties	17-Oct-1957
1705	20131119	Vagi Henao	F	POREBADA WEST	Household Duties	30-May-1962
1706	20218372	Vagi Iru	F	POREBADA WEST	Not Specified	01-Aug-2000
1707	20197975	Vagi Kokoro	F	POREBADA WEST	Unemployed	23-Jan-1996
1708	20124227	Vagi Mali  Igo	F	POREBADA WEST	Household Duties	22-Dec-1982
1709	20009053	VAGI MAURI	F	POREBADA WEST	Unemployed	01-Jan-1993
1710	20092706	Vagi Mere	F	POREBADA WEST	Household Duties	03-Oct-1966
1711	20068062	Vagi Nou	F	POREBADA WEST	Household Duties	27-Apr-1956
1712	20124229	Vagi Pune Henao	F	POREBADA WEST	Household Duties	17-Oct-1986
1713	20124231	Vagi Pune Taia	F	POREBADA WEST	Clerk	19-Sep-1966
1714	20051334	Vagi Roguro	F	POREBADA WEST	Self Employed	12-Sep-1986
1715	20004700	VAGI ARERE SIBONA	F	POREBADA WEST	Household Duties	24-Feb-1945
1716	20083931	Vagi Arua Gomara	F	POREBADA WEST	Household Duties	01-Jan-1983
1717	20092795	Vagi Gahusi Hegame	F	POREBADA WEST	Household Duties	11-Nov-1974
1718	20218374	Vagi Heni Henai	F	POREBADA WEST	Not Specified	25-Jun-1976
1719	20092801	Vagi Hera Ahuta	F	POREBADA WEST	Household Duties	02-Feb-1957
1720	20002927	VAGI NONO GEUA	F	POREBADA WEST	Household Duties	24-Apr-1963
1721	20072989	Vagi Ola Henao	F	POREBADA WEST	Household Duties	16-Aug-1950
1722	20218375	Vagi Tabe Jennifer	F	POREBADA WEST	Not Specified	16-Feb-1961
1723	20218377	Vaguia Siritana	F	POREBADA WEST	Not Specified	25-May-1985
1724	20002938	VAINO AIVA	F	POREBADA WEST	Household Duties	06-Dec-1983
1725	20056799	Vaino Ana	F	POREBADA WEST	Receptionist	01-Jan-1985
1726	20002810	VAINO HELEN	F	POREBADA WEST	Household Duties	24-Apr-1989
1727	20003336	VANUA GALEVA	F	POREBADA WEST	Self Employed	24-Apr-1994
1728	20125725	Varona Lydia	F	POREBADA WEST	Household Duties	01-Jan-1990
1729	20087711	Varubi Sisia Kari	F	POREBADA WEST	Household Duties	15-Mar-1961
1730	20218378	Varuko Henao	F	POREBADA WEST	Not Specified	01-Dec-1974
1731	20072351	Varuko Mea	F	POREBADA WEST	Household Duties	03-Sep-1979
1732	20079012	Varuko Nao	F	POREBADA WEST	Household Duties	28-Apr-1969
1733	20218379	Varuko Pauline	F	POREBADA WEST	Not Specified	07-Jun-2001
1734	20124235	Varuko Vagi Rama	F	POREBADA WEST	Household Duties	05-Nov-1962
1735	20081106	Vele Dina	F	POREBADA WEST	Household Duties	26-Sep-1971
1736	20094344	Vele Doreka	F	POREBADA WEST	Self Employed	09-Nov-1984
1737	20022350	Vele Iru	F	POREBADA WEST	Household Duties	25-Apr-1990
1738	20094443	Vele Muraka	F	POREBADA WEST	Household Duties	23-Jan-1986
1739	20092590	Vele Gari Geua	F	POREBADA WEST	Self Employed	19-Nov-1988
1740	20085725	Vele Koita Hebou	F	POREBADA WEST	Household Duties	01-Jan-1980
1741	20087375	Virobo Heni	F	POREBADA WEST	Subsistence Farmer	06-Jun-1958
1742	20087381	Virobo Oala	F	POREBADA WEST	Self Employed	09-Oct-1985
1743	20087398	Virobo Taumaku	F	POREBADA WEST	Subsistence Farmer	29-Jun-1959
1744	20218380	Walo Konio	F	POREBADA WEST	Not Specified	29-Aug-1985
1745	20218381	Walo Kori	F	POREBADA WEST	Not Specified	27-May-1975
1746	20197976	Willie Beatrice	F	POREBADA WEST	Unemployed	30-Jul-1988
1747	20022365	Wilson Wilma	F	POREBADA WEST	Student	09-Mar-1992
\.


--
-- Name: porebada_ward_economics porebada_ward_economics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.porebada_ward_economics
    ADD CONSTRAINT porebada_ward_economics_pkey PRIMARY KEY (ward_id);


--
-- Name: porebada_ward_education porebada_ward_education_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.porebada_ward_education
    ADD CONSTRAINT porebada_ward_education_pkey PRIMARY KEY (ward_id);


--
-- Name: porebada_ward_geography porebada_ward_geography_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.porebada_ward_geography
    ADD CONSTRAINT porebada_ward_geography_pkey PRIMARY KEY (ward_id);


--
-- Name: porebada_ward_health porebada_ward_health_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.porebada_ward_health
    ADD CONSTRAINT porebada_ward_health_pkey PRIMARY KEY (ward_id);


--
-- Name: porebada_ward_infrastructure porebada_ward_infrastructure_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.porebada_ward_infrastructure
    ADD CONSTRAINT porebada_ward_infrastructure_pkey PRIMARY KEY (ward_id);


--
-- PostgreSQL database dump complete
--

