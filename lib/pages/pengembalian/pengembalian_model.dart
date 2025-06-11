class Pengembalian {
  final int id;
  final dynamic idPeminjaman; // Bisa int atau Map untuk data peminjaman lengkap
  final int jumlah;
  final String tanggalKembali;
  final String kondisi;
  final String catatan;
  final String status;
  String namaBarang;

  Pengembalian({
    required this.id,
    required this.idPeminjaman,
    required this.jumlah,
    required this.tanggalKembali,
    required this.kondisi,
    required this.catatan,
    this.status = 'selesai',
    this.namaBarang = '',
  });

  factory Pengembalian.fromJson(Map<String, dynamic> json) {
    // Print untuk debugging
    print('Parsing pengembalian JSON: $json');

    // Ekstrak nama barang
    String namaBarang = 'Barang tidak diketahui';

    // Cek apakah ada objek peminjaman dengan data barang
    if (json.containsKey('peminjaman') && json['peminjaman'] != null) {
      final peminjaman = json['peminjaman'];
      if (peminjaman is Map) {
        // Cek apakah ada data barang dalam peminjaman
        if (peminjaman.containsKey('barang') && peminjaman['barang'] != null) {
          final barang = peminjaman['barang'];
          if (barang is Map && barang.containsKey('nama')) {
            namaBarang = barang['nama'].toString();
          }
        }
        // Fallback ke nama_barang di level peminjaman
        else if (peminjaman.containsKey('nama_barang')) {
          namaBarang = peminjaman['nama_barang'].toString();
        }
      }
    }

    // Fallback ke nama_barang langsung di root
    if (namaBarang == 'Barang tidak diketahui' && json.containsKey('nama_barang')) {
      namaBarang = json['nama_barang'].toString();
    }

    // Fallback ke barang langsung di root
    if (namaBarang == 'Barang tidak diketahui' && json.containsKey('barang')) {
      final barang = json['barang'];
      if (barang is Map && barang.containsKey('nama')) {
        namaBarang = barang['nama'].toString();
      }
    }

    return Pengembalian(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      idPeminjaman: json['peminjaman_id'] ?? json['peminjaman'] ?? 0,
      jumlah: json['jumlah_kembali'] is int
          ? json['jumlah_kembali']
          : json['jumlah'] is int
              ? json['jumlah']
              : int.tryParse((json['jumlah_kembali'] ?? json['jumlah'] ?? '1').toString()) ?? 1,
      tanggalKembali: json['tanggal_pengembalian'] ?? json['tanggal_kembali'] ?? '',
      kondisi: json['kondisi_barang'] ?? json['kondisi'] ?? 'baik',
      catatan: json['catatan'] ?? '',
      status: json['status'] ?? 'selesai',
      namaBarang: namaBarang,
    );
  }
}








