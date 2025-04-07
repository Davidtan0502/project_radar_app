import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F73A3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "R.A.D.A.R",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // User Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, size: 60, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Juan Dela Cruz",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text(
                            "Metro Manila, City of Manila,\nPhilippines",
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[900],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text("Verified", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Location Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Location",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text("Tell the operator your location"),
                    const SizedBox(height: 12),
                    const Text(
                      "Street Name\nH2PH+HW2, I lopez St.,\nMandaluyong, Metro Manila, Philippines",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Latitude",
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                              Text("14.58639", style: TextStyle(color: Colors.red)),
                              SizedBox(height: 8),
                              Text("Longitude",
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                              Text("121.02979", style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/map_sample.png', // Map preview image
                            width: 150,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Spacer
            ],
          ),
        ),
      ),
    );
  }
}
