-- QUERY JOIN
-- 1 Menampilkan nama departemen, nama ruangan, kapasitas, dan jumlah fasilitas pada setiap ruangan
SELECT 
    d.nama AS nama_departemen,
    d.fakultas,
    r.nama_ruangan,
    r.kapasitas,
    COUNT(fr.Fasilitas_id_fasilitas) AS jumlah_fasilitas
FROM Ruangan r
JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
LEFT JOIN Fasilitas_Ruangan fr ON r.id_ruangan = fr.Ruangan_id_ruangan
GROUP BY d.nama, d.fakultas, r.nama_ruangan, r.kapasitas
ORDER BY d.nama, r.nama_ruangan;

-- 2 Menampilkan rekap fakultas, jumlah departemen, jumlah ruangan, dan rata-rata kapasitas ruangan
SELECT 
    d.fakultas,
    COUNT(DISTINCT d.id_departemen) AS jumlah_departemen,
    COUNT(r.id_ruangan) AS jumlah_ruangan,
    ROUND(AVG(r.kapasitas)::numeric, 2) AS rata_rata_kapasitas
FROM Departemen d
JOIN Ruangan r ON d.id_departemen = r.Departemen_id_departemen
GROUP BY d.fakultas
ORDER BY d.fakultas;

-- VIEW
-- 1 Menampilkan informasi ruangan, departemen, fakultas, lokasi, kapasitas, status, dan jumlah fasilitas yang dimiliki setiap ruangan
CREATE OR REPLACE VIEW vw_aji_ringkasan_ruangan AS
SELECT 
    r.id_ruangan,
    r.nama_ruangan,
    d.nama AS nama_departemen,
    d.fakultas,
    r.lokasi,
    r.kapasitas,
    r.status,
    COUNT(fr.Fasilitas_id_fasilitas) AS jumlah_fasilitas
FROM Ruangan r
JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
LEFT JOIN Fasilitas_Ruangan fr ON r.id_ruangan = fr.Ruangan_id_ruangan
GROUP BY r.id_ruangan, r.nama_ruangan, d.nama, d.fakultas, r.lokasi, r.kapasitas, r.status
ORDER BY d.nama, r.nama_ruangan;


-- 2 Menampilkan jumlah departemen, jumlah ruangan, ruangan aktif, dan rata-rata kapasitas pada setiap fakultas
CREATE OR REPLACE VIEW vw_aji_rekap_fakultas AS
SELECT 
    d.fakultas,
    COUNT(DISTINCT d.id_departemen) AS jumlah_departemen,
    COUNT(DISTINCT r.id_ruangan) AS jumlah_ruangan,
    COUNT(DISTINCT CASE WHEN r.status = TRUE THEN r.id_ruangan END) AS jumlah_ruangan_aktif,
    COALESCE(ROUND(AVG(r.kapasitas)::numeric, 2), 0) AS rata_rata_kapasitas
FROM Departemen d
JOIN Ruangan r ON d.id_departemen = r.Departemen_id_departemen
GROUP BY d.fakultas
ORDER BY d.fakultas;


-- TRIGGER
-- 1 Memastikan kapasitas ruangan wajar dan lokasi ruangan diawali dengan kata Gedung

CREATE OR REPLACE FUNCTION fn_aji_validasi_data_ruangan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.kapasitas <= 0 OR NEW.kapasitas > 300 THEN
        RAISE EXCEPTION 'Kapasitas ruangan harus berada pada rentang 1 sampai 300';
    END IF;

    IF NEW.lokasi NOT ILIKE 'Gedung%' THEN
        RAISE EXCEPTION 'Lokasi ruangan harus diawali dengan kata Gedung';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aji_validasi_data_ruangan ON Ruangan;
CREATE TRIGGER trg_aji_validasi_data_ruangan
BEFORE INSERT OR UPDATE ON Ruangan
FOR EACH ROW
EXECUTE FUNCTION fn_aji_validasi_data_ruangan();


-- 2 Memastikan tanggal pengajuan peminjaman tidak lebih besar dari tanggal hari ini

CREATE OR REPLACE FUNCTION fn_aji_validasi_tanggal_pengajuan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.tanggal_pengajuan > CURRENT_DATE THEN
        RAISE EXCEPTION 'Tanggal pengajuan tidak boleh berada di masa depan';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aji_validasi_tanggal_pengajuan ON Peminjaman;
CREATE TRIGGER trg_aji_validasi_tanggal_pengajuan
BEFORE INSERT OR UPDATE ON Peminjaman
FOR EACH ROW
EXECUTE FUNCTION fn_aji_validasi_tanggal_pengajuan();


-- FUNCTION
-- 1 Menampilkan detail ruangan, jumlah fasilitas, dan total peminjaman untuk satu ruangan

CREATE OR REPLACE FUNCTION fn_aji_statistik_ruangan(
    p_id_ruangan VARCHAR(8)
)
RETURNS TABLE (
    id_ruangan VARCHAR(8),
    nama_ruangan VARCHAR(40),
    nama_departemen VARCHAR(30),
    fakultas VARCHAR(30),
    lokasi VARCHAR(50),
    kapasitas INT,
    jumlah_fasilitas BIGINT,
    total_peminjaman BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id_ruangan,
        r.nama_ruangan,
        d.nama,
        d.fakultas,
        r.lokasi,
        r.kapasitas,
        COUNT(DISTINCT fr.Fasilitas_id_fasilitas) AS jumlah_fasilitas,
        COUNT(DISTINCT pr.Peminjaman_id_peminjaman) AS total_peminjaman
    FROM Ruangan r
    JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
    LEFT JOIN Fasilitas_Ruangan fr ON r.id_ruangan = fr.Ruangan_id_ruangan
    LEFT JOIN Peminjaman_Ruangan pr ON r.id_ruangan = pr.Ruangan_id_ruangan
    WHERE r.id_ruangan = p_id_ruangan
    GROUP BY r.id_ruangan, r.nama_ruangan, d.nama, d.fakultas, r.lokasi, r.kapasitas;
END;
$$;

-- 2 Menampilkan jumlah departemen, jumlah ruangan, ruangan aktif, dan rata-rata kapasitas pada satu fakultas

CREATE OR REPLACE FUNCTION fn_aji_ringkasan_fakultas(
    p_fakultas VARCHAR(30)
)
RETURNS TABLE (
    fakultas VARCHAR(30),
    jumlah_departemen BIGINT,
    jumlah_ruangan BIGINT,
    jumlah_ruangan_aktif BIGINT,
    rata_rata_kapasitas NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.fakultas,
        COUNT(DISTINCT d.id_departemen) AS jumlah_departemen,
        COUNT(DISTINCT r.id_ruangan) AS jumlah_ruangan,
        COUNT(DISTINCT CASE WHEN r.status = TRUE THEN r.id_ruangan END) AS jumlah_ruangan_aktif,
        COALESCE(ROUND(AVG(r.kapasitas)::numeric, 2), 0) AS rata_rata_kapasitas
    FROM Departemen d
    JOIN Ruangan r ON d.id_departemen = r.Departemen_id_departemen
    WHERE d.fakultas = p_fakultas
    GROUP BY d.fakultas;
END;
$$;