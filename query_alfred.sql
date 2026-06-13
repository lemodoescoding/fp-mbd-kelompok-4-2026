-- Query assignment for the room-loan database.
-- PostgreSQL syntax. Run ddl.sql and dml.sql before this file.

-- ============================================================
-- 1. SEARCHING QUERIES WITH JOIN (2 queries)
-- ============================================================

-- Join query 1:
-- Search approved loans and show the student, room, and department.
SELECT
    p.id_peminjaman,
    m.nrp,
    m.nama AS nama_mahasiswa,
    r.nama_ruangan,
    d.nama AS nama_departemen,
    p.detail_waktu_mulai,
    p.detail_waktu_selesai
FROM Peminjaman AS p
JOIN Mahasiswa AS m
    ON m.nrp = p.Mahasiswa_nrp
JOIN StatusPeminjaman AS sp
    ON sp.id_statuspeminjaman = p.StatusPeminjaman_id_statuspeminjaman
JOIN Peminjaman_Ruangan AS pr
    ON pr.Peminjaman_id_peminjaman = p.id_peminjaman
JOIN Ruangan AS r
    ON r.id_ruangan = pr.Ruangan_id_ruangan
JOIN Departemen AS d
    ON d.id_departemen = r.Departemen_id_departemen
WHERE sp.status = 'Disetujui'
ORDER BY p.detail_waktu_mulai;

-- Join query 2:
-- Search available rooms with a capacity of at least 50 and list
-- all facilities in each room.
SELECT
    r.id_ruangan,
    r.nama_ruangan,
    r.lokasi,
    r.kapasitas,
    d.nama AS nama_departemen,
    STRING_AGG(f.nama, ', ' ORDER BY f.nama) AS daftar_fasilitas
FROM Ruangan AS r
JOIN Departemen AS d
    ON d.id_departemen = r.Departemen_id_departemen
JOIN Fasilitas_Ruangan AS fr
    ON fr.Ruangan_id_ruangan = r.id_ruangan
JOIN Fasilitas AS f
    ON f.id_fasilitas = fr.Fasilitas_id_fasilitas
WHERE r.status = TRUE
  AND r.kapasitas >= 50
GROUP BY
    r.id_ruangan,
    r.nama_ruangan,
    r.lokasi,
    r.kapasitas,
    d.nama
ORDER BY r.kapasitas DESC, r.nama_ruangan;

-- ============================================================
-- 2. VIEWS (2 views)
-- ============================================================

-- View 1: complete loan details.
CREATE OR REPLACE VIEW vw_detail_peminjaman AS
SELECT
    p.id_peminjaman,
    p.tanggal_pengajuan,
    p.detail_waktu_mulai,
    p.detail_waktu_selesai,
    p.keperluan,
    m.nrp,
    m.nama AS nama_mahasiswa,
    m.prodi,
    sp.status AS status_peminjaman,
    r.id_ruangan,
    r.nama_ruangan,
    r.lokasi,
    d.nama AS nama_departemen,
    d.fakultas
FROM Peminjaman AS p
JOIN Mahasiswa AS m
    ON m.nrp = p.Mahasiswa_nrp
JOIN StatusPeminjaman AS sp
    ON sp.id_statuspeminjaman = p.StatusPeminjaman_id_statuspeminjaman
JOIN Peminjaman_Ruangan AS pr
    ON pr.Peminjaman_id_peminjaman = p.id_peminjaman
JOIN Ruangan AS r
    ON r.id_ruangan = pr.Ruangan_id_ruangan
JOIN Departemen AS d
    ON d.id_departemen = r.Departemen_id_departemen;

-- Example:
SELECT *
FROM vw_detail_peminjaman
WHERE status_peminjaman = 'Disetujui'
ORDER BY detail_waktu_mulai;

