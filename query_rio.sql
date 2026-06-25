-- 1. 2 Query Join

-- 1a. Peminjaman + Peminjaman_Ruangan + Ruangan
SELECT 
p.id_peminjaman,
p.tanggal_pengajuan,
p.detail_waktu_mulai,
p.detail_waktu_selesai,
p.keperluan,
r.nama_ruangan,
r.lokasi,
r.kapasitas
FROM peminjaman p
JOIN Peminjaman_Ruangan pr ON p.id_peminjaman = pr.Peminjaman_id_peminjaman
JOIN Ruangan r ON pr.Ruangan_id_ruangan = r.id_ruangan;

-- 2a. Ruangan + Departemen

SELECT
    d.fakultas,
    COUNT(*) as jumlah_ruangan
FROM Ruangan r
JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
GROUP BY d.fakultas;

-- 2. 2 Query View

-- 2a. Menampilkan Ruangan yang Memiliki Availability

CREATE OR REPLACE VIEW VIEW_RUANGAN_TERSEDIA AS
SELECT
    r.id_ruangan,
    r.nama_ruangan,
    r.lokasi,
    r.kapasitas,
    d.nama AS nama_departemen,
    d.fakultas
FROM Ruangan r
JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
WHERE r.status = TRUE;

SELECT * FROM VIEW_RUANGAN_TERSEDIA LIMIT 10;

-- 2b. Menampilkan Histori Peminjaman yang Dilakukan oleh Satu Mahasiswa

CREATE OR REPLACE VIEW VIEW_HISTORI_PEMINJAMAN_MAHASISWA AS
SELECT
	m.nrp,
	m.nama AS nama_mahasiswa,
	pm.tanggal_pengajuan,
	pm.detail_waktu_mulai,
	pm.detail_waktu_selesai,
	pm.keperluan,
	sp.status
FROM Mahasiswa m
JOIN Peminjaman pm ON m.nrp = pm.Mahasiswa_nrp
JOIN StatusPeminjaman sp ON pm.StatusPeminjaman_id_statuspeminjaman = sp.id_statuspeminjaman; 

SELECT * FROM VIEW_HISTORI_PEMINJAMAN_MAHASISWA;

-- 3. 2 Query Procedure/Function

-- 3a. Menampilkan data peminjaman ruangan yang memiliki status ‘Dibatalkan’ atau ‘Ditolak’

CREATE OR REPLACE FUNCTION FN_HITUNG_PEMINJAMAN_DITOLAK_DIBATALKAN()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM Peminjaman p
    JOIN StatusPeminjaman sp
        ON p.StatusPeminjaman_id_statuspeminjaman = sp.id_statuspeminjaman
    WHERE sp.status IN ('Ditolak', 'Dibatalkan');

    RETURN v_total;
END;
$$;

SELECT FN_HITUNG_PEMINJAMAN_DITOLAK_DIBATALKAN();

-- 3b.  Mencari ruangan yang dengan frekuensi peminjaman paling banyak

CREATE OR REPLACE FUNCTION FN_RUANGAN_FREK_PINJAM_TERBANYAK()
RETURNS VARCHAR(40)
LANGUAGE PLPGSQL
AS $$
DECLARE 
	v_nama_ruangan VARCHAR(40);
BEGIN 
	SELECT r.nama_ruangan INTO v_nama_ruangan
	FROM Ruangan r
	JOIN Peminjaman_Ruangan pr ON pr.Ruangan_id_ruangan = r.id_ruangan
	GROUP BY r.id_ruangan, r.nama_ruangan
	ORDER BY COUNT(*) DESC
	LIMIT 1;

	RETURN v_nama_ruangan;
END;
$$;

SELECT Fn_RUANGAN_FREK_PINJAM_TERBANYAK();

-- 4. 2 Query Trigger + Function/Procedure

-- 4a. Mencegah pembuatan ruangan memiliki kapasitas terlalu sedikit, minimal berkapasitas 5 orang, berjalan saat sebelum operasi INSERT atau UPDATE ke tabel Ruangan
CREATE OR REPLACE FUNCTION FN_CEK_KAPASITAS_RUANGAN()
RETURNS TRIGGER 
LANGUAGE PLPGSQL
AS $$
BEGIN 
	IF NEW.kapasitas < 5 THEN
		RAISE EXCEPTION 'Kapasitas ruangan harus lebih besar dari 5';
	END IF;

	RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER TRG_CEK_MINIMUM_KAPASITAS_RUANGAN
BEFORE INSERT OR UPDATE 
ON Ruangan 
FOR EACH ROW 
EXECUTE FUNCTION FN_CEK_KAPASITAS_RUANGAN();

INSERT INTO Ruangan (
    id_ruangan,
    nama_ruangan,
    lokasi,
    kapasitas,
    status,
    Departemen_id_departemen
)
VALUES (
    'RNG99999',
    'Ruang Error',
    'Gedung Test',
    0,
    TRUE,
    'DEP001'
);

-- 4b. Otomatis mengubah status ruangan menjadi tidak tersedia saat dipinjam

CREATE OR REPLACE FUNCTION FN_UBAH_STATUS_RUANGAN()
RETURNS TRIGGER 
LANGUAGE PLPGSQL
AS $$
DECLARE
	v_status VARCHAR(20);
BEGIN 
	SELECT sp.status INTO v_status
	FROM Peminjaman p
	JOIN StatusPeminjaman sp ON p.StatusPeminjaman_id_statuspeminjaman = sp.id_statuspeminjaman
	WHERE p.id_peminjaman = NEW.Peminjaman_id_peminjaman;


    IF v_status IN (
        'Ditolak',
        'Dibatalkan',
        'Diajukan',
        'Selesai'
    ) THEN
        UPDATE Ruangan
        SET status = TRUE
        WHERE id_ruangan = NEW.Ruangan_id_ruangan;
    ELSE
        UPDATE Ruangan
        SET status = FALSE
        WHERE id_ruangan = NEW.Ruangan_id_ruangan;
    END IF;

	RETURN NEW;
END
$$;

CREATE OR REPLACE TRIGGER TRG_UBAH_STATUS_RUANGAN
AFTER INSERT
ON Peminjaman_Ruangan
FOR EACH ROW
EXECUTE FUNCTION FN_UBAH_STATUS_RUANGAN();


SELECT status
FROM Ruangan
WHERE id_ruangan = 'RNG00001';

INSERT INTO Peminjaman (
    id_peminjaman,
    tanggal_pengajuan,
    detail_waktu_mulai,
    detail_waktu_selesai,
    keperluan,
    Mahasiswa_nrp,
    StatusPeminjaman_id_statuspeminjaman
)
VALUES (
    'PM9910',
    CURRENT_DATE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '2 hour',
    'Rapat UKM',
    '5025241001',
    'ST0002'
);

INSERT INTO Peminjaman_Ruangan (
    Peminjaman_id_peminjaman,
    Ruangan_id_ruangan
)
VALUES (
    'PM9910',
    'RNG00001'
);

SELECT status
FROM Ruangan
WHERE id_ruangan = 'RNG00001';
