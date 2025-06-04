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
    // Ekstrak nama barang
    String namaBarang = 'Barang tidak diketahui';
    
    // Coba ambil dari objek peminjaman jika ada
    if (json['peminjaman'] != null && json['peminjaman'] is Map) {
      if (json['peminjaman']['barang'] != null && json['peminjaman']['barang'] is Map) {
        namaBarang = json['peminjaman']['barang']['nama'] ?? 'Barang tidak diketahui';
      } else if (json['peminjaman']['nama_barang'] != null) {
        namaBarang = json['peminjaman']['nama_barang'];
      }
    }
    
    // Jika tidak ada di peminjaman, coba ambil langsung dari objek pengembalian
    if (namaBarang == 'Barang tidak diketahui' && json['nama_barang'] != null) {
      namaBarang = json['nama_barang'];
    }
    
    // Ekstrak nama peminjam
    String? namaPeminjam;
    if (json['peminjaman'] != null && json['peminjaman'] is Map) {
      if (json['peminjaman']['user'] != null && json['peminjaman']['user'] is Map) {
        namaPeminjam = json['peminjaman']['user']['name'];
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






