class Peminjaman {
  final int id;
  final int idUser;
  final int idBarang;
  final String alasanPinjam;
  final int jumlah;
  final String tglPinjam;
  final String? tglKembali;
  final String status;
  String namaBarang;
  bool sudahDikembalikan; // Tambahkan field untuk status pengembalian

  Peminjaman({
    required this.id,
    required this.idUser,
    required this.idBarang,
    required this.alasanPinjam,
    required this.jumlah,
    required this.tglPinjam,
    this.tglKembali,
    required this.status,
    required this.namaBarang,
    this.sudahDikembalikan = false, // Default false
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    // Print untuk debugging
    print('Parsing peminjaman JSON: $json');

    // Ekstrak nama barang
    String namaBarang = 'Barang tidak diketahui';
    int jumlah = 1;
    int idBarang = 0;
    bool sudahDikembalikan = false;

    // Coba dapatkan ID barang
    if (json.containsKey('barang_id')) {
      idBarang =
          json['barang_id'] is int
              ? json['barang_id']
              : int.tryParse(json['barang_id'].toString()) ?? 0;
    } else if (json.containsKey('id_barang')) {
      idBarang =
          json['id_barang'] is int
              ? json['id_barang']
              : int.tryParse(json['id_barang'].toString()) ?? 0;
    }

    // Cek apakah ada objek barang
    if (json.containsKey('barang') && json['barang'] != null) {
      final barang = json['barang'];
      if (barang is Map) {
        // Coba ambil nama dari berbagai kemungkinan key
        if (barang.containsKey('nama')) {
          namaBarang = barang['nama'].toString();
        } else if (barang.containsKey('nama_barang')) {
          namaBarang = barang['nama_barang'].toString();
        }
      } else if (barang is String) {
        namaBarang = barang;
      }
    }

    // Jika jumlah ada di root JSON
    if (json.containsKey('jumlah')) {
      jumlah =
          json['jumlah'] is int
              ? json['jumlah']
              : int.tryParse(json['jumlah'].toString()) ?? 1;
    }

    // Cek status pengembalian
    if (json.containsKey('status_pengembalian')) {
      sudahDikembalikan =
          json['status_pengembalian'] == true ||
          json['status_pengembalian'] == 'true' ||
          json['status_pengembalian'] == 1 ||
          json['status_pengembalian'] == '1';
    } else if (json.containsKey('sudah_dikembalikan')) {
      sudahDikembalikan =
          json['sudah_dikembalikan'] == true ||
          json['sudah_dikembalikan'] == 'true' ||
          json['sudah_dikembalikan'] == 1 ||
          json['sudah_dikembalikan'] == '1';
    } else if (json.containsKey('pengembalian')) {
      // Jika ada objek pengembalian, berarti sudah dikembalikan
      sudahDikembalikan = json['pengembalian'] != null;
    }

    print(
      'Hasil parsing: id_barang=$idBarang, nama=$namaBarang, jumlah=$jumlah, sudahDikembalikan=$sudahDikembalikan',
    );

    return Peminjaman(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      idUser:
          json['user_id'] is int
              ? json['user_id']
              : int.tryParse(json['user_id'].toString()) ?? 0,
      idBarang: idBarang,
      alasanPinjam: json['alasan_pinjam'] ?? '',
      jumlah: jumlah,
      tglPinjam: json['tanggal_pinjam'] ?? json['tgl_pinjam'] ?? '',
      tglKembali: json['tanggal_kembali'] ?? json['tgl_kembali'],
      status: json['status'] ?? 'menunggu',
      namaBarang: namaBarang,
      sudahDikembalikan: sudahDikembalikan,
    );
  }

  // Method untuk convert ke JSON sesuai format API
  Map<String, dynamic> toJson() {
    return {
      'user_id': idUser,
      'barang_id': idBarang,
      'alasan_pinjam': alasanPinjam,
      'jumlah': jumlah,
      'status': status,
      'tanggal_pinjam': tglPinjam,
      'tanggal_kembali': tglKembali,
    };
  }
}
