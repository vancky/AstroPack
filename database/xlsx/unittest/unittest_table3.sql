

CREATE TABLE public.table3 (
RecID VARCHAR NOT NULL,
FDouble1 DOUBLE PRECISION DEFAULT 0,
FDouble2 DOUBLE PRECISION DEFAULT 0,
FDouble3 DOUBLE PRECISION DEFAULT 0,
FInt1 INTEGER DEFAULT 0,
FInt2 INTEGER DEFAULT 0,
FInt3 INTEGER DEFAULT 0,
FString1 VARCHAR,
FString2 VARCHAR,
FString3 VARCHAR,

CONSTRAINT table3_pkey PRIMARY KEY(RecID)
);
