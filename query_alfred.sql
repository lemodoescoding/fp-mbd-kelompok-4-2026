-- Join 1: Menampilkan pasangan peminjaman pada tanggal yang sama.
SELECT p1.id_peminjaman AS peminjaman_pertama, p2.id_peminjaman AS peminjaman_kedua, p1.detail_waktu_mulai::date AS tanggal_peminjaman
FROM Peminjaman AS p1
JOIN Peminjaman AS p2 ON p1.detail_waktu_mulai::date = p2.detail_waktu_mulai::date AND p1.id_peminjaman < p2.id_peminjaman;

-- Join 2: Menampilkan jeda hari antara pengajuan dan peminjaman.
SELECT p.id_peminjaman, m.nama AS nama_mahasiswa, p.tanggal_pengajuan, p.detail_waktu_mulai::date - p.tanggal_pengajuan AS jeda_hari
FROM Peminjaman AS p
JOIN Mahasiswa AS m ON m.nrp = p.Mahasiswa_nrp
WHERE p.detail_waktu_mulai::date - p.tanggal_pengajuan > 3;

-- View 1: Menampilkan peminjaman yang menggunakan lebih dari satu ruangan.
CREATE OR REPLACE VIEW peminjaman_multi_ruangan AS
SELECT p.id_peminjaman, p.keperluan
FROM Peminjaman AS p
WHERE (
    SELECT COUNT(*) FROM Peminjaman_Ruangan AS pr
    WHERE pr.Peminjaman_id_peminjaman = p.id_peminjaman
) > 1;

-- View 2: Menampilkan peminjaman yang dijadwalkan pada akhir pekan.
CREATE OR REPLACE VIEW peminjaman_akhir_pekan AS
SELECT id_peminjaman, detail_waktu_mulai, detail_waktu_selesai, keperluan
FROM Peminjaman
WHERE EXTRACT(ISODOW FROM detail_waktu_mulai) IN (6, 7);

-- Trigger 1: Memastikan ID peminjaman mengikuti format PM0000.
CREATE OR REPLACE FUNCTION validasi_format_id_peminjaman()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.id_peminjaman !~ '^PM[0-9]{4}$' THEN
        RAISE EXCEPTION
            'ID peminjaman harus menggunakan format PM0000';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validasi_format_id_peminjaman
ON Peminjaman;

CREATE TRIGGER validasi_format_id_peminjaman
BEFORE INSERT OR UPDATE OF id_peminjaman
ON Peminjaman
FOR EACH ROW
EXECUTE FUNCTION validasi_format_id_peminjaman();

-- Trigger 2: Merapikan spasi pada keperluan peminjaman.
CREATE OR REPLACE FUNCTION rapikan_keperluan_peminjaman()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.keperluan := TRIM(NEW.keperluan);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS rapikan_keperluan_peminjaman
ON Peminjaman;

CREATE TRIGGER rapikan_keperluan_peminjaman
BEFORE INSERT OR UPDATE OF keperluan
ON Peminjaman
FOR EACH ROW
EXECUTE FUNCTION rapikan_keperluan_peminjaman();

-- Procedure 1: Memindahkan pengaju peminjaman ke mahasiswa lain.
CREATE OR REPLACE PROCEDURE ubah_mahasiswa_peminjaman(
    p_id_peminjaman VARCHAR(6),
    p_nrp_baru CHAR(10)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Peminjaman
    SET Mahasiswa_nrp = p_nrp_baru
    WHERE id_peminjaman = p_id_peminjaman;
END;
$$;

-- Procedure 2: Memindahkan peminjaman ke ruangan lain.
CREATE OR REPLACE PROCEDURE pindah_ruangan_peminjaman(
    p_id_peminjaman VARCHAR(6),
    p_id_ruangan_lama VARCHAR(8),
    p_id_ruangan_baru VARCHAR(8)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Peminjaman_Ruangan
    SET Ruangan_id_ruangan = p_id_ruangan_baru
    WHERE Peminjaman_id_peminjaman = p_id_peminjaman
      AND Ruangan_id_ruangan = p_id_ruangan_lama;
END;
$$;