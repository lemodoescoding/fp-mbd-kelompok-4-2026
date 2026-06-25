CREATE ROLE biro_aset_role;

GRANT SELECT, UPDATE ON Ruangan TO biro_aset_role;
GRANT SELECT ON Fasilitas_Ruangan, Fasilitas, Departemen TO biro_aset_role;
GRANT SELECT, UPDATE ON Peminjaman TO biro_aset_role;
GRANT SELECT ON Peminjaman_Ruangan, StatusPeminjaman, Mahasiswa TO biro_aset_role;

CREATE POLICY biro_aset_all_rooms ON Ruangan
    FOR ALL
    TO biro_aset_role
    USING (true);