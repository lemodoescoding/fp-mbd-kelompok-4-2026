CREATE ROLE mahasiswa_role;

GRANT SELECT ON Ruangan, Fasilitas, Fasilitas_Ruangan, Departemen TO mahasiswa_role;

GRANT SELECT, INSERT ON Peminjaman TO mahasiswa_role;
GRANT SELECT, INSERT ON Peminjaman_Ruangan TO mahasiswa_role;

ALTER TABLE Peminjaman ENABLE ROW LEVEL SECURITY;

CREATE POLICY mahasiswa_own_peminjaman ON Peminjaman
    FOR ALL
    TO mahasiswa_role
    USING (Mahasiswa_nrp = current_setting('app.current_nrp'));