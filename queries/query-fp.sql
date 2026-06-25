-- hak akses biro_aset
GRANT CREATE ON SCHEMA public TO biro_aset_role;
GRANT INSERT, SELECT, UPDATE ON peminjaman TO biro_aset_role;
GRANT INSERT, SELECT ON peminjaman_Ruangan TO biro_aset_role;
GRANT TRIGGER ON peminjaman_ruangan TO biro_aset_role;

-- policy agar dapat melakukan insert
CREATE POLICY biro_aset_all ON peminjaman
    FOR ALL TO biro_aset_role
    USING (true) WITH CHECK (true);

CREATE POLICY biro_aset_all ON peminjaman_ruangan
    FOR ALL TO biro_aset_role
    USING (true) WITH CHECK (true);

CREATE POLICY biro_aset_all ON ruangan
    FOR ALL TO biro_aset_role
    USING (true) WITH CHECK (true);


-- memberikan kepemilikan tabel mahasiswa dan ruangan ke biro_aset
ALTER TABLE mahasiswa OWNER to biro_aset_role;
ALTER TABLE ruangan OWNER to biro_aset_role;

-- membuat kolom poin dengan nilai default 0 pada tabel mahasiswa
ALTER TABLE mahasiswa
ADD COLUMN total_poin INT NOT NULL DEFAULT 0;

-- function untuk menambahkan point
CREATE OR REPLACE FUNCTION tambah_poin()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_nrp VARCHAR(20);
    v_bulan INT;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM ruangan
        WHERE id_ruangan = NEW.ruangan_id_ruangan
          AND kapasitas > 50
    ) THEN

        SELECT mahasiswa_nrp,
               EXTRACT(MONTH FROM detail_waktu_mulai)
        INTO v_nrp, v_bulan
        FROM peminjaman
        WHERE id_peminjaman = NEW.peminjaman_id_peminjaman;

        UPDATE mahasiswa
        SET total_poin = total_poin + FLOOR(v_bulan * 0.2)
        WHERE nrp = v_nrp;

    END IF;

    RETURN NEW;
END;
$$;

-- trigger ketika insert pada peminjaman ruangan
CREATE OR REPLACE TRIGGER trigger_tambah_poin
AFTER INSERT ON peminjaman_ruangan
FOR EACH ROW
EXECUTE FUNCTION tambah_poin();

-- kapasitas >50, bulan 6
INSERT INTO Peminjaman (id_peminjaman, tanggal_pengajuan, detail_waktu_mulai, detail_waktu_selesai, keperluan, Mahasiswa_nrp, StatusPeminjaman_id_statuspeminjaman) 
VALUES ('PM9005', '2026-06-09', '2026-06-26 08:00:00', '2026-06-26 10:00:00', 'Gerigi', '5025241005', 'ST0001'); 

INSERT INTO Peminjaman_Ruangan VALUES ('PM9005', 'RNG00002');

-- kapasitas >50, bulam 10
INSERT INTO Peminjaman (id_peminjaman, tanggal_pengajuan, detail_waktu_mulai, detail_waktu_selesai, keperluan, Mahasiswa_nrp, StatusPeminjaman_id_statuspeminjaman) 
VALUES ('PM9006', '2026-10-09', '2026-10-13 08:00:00', '2026-10-13 10:00:00', 'Gerigi', '5025241006', 'ST0001'); 

INSERT INTO Peminjaman_Ruangan VALUES ('PM9006', 'RNG00009');

-- kapasitas <50
INSERT INTO Peminjaman (id_peminjaman, tanggal_pengajuan, detail_waktu_mulai, detail_waktu_selesai, keperluan, Mahasiswa_nrp, StatusPeminjaman_id_statuspeminjaman) 
VALUES ('PM9007', '2026-10-09', '2026-12-14 08:00:00', '2026-12-14 10:00:00', 'Test Trigger 4', '5025241007', 'ST0001'); 

INSERT INTO Peminjaman_Ruangan VALUES ('PM9004', 'RNG00001');

-- cek hasil pada mahasiswa
SELECT nrp, total_poin FROM mahasiswa
WHERE nrp IN ('5025241005', '5025241006', '5025241007');