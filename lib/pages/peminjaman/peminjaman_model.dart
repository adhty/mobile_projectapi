class Peminjaman {
  final int? id;
  final int? idUser;
  final int? idBarang;
  final String? alasanPinjam;
  final int? jumlah;
  final String? tglPinjam;
  final String? tglKembali;
  final String? status;
  final String? namaBarang; // Untuk menampilkan nama barang di dropdown

  Peminjaman({
    this.id,
    this.idUser,
    this.idBarang,
    this.alasanPinjam,
    this.jumlah,
    this.tglPinjam,
    this.tglKembali,
    this.status,
    this.namaBarang,
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    // Print untuk debugging
    print('Parsing peminjaman: $json');
    
    String? namaBarang;
    if (json.containsKey('barang') && json['barang'] != null) {
      namaBarang = json['barang']['nama_barang'];
    }
    
    return Peminjaman(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      idUser: json['id_user'] is String ? int.parse(json['id_user']) : json['id_user'],
      idBarang: json['id_barang'] is String ? int.parse(json['id_barang']) : json['id_barang'],
      alasanPinjam: json['alasan_pinjam'],
      jumlah: json['jumlah'] is String ? int.parse(json['jumlah']) : json['jumlah'],
      tglPinjam: json['tgl_pinjam'],
      tglKembali: json['tgl_kembali'],
      status: json['status'],
      namaBarang: namaBarang,
    );
  }
}
