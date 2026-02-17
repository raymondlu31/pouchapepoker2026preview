import 'package:flutter/material.dart';

/// Represents the four suits in a standard deck of playing cards
enum CardSuit {
  spade,
  heart,
  diamond,
  club;

  String get displayName {
    switch (this) {
      case CardSuit.spade:
        return 'Spade';
      case CardSuit.heart:
        return 'Heart';
      case CardSuit.diamond:
        return 'Diamond';
      case CardSuit.club:
        return 'Club';
    }
  }

  String get symbol {
    switch (this) {
      case CardSuit.spade:
        return '♠';
      case CardSuit.heart:
        return '♥';
      case CardSuit.diamond:
        return '♦';
      case CardSuit.club:
        return '♣';
    }
  }

  Color get color {
    switch (this) {
      case CardSuit.spade:
      case CardSuit.club:
        return Colors.black;
      case CardSuit.heart:
      case CardSuit.diamond:
        return Colors.red;
    }
  }
}

/// Represents the name/value of a card
enum CardName {
  two(2),
  three(3),
  four(4),
  five(5),
  six(6),
  seven(7),
  eight(8),
  nine(9),
  ten(10),
  jack(11),
  queen(12),
  king(13),
  ace(14),
  littleJoker(15),
  bigJoker(16);

  final int value;

  const CardName(this.value);

  String get displayName {
    switch (this) {
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
      case CardName.littleJoker:
        return 'Little Joker';
      case CardName.bigJoker:
        return 'Big Joker';
    }
  }

  /// Check if this card is a joker
  bool get isJoker => this == CardName.littleJoker || this == CardName.bigJoker;

  /// Check if this card is a regular playing card (not joker)
  bool get isRegularCard => !isJoker;

  /// Get intuitive card size category
  String get intuitiveSize {
    if (value >= 2 && value <= 6) return 'Small';
    if (value >= 7 && value <= 9) return 'Middle';
    if (value >= 10) return 'Big';
    return 'Unknown';
  }
}

/// Represents the current status/location of a card in the game
enum CardStatus {
  inDeck,      // In the deck, not yet dealt
  dealed,      // Dealt but not revealed (user's face-down card)
  revealed,    // Revealed to all players
}

/// Model representing a single poker card
class CardModel {
  final String cardId;          // Unique identifier: '<suit>_<name>' or 'joker_type'
  final CardSuit? suit;         // Null for jokers
  final CardName name;          // Card value/name
  final int value;              // Numerical value: 2-16
  final String suitSymbol;      // "♠", "♥", "♦", "♣", or empty for jokers
  bool isDealed;                // Whether card has been dealt
  bool isRevealed;              // Whether card has been revealed
  String cardImagePath;         // Path to card image asset

  CardModel({
    required this.cardId,
    required this.suit,
    required this.name,
    required this.value,
    required this.suitSymbol,
    this.isDealed = false,
    this.isRevealed = false,
    required this.cardImagePath,
  });

  /// Factory constructor for creating a regular card (not joker)
  factory CardModel.regularCard({
    required CardSuit suit,
    required CardName name,
  }) {
    if (name.isJoker) {
      throw ArgumentError('Use CardModel.joker() for joker cards');
    }

    final cardId = '${suit.displayName.toLowerCase()}_${name.displayName.toLowerCase()}';
    final value = name.value;
    final suitSymbol = suit.symbol;

    return CardModel(
      cardId: cardId,
      suit: suit,
      name: name,
      value: value,
      suitSymbol: suitSymbol,
      cardImagePath: 'assets/images/cards/$cardId.png', // Adjust path as needed
    );
  }

  /// Factory constructor for creating a joker card
  factory CardModel.joker({
    required CardName name,
  }) {
    if (!name.isJoker) {
      throw ArgumentError('Use CardModel.regularCard() for non-joker cards');
    }

    final cardId = name == CardName.littleJoker ? 'little_joker' : 'big_joker';
    final value = name.value;

    return CardModel(
      cardId: cardId,
      suit: null,
      name: name,
      value: value,
      suitSymbol: '', // Jokers have no suit symbol
      cardImagePath: 'assets/images/cards/$cardId.png', // Adjust path as needed
    );
  }

