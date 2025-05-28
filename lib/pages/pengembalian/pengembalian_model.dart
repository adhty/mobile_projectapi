class Pengembalian {
  final int id;
  final int peminjamanId;
  final String tanggalPengembalian;
  final String kondisiBarang;
  final String? catatan;
  final String status;
  final int jumlahKembali;
  final String? namaPengembalian;
  final double? biayaDenda;
  final Map<String, dynamic>? peminjaman;
  final String? namaPeminjam;
  final String namaBarang;

  Pengembalian({
    required this.id,
    required this.peminjamanId,
    required this.tanggalPengembalian,
    required this.kondisiBarang,
    this.catatan,
    required this.status,
    required this.jumlahKembali,
    this.namaPengembalian,
    this.biayaDenda,
    this.peminjaman,
    this.namaPeminjam,
    required this.namaBarang,
  });

  factory Pengembalian.fromJson(Map<String, dynamic> json) {
    // Print untuk debugging
    print('Parsing pengembalian JSON: $json');

    String? namaPeminjam;
    String namaBarang = 'Barang tidak diketahui';

    // Ekstrak nama peminjam dari field nama_pengembalian jika ada
    if (json.containsKey('nama_pengembalian')) {
      namaPeminjam = json['nama_pengembalian'];
    } else if (json.containsKey('nama_pengembalian')) {
      namaPeminjam = json['nama_pengembalian'];
    }

    // Ekstrak nama barang dari peminjaman jika ada
    if (json.containsKey('peminjaman') && json['peminjaman'] != null) {
      if (json['peminjaman'].containsKey('barang') && json['peminjaman']['barang'] != null) {
        final barang = json['peminjaman']['barang'];
        if (barang is Map) {
          if (barang.containsKey('nama')) {
            namaBarang = barang['nama'];
          } else if (barang.containsKey('nama_barang')) {
            namaBarang = barang['nama_barang'];
          }
        }
      }
    }

    print('Extracted nama barang: $namaBarang');

    return Pengembalian(
      id: json['id'] ?? 0,
      peminjamanId: json['peminjaman_id'] ?? 0,
      tanggalPengembalian: json['tanggal_pengembalian'] ?? '',
      kondisiBarang: json['kondisi_barang'] ?? 'baik',
      catatan: json['catatan'],
      status: json['status'] ?? 'menunggu',
      jumlahKembali: json['jumlah_kembali'] is int
          ? json['jumlah_kembali']
          : int.tryParse(json['jumlah_kembali'].toString()) ?? 0,
      namaPengembalian: json['nama_pengembalian'],
      biayaDenda: json['biaya_denda'] != null
          ? double.tryParse(json['biaya_denda'].toString())
          : null,
      peminjaman: json['peminjaman'],
      namaPeminjam: namaPeminjam,
      namaBarang: namaBarang,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peminjaman_id': peminjamanId,
      'tanggal_pengembalian': tanggalPengembalian,
      'kondisi_barang': kondisiBarang,
      'catatan': catatan,
      'status': status,
      'jumlah_kembali': jumlahKembali,
    };
  }
}


