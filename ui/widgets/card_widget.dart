
import 'package:flutter/material.dart';
import '../../core/models/card_model.dart';
import '../styles/game_colors.dart';



class CardWidget extends StatelessWidget {
  final CardModel? card;
  final bool isFaceUp;
  final bool isComputerCard;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const CardWidget({
    super.key,
    required this.card,
    required this.isFaceUp,
    this.isComputerCard = false,
    this.isSelected = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? (screenWidth < 600 ? 100 : 120);
    final cardHeight = height ?? (screenWidth < 600 ? 140 : 180);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GameColors.accentGold : GameColors.textBlack,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: isFaceUp ? _buildCardFace(cardWidth, cardHeight) : _buildCardBack(),
        ),
      ),
    );
  }

  Widget _buildCardFace(double width, double height) {
    if (card == null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: width * 0.4,
              fontWeight: FontWeight.bold,
              color: GameColors.textBlack,
            ),
          ),
        ),
      );
    }

    final imagePath = _getCardImagePath();

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text if image not found
        return _buildFallbackCard(width, height);
      },
    );
  }

  Widget _buildCardBack() {
    return Image.asset(
      'assets/images/cards/card_back.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to gradient if image not found
        return Container(
          decoration: BoxDecoration(
            color: GameColors.cardBackBlue,
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GameColors.cardBackBlue,
                GameColors.cardBackBlue.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: Center(
                child: Text(
                  'PAP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCardImagePath() {
    if (card == null) return '';

    if (card!.name.isJoker) {
      if (card!.name == CardName.bigJoker) {
        return 'assets/images/cards/big_joker.jpg';
      } else {
        return 'assets/images/cards/little_joker.jpg';
      }
    }

    final suitName = _getSuitName();
    final cardName = _getCardName();
    return 'assets/images/cards/${suitName}_$cardName.jpg';
  }

  String _getSuitName() {
    switch (card!.suit) {
      case CardSuit.spade:
        return 'Spade';
      case CardSuit.heart:
        return 'Heart';
      case CardSuit.diamond:
        return 'Diamond';
      case CardSuit.club:
        return 'Club';
      default:
        return '';
    }
  }

  String _getCardName() {
    switch (card!.name) {
      case CardName.two:
        return '2';
      case CardName.three:
        return '3';
      case CardName.four:
        return '4';
      case CardName.five:
        return '5';
      case CardName.six:
        return '6';
      case CardName.seven:
        return '7';
      case CardName.eight:
        return '8';
      case CardName.nine:
        return '9';
      case CardName.ten:
        return '10';
      case CardName.jack:
        return 'J';
      case CardName.queen:
        return 'Q';
      case CardName.king:
        return 'K';
      case CardName.ace:
        return 'A';
      default:
        return '';
    }
  }

  Widget _buildFallbackCard(double width, double height) {
    final isRedSuit = card?.suit == CardSuit.heart ||
                      card?.suit == CardSuit.diamond;
    final suitColor = isRedSuit ? GameColors.heart : GameColors.spade;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(width * 0.05),
      child: Stack(
        children: [
          if (card!.suit != null)
            Center(
              child: Text(
                card!.suit!.symbol,
                style: TextStyle(
                  fontSize: width * 0.35,
                  color: suitColor,
                ),
              ),
            ),
          Positioned(
            top: width * 0.05,
            left: width * 0.05,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  card!.name.displayName,
                  style: TextStyle(
                    fontSize: width * 0.15,
                    fontWeight: FontWeight.bold,
                    color: suitColor,
                  ),
                ),
                if (card!.suit != null)
                  Text(
                    card!.suit!.symbol,
                    style: TextStyle(
                      fontSize: width * 0.18,
                      color: suitColor,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: width * 0.05,
            right: width * 0.05,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    card!.name.displayName,
                    style: TextStyle(
                      fontSize: width * 0.15,
                      fontWeight: FontWeight.bold,
                      color: suitColor,
                    ),
                  ),
                  if (card!.suit != null)
                    Text(
                      card!.suit!.symbol,
                      style: TextStyle(
                        fontSize: width * 0.18,
                        color: suitColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

