import 'package:flutter/material.dart';

/// Renders decorative props (plants, candles, bookends) and gap spacers on shelves.
class ShelfPropWidget extends StatelessWidget {
  final String propAssetId;
  final double? customWidth;

  const ShelfPropWidget({
    super.key,
    required this.propAssetId,
    this.customWidth,
  });

  @override
  Widget build(BuildContext context) {
    switch (propAssetId) {
      case 'gap':
        return SizedBox(width: customWidth ?? 28.0);
      case 'plant_monstera':
        return _buildMonstera();
      case 'plant_succulent':
        return _buildSucculent();
      case 'candle_amber':
        return _buildCandle();
      case 'bookend_brass':
        return _buildBookend();
      case 'cup_coffee':
        return _buildMug();
      default:
        return SizedBox(width: customWidth ?? 20.0);
    }
  }

  Widget _buildMonstera() {
    return Container(
      width: 58.0,
      height: 125.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Foliage
          Positioned(
            top: 0,
            child: Icon(
              Icons.eco,
              size: 78.0,
              color: Colors.green.shade800,
            ),
          ),
          // Pot
          Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A373),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 3.0,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSucculent() {
    return Container(
      width: 42.0,
      height: 70.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 4,
            child: Icon(
              Icons.spa,
              size: 42.0,
              color: Colors.teal.shade700,
            ),
          ),
          Container(
            width: 32.0,
            height: 26.0,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(6.0),
                bottomRight: Radius.circular(6.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandle() {
    return Container(
      width: 34.0,
      height: 65.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Flame glow
          Positioned(
            top: 0,
            child: Container(
              width: 10.0,
              height: 14.0,
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                borderRadius: BorderRadius.circular(5.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.6),
                    blurRadius: 6.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
            ),
          ),
          // Candle Jar
          Container(
            width: 30.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: const Color(0xFFB45309), // Amber glass
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.amber.shade900, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookend() {
    return Container(
      width: 24.0,
      height: 95.0,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE5C07B), // Brass
            Color(0xFFB8860B),
            Color(0xFF8B6508),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6.0),
          bottomLeft: Radius.circular(2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3.0,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMug() {
    return Container(
      width: 36.0,
      height: 40.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2.0,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.coffee, size: 20.0, color: Color(0xFF5D4037)),
      ),
    );
  }
}
