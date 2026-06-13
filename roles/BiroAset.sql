CREATE ROLE biro_aset_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON Ruangan TO biro_aset_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Fasilitas_Ruangan TO biro_aset_role;
GRANT SELECT ON Fasilitas, Departemen TO biro_aset_role;

GRANT SELECT, UPDATE ON Peminjaman TO biro_aset_role;
GRANT SELECT ON Peminjaman_Ruangan, StatusPeminjaman, Mahasiswa TO biro_aset_role;

CREATE POLICY biro_aset_rooms ON Ruangan
    FOR ALL
    TO biro_aset_role
    USING (Departemen_id_departemen IS NULL);