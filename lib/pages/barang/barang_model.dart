class Barang {
  final int id;
  final String nama;
  final int jumlahBarang; // ubah dari stok
  final String foto;
  final int idKategori;

  Barang({
    required this.id,
    required this.nama,
    required this.jumlahBarang,
    required this.foto,
    required this.idKategori,
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'],
      nama: json['nama'],
      jumlahBarang: json['jumlah_barang'], // key-nya dari Laravel
      foto: json['foto'] ?? '',
      idKategori: json['id_kategori'],
    );
  }
}