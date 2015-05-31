L0 = LOAD 's3://kls-omniture/inputdata/Omniture.0.tsv.gz' USING PigStorage();
L1 = LOAD 's3://kls-omniture/inputdata/Omniture.1.tsv.gz' USING PigStorage();
L2 = LOAD 's3://kls-omniture/inputdata/Omniture.2.tsv.gz' USING PigStorage();
L3 = LOAD 's3://kls-omniture/inputdata/Omniture.3.tsv.gz' USING PigStorage();
L4 = LOAD 's3://kls-omniture/inputdata/Omniture.4.tsv.gz' USING PigStorage();
L5 = LOAD 's3://kls-omniture/inputdata/Omniture.5.tsv.gz' USING PigStorage();
LOG = UNION L0, L1, L2, L3, L4, L5; 
STORE LOG INTO 's3://kls-omniture/outputdata/pigdata' USING PigStorage();