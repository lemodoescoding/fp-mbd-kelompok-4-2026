CREATE ROLE tendik_departemen_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON Ruangan TO tendik_departemen_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Fasilitas_Ruangan TO tendik_departemen_role;
GRANT SELECT ON Fasilitas, Departemen TO tendik_departemen_role;

GRANT SELECT ON Peminjaman, Peminjaman_Ruangan, StatusPeminjaman, Mahasiswa TO tendik_departemen_role;

ALTER TABLE Ruangan ENABLE ROW LEVEL SECURITY;

CREATE POLICY tendik_departemen_rooms ON Ruangan
    FOR ALL
    TO tendik_departemen_role
    USING (Departemen_id_departemen IS NOT NULL);