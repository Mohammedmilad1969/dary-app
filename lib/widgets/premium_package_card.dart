import 'package:flutter/material.dart';
import '../models/premium_package.dart';

class PremiumPackageCard extends StatelessWidget {
  final PremiumPackage package;
  final VoidCallback? onBuy;

  const PremiumPackageCard({
    super.key,
    required this.package,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: package.isPopular ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: package.isPopular
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: package.isPopular
              ? const LinearGradient(
                  colors: [Colors.green, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Popular Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: package.isPopular ? Colors.white : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PaywallService.getDurationText(package.duration),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: package.isPopular ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (package.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Price
              Text(
                '${package.price.toStringAsFixed(0)} ${package.currency}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: package.isPopular ? Colors.white : Colors.green,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                PaywallService.getDurationDescription(package.duration),
                style: TextStyle(
                  fontSize: 14,
                  color: package.isPopular ? Colors.white70 : Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Features List
              ...package.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: package.isPopular ? Colors.white : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: package.isPopular ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: 24),
              
              // Buy Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onBuy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: package.isPopular ? Colors.white : Colors.green,
                    foregroundColor: package.isPopular ? Colors.green : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: package.isPopular ? 4 : 2,
                  ),
                  child: Text(
                    'Buy ${PaywallService.getDurationText(package.duration)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