  /// Get the current status of the card
  CardStatus get status {
    if (isRevealed) return CardStatus.revealed;
    if (isDealed) return CardStatus.dealed;
    return CardStatus.inDeck;
  }

  /// Set the status of the card
  set status(CardStatus newStatus) {
    switch (newStatus) {
      case CardStatus.inDeck:
        isDealed = false;
        isRevealed = false;
        break;
      case CardStatus.dealed:
        isDealed = true;
        isRevealed = false;
        break;
      case CardStatus.revealed:
        isDealed = true;
        isRevealed = true;
        break;
    }
  }

  /// Get display name with suit (e.g., "A♠" or "Big Joker")
  String get displayNameWithSuit {
    if (suit == null) {
      return name.displayName;
    }
    return '${name.displayName}$suitSymbol';
  }

  /// Get full descriptive name (e.g., "Ace of Spades" or "Big Joker")
  String get fullName {
    if (suit == null) {
      return name.displayName;
    }
    return '${name.displayName} of ${suit!.displayName}s';
  }

  /// Check if this card can tie with another card (jokers cannot tie)
  bool canTieWith(CardModel other) {
    if (name.isJoker || other.name.isJoker) {
      return false; // Jokers cannot tie
    }
    return value == other.value;
  }

  /// Compare this card with another card
  /// Returns: 1 if this > other, 0 if equal, -1 if this < other
  int compareTo(CardModel other) {
    if (value > other.value) return 1;
    if (value < other.value) return -1;
    return 0;
  }

  /// Check if this card is higher than another card
  bool isHigherThan(CardModel other) => compareTo(other) == 1;

  /// Check if this card is lower than another card
  bool isLowerThan(CardModel other) => compareTo(other) == -1;

  /// Check if this card is equal to another card (for non-jokers)
  bool isEqualTo(CardModel other) => compareTo(other) == 0;

  @override
  String toString() {
    return 'CardModel(id: $cardId, name: ${name.displayName}, value: $value, '
           'suit: ${suit?.displayName ?? "N/A"}, status: $status)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          cardId == other.cardId;

  @override
  int get hashCode => cardId.hashCode;
}

/// Utility class for creating and managing a full deck of 54 cards
class DeckManager {
  /// Create a complete deck of 54 cards (52 regular + 2 jokers)
  static List<CardModel> createFullDeck() {
    final List<CardModel> deck = [];

    // Add regular cards (4 suits × 13 values)
    for (final suit in CardSuit.values) {
      // Skip joker from CardName enum (last two entries)
      for (final name in CardName.values.take(13)) {
        deck.add(CardModel.regularCard(suit: suit, name: name));
      }
    }

    // Add jokers
    deck.add(CardModel.joker(name: CardName.littleJoker));
    deck.add(CardModel.joker(name: CardName.bigJoker));

    return deck;
  }

  /// Get cards by their current status
  static List<CardModel> getCardsByStatus(
    List<CardModel> allCards,
    CardStatus status,
  ) {
    return allCards.where((card) => card.status == status).toList();
  }

  /// Get count of cards by value in a given list
  static Map<int, int> getValueCounts(List<CardModel> cards) {
    final counts = <int, int>{};
    for (final card in cards) {
      counts[card.value] = (counts[card.value] ?? 0) + 1;
    }
    return counts;
  }

  /// Get cards grouped by their intuitive size category
  static Map<String, List<CardModel>> groupByIntuitiveSize(List<CardModel> cards) {
    final groups = <String, List<CardModel>>{
      'Small': [],
      'Middle': [],
      'Big': [],
    };

    for (final card in cards) {
      final size = card.name.intuitiveSize;
      if (groups.containsKey(size)) {
        groups[size]!.add(card);
      }
    }

    return groups;
  }
}