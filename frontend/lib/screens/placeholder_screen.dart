import 'package:flutter/material.dart';

// Konstanta warna agar konsisten dengan Home
const Color _primaryColor = Color(0xFF0E2F60);
const Color _accentColor = Color(0xFF3C486B);
const Color _backgroundColor = Color(0xFFF5F5F5);

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Kita cek judulnya. Jika "Data Keluarga Saya", tampilkan UI KK.
    // Jika suatu saat dipakai untuk menu lain, bisa ditambahkan 'else if'.
    if (title.contains("Keluarga")) {
      return _buildKeluargaView(context);
    }

    // Default view jika judul tidak dikenali (fallback)
    return const Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(child: Text("Konten belum tersedia")),
    );
  }

  Widget _buildKeluargaView(BuildContext context) {
    // --- DATA DUMMY (Nantinya ini diambil dari API/Database) ---
    final Map<String, String> infoKK = {
      "No. KK": "3201123456780001",
      "Kepala Keluarga": "Budi Santoso",
      "Alamat": "Jl. Mawar No. 12, RT 01 / RW 02",
      "Desa/Kelurahan": "Sukamaju",
    };

    final List<Map<String, String>> anggotaKeluarga = [
      {
        "nama": "Budi Santoso",
        "nik": "3201123456780001",
        "status": "Kepala Keluarga",
        "jk": "Laki-laki",
        "ttl": "Bandung, 12-08-1980",
        "agama": "Islam",
        "pekerjaan": "Wiraswasta",
      },
      {
        "nama": "Siti Aminah",
        "nik": "3201123456780002",
        "status": "Istri",
        "jk": "Perempuan",
        "ttl": "Jakarta, 05-03-1985",
        "agama": "Islam",
        "pekerjaan": "Ibu Rumah Tangga",
      },
      {
        "nama": "Rizky Pratama",
        "nik": "3201123456780003",
        "status": "Anak",
        "jk": "Laki-laki",
        "ttl": "Bandung, 20-01-2010",
        "agama": "Islam",
        "pekerjaan": "Pelajar/Mahasiswa",
      },
      {
        "nama": "Anya Putri",
        "nik": "3201123456780004",
        "status": "Anak",
        "jk": "Perempuan",
        "ttl": "Bandung, 15-06-2015",
        "agama": "Islam",
        "pekerjaan": "Belum/Tidak Bekerja",
      },
    ];
    // ------------------------------------------------------------

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Kartu Keluarga (Card Besar di Atas)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryColor, _accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "KARTU KELUARGA",
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1.5,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    infoKK['No. KK']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHeaderInfo("Kepala Keluarga", infoKK['Kepala Keluarga']!),
                  const SizedBox(height: 8),
                  _buildHeaderInfo("Alamat", infoKK['Alamat']!),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. Judul Section Anggota
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                "Anggota Keluarga",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),

            // 3. List Anggota Keluarga (Menggunakan ExpansionTile)
            ListView.builder(
              shrinkWrap: true, // Agar bisa di dalam SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(),
              itemCount: anggotaKeluarga.length,
              itemBuilder: (context, index) {
                final member = anggotaKeluarga[index];
                return _buildMemberCard(member);
              },
            ),

            const SizedBox(height: 20),
            
            // 4. Tombol Aksi (Opsional)
            
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget kecil untuk info di header (teks putih)
  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Widget Card untuk setiap Anggota Keluarga
  Widget _buildMemberCard(Map<String, String> member) {
    bool isHead = member['status'] == "Kepala Keluarga";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(), // Menghilangkan garis border default saat expand
        leading: CircleAvatar(
          backgroundColor: isHead ? _primaryColor : _primaryColor.withOpacity(0.1),
          child: Icon(
            member['jk'] == "Laki-laki" ? Icons.face : Icons.face_3,
            color: isHead ? Colors.white : _primaryColor,
          ),
        ),
        title: Text(
          member['nama']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          member['status']!,
          style: TextStyle(
            color: isHead ? _primaryColor : Colors.grey[600],
            fontWeight: isHead ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          _buildDetailRow(Icons.badge, "NIK", member['nik']!),
          _buildDetailRow(Icons.cake, "TTL", member['ttl']!),
          _buildDetailRow(Icons.people, "Jenis Kelamin", member['jk']!),
          _buildDetailRow(Icons.mosque, "Agama", member['agama']!),
          _buildDetailRow(Icons.work, "Pekerjaan", member['pekerjaan']!),
        ],
      ),
    );
  }

  // Baris detail di dalam ExpansionTile
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}