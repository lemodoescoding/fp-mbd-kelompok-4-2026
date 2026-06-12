-- Created by Redgate Data Modeler (https://datamodeler.redgate-platform.com)
-- Last modification date: 2026-06-12 06:04:18.436

-- tables
-- Table: Departemen
CREATE TABLE Departemen (
    id_departemen varchar(6)  NOT NULL,
    nama varchar(30)  NOT NULL,
    fakultas varchar(30)  NOT NULL,
    CONSTRAINT Departemen_pk PRIMARY KEY (id_departemen)
);

-- Table: Fasilitas
CREATE TABLE Fasilitas (
    id_fasilitas varchar(6)  NOT NULL,
    nama varchar(30)  NOT NULL,
    CONSTRAINT Fasilitas_pk PRIMARY KEY (id_fasilitas)
);

-- Table: Fasilitas_Ruangan
CREATE TABLE Fasilitas_Ruangan (
    Fasilitas_id_fasilitas varchar(6)  NOT NULL,
    Ruangan_id_ruangan varchar(8)  NOT NULL,
    CONSTRAINT Fasilitas_Ruangan_pk PRIMARY KEY (Fasilitas_id_fasilitas,Ruangan_id_ruangan)
);

-- Table: Mahasiswa
CREATE TABLE Mahasiswa (
    nrp char(10)  NOT NULL,
    nama varchar(30)  NOT NULL,
    prodi varchar(50)  NOT NULL,
    email varchar(30)  NOT NULL,
    CONSTRAINT Mahasiswa_pk PRIMARY KEY (nrp)
);

-- Table: Peminjaman
CREATE TABLE Peminjaman (
    id_peminjaman varchar(6)  NOT NULL,
    tanggal_pengajuan date  NOT NULL,
    detail_waktu_mulai timestamp  NOT NULL,
    detail_waktu_selesai timestamp  NOT NULL,
    keperluan text  NOT NULL,
    Mahasiswa_nrp char(10)  NOT NULL,
    StatusPeminjaman_id_statuspeminjaman varchar(6)  NOT NULL,
    CONSTRAINT Peminjaman_pk PRIMARY KEY (id_peminjaman)
);

-- Table: Peminjaman_Ruangan
CREATE TABLE Peminjaman_Ruangan (
    Peminjaman_id_peminjaman varchar(6)  NOT NULL,
    Ruangan_id_ruangan varchar(8)  NOT NULL,
    CONSTRAINT Peminjaman_Ruangan_pk PRIMARY KEY (Peminjaman_id_peminjaman,Ruangan_id_ruangan)
);

-- Table: Ruangan
CREATE TABLE Ruangan (
    id_ruangan varchar(8)  NOT NULL,
    nama_ruangan varchar(40)  NOT NULL,
    lokasi varchar(50)  NOT NULL,
    kapasitas int  NOT NULL,
    status boolean  NOT NULL,
    Departemen_id_departemen varchar(6)  NOT NULL,
    CONSTRAINT Ruangan_pk PRIMARY KEY (id_ruangan)
);

-- Table: StatusPeminjaman
CREATE TABLE StatusPeminjaman (
    id_statuspeminjaman varchar(6)  NOT NULL,
    status varchar(20)  NOT NULL,
    CONSTRAINT StatusPeminjaman_pk PRIMARY KEY (id_statuspeminjaman)
);

-- foreign keys
-- Reference: Fasilitas_Ruangan_Fasilitas (table: Fasilitas_Ruangan)
ALTER TABLE Fasilitas_Ruangan ADD CONSTRAINT Fasilitas_Ruangan_Fasilitas
    FOREIGN KEY (Fasilitas_id_fasilitas)
    REFERENCES Fasilitas (id_fasilitas)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Fasilitas_Ruangan_Ruangan (table: Fasilitas_Ruangan)
ALTER TABLE Fasilitas_Ruangan ADD CONSTRAINT Fasilitas_Ruangan_Ruangan
    FOREIGN KEY (Ruangan_id_ruangan)
    REFERENCES Ruangan (id_ruangan)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Peminjaman_Mahasiswa (table: Peminjaman)
ALTER TABLE Peminjaman ADD CONSTRAINT Peminjaman_Mahasiswa
    FOREIGN KEY (Mahasiswa_nrp)
    REFERENCES Mahasiswa (nrp)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Peminjaman_Ruangan_Peminjaman (table: Peminjaman_Ruangan)
ALTER TABLE Peminjaman_Ruangan ADD CONSTRAINT Peminjaman_Ruangan_Peminjaman
    FOREIGN KEY (Peminjaman_id_peminjaman)
    REFERENCES Peminjaman (id_peminjaman)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Peminjaman_Ruangan_Ruangan (table: Peminjaman_Ruangan)
ALTER TABLE Peminjaman_Ruangan ADD CONSTRAINT Peminjaman_Ruangan_Ruangan
    FOREIGN KEY (Ruangan_id_ruangan)
    REFERENCES Ruangan (id_ruangan)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Peminjaman_StatusPeminjaman (table: Peminjaman)
ALTER TABLE Peminjaman ADD CONSTRAINT Peminjaman_StatusPeminjaman
    FOREIGN KEY (StatusPeminjaman_id_statuspeminjaman)
    REFERENCES StatusPeminjaman (id_statuspeminjaman)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: Ruangan_Departemen (table: Ruangan)
ALTER TABLE Ruangan ADD CONSTRAINT Ruangan_Departemen
    FOREIGN KEY (Departemen_id_departemen)
    REFERENCES Departemen (id_departemen)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- End of file.

