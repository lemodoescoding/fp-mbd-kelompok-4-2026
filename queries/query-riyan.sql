SELECT id_ruangan, nama_ruangan,  FROM ruangan
LEFT JOIN peminjaman_ruangan
ON ruangan.id_ruangan = peminjaman_ruangan.ruangan_id_ruangan
WHERE peminjaman_ruangan.ruangan_id_ruangan IS NULL;

SELECT
    d.fakultas,
    r.id_ruangan,
    r.nama_ruangan,
    STRING_AGG(f.nama, ', ' ORDER BY f.nama) AS daftar_fasilitas
FROM Ruangan r
JOIN Departemen d
    ON r.Departemen_id_departemen = d.id_departemen
JOIN Fasilitas_Ruangan fr
    ON r.id_ruangan = fr.Ruangan_id_ruangan
JOIN Fasilitas f
    ON fr.Fasilitas_id_fasilitas = f.id_fasilitas
WHERE d.fakultas = 'FTEIC'
GROUP BY d.fakultas, r.id_ruangan, r.nama_ruangan
ORDER BY r.id_ruangan;

CREATE OR REPLACE VIEW histori_peminjaman AS
SELECT
    p.id_peminjaman,
    m.nama AS nama_mahasiswa,
    r.nama_ruangan,
	d.nama AS nama_departemen,
	sp.status
FROM peminjaman p
JOIN mahasiswa m
    ON p.mahasiswa_nrp = m.nrp
JOIN peminjaman_Ruangan pr
    ON p.id_peminjaman = pr.peminjaman_id_peminjaman
JOIN ruangan r
    ON pr.ruangan_id_ruangan = r.id_ruangan
JOIN departemen d
	ON d.id_departemen = r.departemen_id_departemen
JOIN statuspeminjaman sp
	ON sp.id_statuspeminjaman = p.statusPeminjaman_id_statuspeminjaman;

SELECT * FROM histori_peminjaman;

CREATE OR REPLACE VIEW statistik_peminjaman_ruangan AS
SELECT
    r.id_ruangan,
    r.nama_ruangan,
    COUNT(pr.peminjaman_id_peminjaman) AS jumlah_peminjaman
FROM ruangan r
LEFT JOIN peminjaman_Ruangan pr
    ON r.id_ruangan = pr.Ruangan_id_ruangan
GROUP BY r.id_ruangan, r.nama_ruangan
ORDER BY jumlah_peminjaman DESC;

SELECT * FROM statistik_peminjaman_ruangan;

CREATE OR REPLACE FUNCTION fn_cek_double_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_mulai TIMESTAMP;
    v_selesai TIMESTAMP;
BEGIN
    SELECT
        detail_waktu_mulai,
        detail_waktu_selesai
    INTO
        v_mulai,
        v_selesai
    FROM Peminjaman
    WHERE id_peminjaman = NEW.Peminjaman_id_peminjaman;

    IF EXISTS (
        SELECT 1
        FROM Peminjaman_Ruangan pr
        JOIN Peminjaman p
            ON pr.Peminjaman_id_peminjaman = p.id_peminjaman
        WHERE pr.Ruangan_id_ruangan = NEW.Ruangan_id_ruangan
        AND p.id_peminjaman <> NEW.Peminjaman_id_peminjaman
        AND (
            v_mulai < p.detail_waktu_selesai
            AND
            v_selesai > p.detail_waktu_mulai
        )
    ) THEN
        RAISE EXCEPTION
            'Ruangan sudah dibooking pada rentang waktu tersebut';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cek_double_booking
BEFORE INSERT OR UPDATE
ON Peminjaman_Ruangan
FOR EACH ROW
EXECUTE FUNCTION fn_cek_double_booking();

INSERT INTO Peminjaman
VALUES (
    'PM0999',
    CURRENT_DATE,
    '2026-06-20 09:00:00',
    '2026-06-20 11:00:00',
    'Tes Double Booking',
    '5025241001',
    'ST0001'
);

INSERT INTO Peminjaman_Ruangan
VALUES ('PM0999', 'RNG00001');

CREATE OR REPLACE FUNCTION fn_validasi_waktu_masa_depan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.detail_waktu_mulai < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION
            'Waktu peminjaman tidak boleh berada di masa lalu';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validasi_waktu_masa_depan
BEFORE INSERT OR UPDATE
ON Peminjaman
FOR EACH ROW
EXECUTE FUNCTION fn_validasi_waktu_masa_depan();

-- TESTING

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
    'PM0999',
    CURRENT_DATE,
    '2025-01-01 08:00:00',
    '2025-01-01 10:00:00',
    'Tes Trigger',
    '5025241001',
    'ST0001'
);

CREATE OR REPLACE FUNCTION hitung_peminjaman_mahasiswa(
    p_nrp CHAR(10)
)
RETURNS TABLE (
    nama_mahasiswa VARCHAR(30),
    total_peminjaman BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.nama,
        COUNT(p.id_peminjaman)
    FROM Mahasiswa m
    LEFT JOIN Peminjaman p
        ON p.Mahasiswa_nrp = m.nrp
    WHERE m.nrp = p_nrp
    GROUP BY m.nama;
END;
$$;

-- TESTING
SELECT *
FROM hitung_peminjaman_mahasiswa(
    '5025241001'
);

CREATE OR REPLACE FUNCTION cari_ruangan_kosong(
    p_mulai TIMESTAMP,
    p_selesai TIMESTAMP
)
RETURNS TABLE (
    id_ruangan VARCHAR(8),
    nama_ruangan VARCHAR(40),
    lokasi VARCHAR(50),
    kapasitas INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id_ruangan,
        r.nama_ruangan,
        r.lokasi,
        r.kapasitas
    FROM Ruangan r
    WHERE NOT EXISTS (
        SELECT 1
        FROM Peminjaman_Ruangan pr
        JOIN Peminjaman p
            ON p.id_peminjaman =
               pr.Peminjaman_id_peminjaman
        WHERE pr.Ruangan_id_ruangan =
              r.id_ruangan
        AND (
            p_mulai < p.detail_waktu_selesai
            AND
            p_selesai > p.detail_waktu_mulai
        )
    );
END;
$$;

-- TESTING
SELECT *
FROM cari_ruangan_kosong(
    '2026-04-01 08:00:00',
    '2026-04-01 10:00:00'
);