-- View 2: room usage summary.
CREATE OR REPLACE VIEW vw_ringkasan_penggunaan_ruangan AS
SELECT
    r.id_ruangan,
    r.nama_ruangan,
    d.nama AS nama_departemen,
    COUNT(DISTINCT p.id_peminjaman) AS total_peminjaman,
    COUNT(DISTINCT p.id_peminjaman)
        FILTER (WHERE sp.status = 'Disetujui') AS total_disetujui,
    COALESCE(
        SUM(
            EXTRACT(EPOCH FROM (
                p.detail_waktu_selesai - p.detail_waktu_mulai
            )) / 3600
        ) FILTER (WHERE sp.status IN ('Disetujui', 'Selesai')),
        0
    )::numeric(10, 2) AS total_jam_penggunaan
FROM Ruangan AS r
JOIN Departemen AS d
    ON d.id_departemen = r.Departemen_id_departemen
LEFT JOIN Peminjaman_Ruangan AS pr
    ON pr.Ruangan_id_ruangan = r.id_ruangan
LEFT JOIN Peminjaman AS p
    ON p.id_peminjaman = pr.Peminjaman_id_peminjaman
LEFT JOIN StatusPeminjaman AS sp
    ON sp.id_statuspeminjaman = p.StatusPeminjaman_id_statuspeminjaman
GROUP BY
    r.id_ruangan,
    r.nama_ruangan,
    d.nama;

-- Example:
SELECT *
FROM vw_ringkasan_penggunaan_ruangan
ORDER BY total_jam_penggunaan DESC, nama_ruangan;

-- ============================================================
-- 3. TRIGGERS (2 trigger functions + 2 triggers)
-- These two functions are used only by their respective triggers.
-- They are not counted as the two routines required in section 4.
-- ============================================================

-- Trigger function 1: reject invalid application and usage times.
CREATE OR REPLACE FUNCTION trg_validasi_waktu_peminjaman()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.detail_waktu_mulai >= NEW.detail_waktu_selesai THEN
        RAISE EXCEPTION
            'Waktu mulai harus lebih awal daripada waktu selesai';
    END IF;

    IF NEW.tanggal_pengajuan > NEW.detail_waktu_mulai::date THEN
        RAISE EXCEPTION
            'Tanggal pengajuan tidak boleh setelah tanggal peminjaman';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS validasi_waktu_peminjaman ON Peminjaman;

-- Trigger 1: execute trg_validasi_waktu_peminjaman().
CREATE TRIGGER validasi_waktu_peminjaman
BEFORE INSERT OR UPDATE OF
    tanggal_pengajuan,
    detail_waktu_mulai,
    detail_waktu_selesai
ON Peminjaman
FOR EACH ROW
EXECUTE FUNCTION trg_validasi_waktu_peminjaman();

-- Trigger function 2: prevent one room from having overlapping
-- active loans.
CREATE OR REPLACE FUNCTION trg_cegah_jadwal_ruangan_bentrok()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_peminjaman Peminjaman%ROWTYPE;
BEGIN
    SELECT *
    INTO v_peminjaman
    FROM Peminjaman
    WHERE id_peminjaman = NEW.Peminjaman_id_peminjaman;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Peminjaman % tidak ditemukan',
            NEW.Peminjaman_id_peminjaman;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM Peminjaman_Ruangan AS pr_lain
        JOIN Peminjaman AS p_lain
            ON p_lain.id_peminjaman = pr_lain.Peminjaman_id_peminjaman
        JOIN StatusPeminjaman AS sp_lain
            ON sp_lain.id_statuspeminjaman =
               p_lain.StatusPeminjaman_id_statuspeminjaman
        WHERE pr_lain.Ruangan_id_ruangan = NEW.Ruangan_id_ruangan
          AND pr_lain.Peminjaman_id_peminjaman <>
              NEW.Peminjaman_id_peminjaman
          AND sp_lain.status IN ('Diajukan', 'Disetujui')
          AND v_peminjaman.detail_waktu_mulai <
              p_lain.detail_waktu_selesai
          AND v_peminjaman.detail_waktu_selesai >
              p_lain.detail_waktu_mulai
    ) THEN
        RAISE EXCEPTION
            'Ruangan % sudah dipesan pada rentang waktu tersebut',
            NEW.Ruangan_id_ruangan;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS cegah_jadwal_ruangan_bentrok
ON Peminjaman_Ruangan;

