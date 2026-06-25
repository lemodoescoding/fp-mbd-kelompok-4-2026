CREATE ROLE tendik_departemen_role;

GRANT SELECT, INSERT, UPDATE ON Ruangan TO tendik_departemen_role;
GRANT SELECT, INSERT ON Fasilitas_Ruangan TO tendik_departemen_role;
GRANT SELECT, INSERT ON Fasilitas TO tendik_departemen_role;
GRANT SELECT ON Departemen TO tendik_departemen_role;

ALTER TABLE Ruangan ENABLE ROW LEVEL SECURITY;
CREATE POLICY tendik_departemen_rooms ON Ruangan
    FOR ALL
    TO tendik_departemen_role
    USING (Departemen_id_departemen IS NOT NULL);