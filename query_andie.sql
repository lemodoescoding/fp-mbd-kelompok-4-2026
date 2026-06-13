-- QUERY JOIN
--1 Menampilkan nama mahasiswa, prodi, nama ruangan, dan status peminjaman
SELECT m.nama, m.prodi, r.nama_ruangan, sp.status FROM Mahasiswa m
JOIN Peminjaman p ON m.nrp = p.Mahasiswa_nrp
JOIN Peminjaman_Ruangan pr ON p.id_peminjaman = pr.Peminjaman_id_peminjaman
JOIN Ruangan r ON pr.Ruangan_id_ruangan = r.id_ruangan
JOIN StatusPeminjaman sp ON p.StatusPeminjaman_id_statuspeminjaman = sp.id_statuspeminjaman

--2 Menampilkan nrp, nama mahasiswa, prodi yang melakukan lebih dari satu peminjaman
SELECT m.nrp, m.nama, m.prodi FROM Mahasiswa m
JOIN Peminjaman p ON m.nrp = p.Mahasiswa_nrp
GROUP BY m.nrp, m.nama, m.prodi
HAVING COUNT(p.id_peminjaman) > 1;

--VIEW
--1 Menampilkan nama departemen, nama ruangan, lokasi, dan kapasitas untuk ruangan yang memiliki kapasitas lebih dari 100. Data diurutkan berdasarkan nama departemen.
CREATE VIEW INFO_RUANGAN AS SELECT d.nama, r.nama_ruangan, r.lokasi, r.kapasitas FROM Ruangan r
JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
WHERE r.kapasitas > 100
ORDER BY d.nama;

SELECT * FROM INFO_RUANGAN;

--2 Menampilkan nama departemen, nama ruangan, dan daftar fasilitas pada setiap ruangan. Data diurutkan berdasarkan nama departemen.
CREATE VIEW INFO_FASILITAS_RUANGAN AS 
SELECT d.nama, r.nama_ruangan, STRING_AGG(f.nama, ', ' ORDER BY f.nama) AS fasilitas FROM Ruangan r
JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
JOIN Fasilitas_Ruangan fr ON r.id_ruangan = fr.Ruangan_id_ruangan
JOIN Fasilitas f ON fr.Fasilitas_id_fasilitas = f.id_fasilitas
GROUP BY r.nama_ruangan, d.nama
ORDER BY d.nama;

SELECT * FROM INFO_FASILITAS_RUANGAN;
DROP VIEW INFO_FASILITAS_RUANGAN

--TRIGGER
--1 Memastikan email mahasiswa menggunakan domain @its.ac.id sebelum data mahasiswa disimpan atau diperbarui.
CREATE OR REPLACE FUNCTION trg_validasi_email_mahasiswa()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.email NOT LIKE '%@its.ac.id' THEN
        RAISE EXCEPTION
            'Email harus menggunakan domain @its.ac.id';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validasi_email_mahasiswa
BEFORE INSERT OR UPDATE OF email ON Mahasiswa
FOR EACH ROW
EXECUTE FUNCTION trg_validasi_email_mahasiswa();

INSERT INTO Mahasiswa VALUES ('5025241000', 'Budi', 'Informatika', 'budi@gmail.com');

--2 Memvalidasi ketersediaan ruangan sebelum peminjaman dilakukan sehingga ruangan yang berstatus tidak tersedia tidak dapat dipinjam. 
CREATE OR REPLACE FUNCTION trg_cek_status_ruangan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF (
        SELECT status
        FROM Ruangan
        WHERE id_ruangan = NEW.Ruangan_id_ruangan
    ) = FALSE THEN
        RAISE EXCEPTION
            'Ruangan tidak tersedia';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER cek_status_ruangan
BEFORE INSERT ON Peminjaman_Ruangan
FOR EACH ROW
EXECUTE FUNCTION trg_cek_status_ruangan();

INSERT INTO Peminjaman_Ruangan VALUES ('PM0200', 'RNG00038');

--FUNCTION
--1 Menampilkan nama departemen dan nama ruangan yang memiliki fasilitas yang dicari. 
CREATE OR REPLACE FUNCTION cari_ruangan(fasilitas VARCHAR)
RETURNS TABLE (
    departemen VARCHAR(30),
    nama_ruangan VARCHAR(40)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT d.nama, r.nama_ruangan FROM Ruangan r
    JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
    JOIN Fasilitas_Ruangan fr ON r.id_ruangan = fr.Ruangan_id_ruangan
    JOIN Fasilitas f ON fr.Fasilitas_id_fasilitas = f.id_fasilitas
    WHERE f.nama = fasilitas;
END;
$$;

SELECT * FROM cari_ruangan('Papan Tulis')

--2 Menampilkan nama departemen, nama ruangan, lokasi, dan kapasitas ruangan berdasarkan kapasitas yang dicari. 
CREATE OR REPLACE FUNCTION cari_ruangan_kapasitas(p_kapasitas INTEGER)
RETURNS TABLE (
    departemen VARCHAR(30),
    nama_ruangan VARCHAR(40),
    lokasi VARCHAR(50),
    kapasitas INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT d.nama, r.nama_ruangan, r.lokasi, r.kapasitas FROM Ruangan r
    JOIN Departemen d ON r.Departemen_id_departemen = d.id_departemen
    WHERE r.kapasitas >= p_kapasitas
    ORDER BY r.kapasitas DESC;
END;
$$;

SELECT * FROM cari_ruangan_kapasitas(75)