-- Trigger 2: execute trg_cegah_jadwal_ruangan_bentrok().
CREATE TRIGGER cegah_jadwal_ruangan_bentrok
BEFORE INSERT OR UPDATE OF
    Peminjaman_id_peminjaman,
    Ruangan_id_ruangan
ON Peminjaman_Ruangan
FOR EACH ROW
EXECUTE FUNCTION trg_cegah_jadwal_ruangan_bentrok();

-- ============================================================
-- 4. STANDALONE PROCEDURES (2 procedures)
-- Procedures are used here so the trigger functions above are not
-- also claimed for this assignment requirement.
-- ============================================================

-- Procedure 1: create a loan and assign its room in one call.
-- The two triggers in section 3 automatically validate the data.
CREATE OR REPLACE PROCEDURE buat_peminjaman(
    p_id_peminjaman VARCHAR(6),
    p_tanggal_pengajuan DATE,
    p_waktu_mulai TIMESTAMP,
    p_waktu_selesai TIMESTAMP,
    p_keperluan TEXT,
    p_mahasiswa_nrp CHAR(10),
    p_id_ruangan VARCHAR(8)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Ruangan
        WHERE id_ruangan = p_id_ruangan
          AND status = TRUE
    ) THEN
        RAISE EXCEPTION
            'Ruangan % tidak ditemukan atau tidak tersedia',
            p_id_ruangan;
    END IF;

    INSERT INTO Peminjaman (
        id_peminjaman,
        tanggal_pengajuan,
        detail_waktu_mulai,
        detail_waktu_selesai,
        keperluan,
        Mahasiswa_nrp,
        StatusPeminjaman_id_statuspeminjaman
    ) VALUES (
        p_id_peminjaman,
        p_tanggal_pengajuan,
        p_waktu_mulai,
        p_waktu_selesai,
        p_keperluan,
        p_mahasiswa_nrp,
        'ST0001'
    );

    INSERT INTO Peminjaman_Ruangan (
        Peminjaman_id_peminjaman,
        Ruangan_id_ruangan
    ) VALUES (
        p_id_peminjaman,
        p_id_ruangan
    );
END;
$$;

-- Mutating example; run only when needed:
-- CALL buat_peminjaman(
--     'PM0201',
--     DATE '2026-07-07',
--     TIMESTAMP '2026-07-10 08:00:00',
--     TIMESTAMP '2026-07-10 10:00:00',
--     'Rapat organisasi mahasiswa',
--     '5025241001',
--     'RNG00001'
-- );

-- Procedure 2: change a loan status using valid workflow transitions.
CREATE OR REPLACE PROCEDURE ubah_status_peminjaman(
    p_id_peminjaman VARCHAR(6),
    p_status_baru VARCHAR(6)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status_lama VARCHAR(6);
BEGIN
    SELECT StatusPeminjaman_id_statuspeminjaman
    INTO v_status_lama
    FROM Peminjaman
    WHERE id_peminjaman = p_id_peminjaman
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Peminjaman % tidak ditemukan',
            p_id_peminjaman;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM StatusPeminjaman
        WHERE id_statuspeminjaman = p_status_baru
    ) THEN
        RAISE EXCEPTION 'Status % tidak ditemukan', p_status_baru;
    END IF;

    IF v_status_lama = p_status_baru THEN
        RETURN;
    END IF;

    IF NOT (
        (v_status_lama = 'ST0001' AND
            p_status_baru IN ('ST0002', 'ST0003', 'ST0005'))
        OR
        (v_status_lama = 'ST0002' AND
            p_status_baru IN ('ST0004', 'ST0005'))
    ) THEN
        RAISE EXCEPTION
            'Perubahan status dari % ke % tidak diperbolehkan',
            v_status_lama,
            p_status_baru;
    END IF;

    UPDATE Peminjaman
    SET StatusPeminjaman_id_statuspeminjaman = p_status_baru
    WHERE id_peminjaman = p_id_peminjaman;
END;
$$;

-- Mutating example; run only when needed:
-- CALL ubah_status_peminjaman('PM0175', 'ST0002');