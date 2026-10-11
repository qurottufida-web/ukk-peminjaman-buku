-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 11, 2026 at 03:22 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `perpustakaan`
--

-- --------------------------------------------------------

--
-- Table structure for table `peminjaman`
--

CREATE TABLE `peminjaman` (
  `id` int(11) NOT NULL,
  `kode` varchar(30) NOT NULL,
  `buku_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `tgl_pinjam` date DEFAULT NULL,
  `tgl_jatuh_tempo` date DEFAULT NULL,
  `tgl_kembali` date DEFAULT NULL,
  `denda` int(11) NOT NULL DEFAULT 0,
  `status` enum('diajukan','dipinjam','dikembalikan','ditolak') NOT NULL DEFAULT 'diajukan',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `peminjaman`
--

INSERT INTO `peminjaman` (`id`, `kode`, `buku_id`, `user_id`, `tgl_pinjam`, `tgl_jatuh_tempo`, `tgl_kembali`, `denda`, `status`, `created_at`) VALUES
(1, 'PJM-0001', 1, 2, '2026-09-19', '2026-09-26', '2026-09-29', 3000, 'dikembalikan', '2026-10-09 03:32:38'),
(2, 'PJM-0002', 3, 2, '2026-09-29', '2026-10-06', '2026-10-11', 5000, 'dikembalikan', '2026-10-09 03:32:38'),
(3, 'PJM-0003', 3, 3, '2026-10-04', '2026-10-11', NULL, 0, 'dipinjam', '2026-10-09 03:32:38'),
(4, 'PJM-0004', 6, 3, '2026-10-11', '2026-10-18', '2026-10-11', 0, 'dikembalikan', '2026-10-09 03:32:38'),
(5, 'PJM-0005', 1, 3, '2026-08-30', '2026-09-06', '2026-09-06', 0, 'dikembalikan', '2026-10-09 03:32:38'),
(6, 'PJM-26101101385428', 4, 2, '2026-10-11', '2026-10-18', NULL, 0, 'dipinjam', '2026-10-10 18:38:54'),
(7, 'PJM-26101101395618', 7, 3, NULL, NULL, NULL, 0, 'diajukan', '2026-10-10 18:39:56'),
(8, 'PJM-26101119185028', 2, 2, '2026-10-11', '2026-10-18', NULL, 0, 'dipinjam', '2026-10-11 12:18:50'),
(9, 'PJM-26101119195839', 1, 3, '2026-10-11', '2026-10-18', NULL, 0, 'dipinjam', '2026-10-11 12:19:58');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `peminjaman`
--
ALTER TABLE `peminjaman`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kode` (`kode`),
  ADD KEY `buku_id` (`buku_id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `peminjaman`
--
ALTER TABLE `peminjaman`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `peminjaman`
--
ALTER TABLE `peminjaman`
  ADD CONSTRAINT `peminjaman_ibfk_1` FOREIGN KEY (`buku_id`) REFERENCES `buku` (`id`),
  ADD CONSTRAINT `peminjaman_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
