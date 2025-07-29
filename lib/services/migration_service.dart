import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/player.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Migrate player data from embedded contracts/endorsements to separate collections
  Future<void> migratePlayerData(String playerId) async {
    try {
      // Get the player document
      final playerDoc = await _firestore.collection('players').doc(playerId).get();
      
      if (!playerDoc.exists) {
        print('Player document not found: $playerId');
        return;
      }

      final playerData = playerDoc.data()!;
      
      // Check if migration is already done
      if (playerData.containsKey('contractIds') && playerData.containsKey('endorsementIds')) {
        print('Migration already completed for player: $playerId');
        return;
      }

      print('Starting migration for player: $playerId');

      // Migrate contracts
      if (playerData.containsKey('contracts') && playerData['contracts'] is List) {
        final contracts = playerData['contracts'] as List;
        final contractIds = <String>[];

        for (final contractData in contracts) {
          if (contractData is Map<String, dynamic>) {
            // Add userId to contract data
            final contractWithUserId = {
              ...contractData,
              'userId': playerId,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };

            // Create contract in separate collection
            final contractDoc = await _firestore.collection('contracts').add(contractWithUserId);
            contractIds.add(contractDoc.id);
            
            print('Migrated contract: ${contractDoc.id}');
          }
        }

        // Update player with contract IDs
        await _firestore.collection('players').doc(playerId).update({
          'contractIds': contractIds,
        });
      }

      // Migrate endorsements
      if (playerData.containsKey('endorsements') && playerData['endorsements'] is List) {
        final endorsements = playerData['endorsements'] as List;
        final endorsementIds = <String>[];

        for (final endorsementData in endorsements) {
          if (endorsementData is Map<String, dynamic>) {
            // Add userId to endorsement data
            final endorsementWithUserId = {
              ...endorsementData,
              'userId': playerId,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };

            // Create endorsement in separate collection
            final endorsementDoc = await _firestore.collection('endorsements').add(endorsementWithUserId);
            endorsementIds.add(endorsementDoc.id);
            
            print('Migrated endorsement: ${endorsementDoc.id}');
          }
        }

        // Update player with endorsement IDs
        await _firestore.collection('players').doc(playerId).update({
          'endorsementIds': endorsementIds,
        });
      }

      // Remove old embedded data
      await _firestore.collection('players').doc(playerId).update({
        'contracts': FieldValue.delete(),
        'endorsements': FieldValue.delete(),
      });

      print('Migration completed for player: $playerId');
    } catch (e) {
      print('Error during migration for player $playerId: $e');
      rethrow;
    }
  }

  // Migrate all players in the system
  Future<void> migrateAllPlayers() async {
    try {
      final playersSnapshot = await _firestore.collection('players').get();
      
      for (final doc in playersSnapshot.docs) {
        await migratePlayerData(doc.id);
      }
      
      print('Migration completed for all players');
    } catch (e) {
      print('Error during bulk migration: $e');
      rethrow;
    }
  }

  // Create Firestore indexes for the new structure
  Future<void> createIndexes() async {
    try {
      // Note: In a real application, you would create these indexes through the Firebase Console
      // or using the Firebase CLI. This is just a placeholder for documentation.
      
      print('Required Firestore indexes:');
      print('Collection: contracts');
      print('- userId (Ascending) + status (Ascending)');
      print('- userId (Ascending) + createdAt (Descending)');
      print('- userId (Ascending) + startDate (Ascending) + endDate (Ascending)');
      
      print('Collection: endorsements');
      print('- userId (Ascending) + status (Ascending)');
      print('- userId (Ascending) + createdAt (Descending)');
      print('- userId (Ascending) + startDate (Ascending) + endDate (Ascending)');
      print('- status (Ascending) + createdAt (Descending)');
      
      print('Collection: transactions');
      print('- userId (Ascending) + date (Descending)');
      
      print('Please create these indexes in the Firebase Console for optimal performance.');
    } catch (e) {
      print('Error creating indexes: $e');
    }
  }

  // Validate migration
  Future<bool> validateMigration(String playerId) async {
    try {
      final playerDoc = await _firestore.collection('players').doc(playerId).get();
      
      if (!playerDoc.exists) {
        return false;
      }

      final playerData = playerDoc.data()!;
      
      // Check if new structure exists
      if (!playerData.containsKey('contractIds') || !playerData.containsKey('endorsementIds')) {
        return false;
      }

      final contractIds = List<String>.from(playerData['contractIds'] ?? []);
      final endorsementIds = List<String>.from(playerData['endorsementIds'] ?? []);

      // Verify contracts exist
      for (final contractId in contractIds) {
        final contractDoc = await _firestore.collection('contracts').doc(contractId).get();
        if (!contractDoc.exists) {
          print('Contract not found: $contractId');
          return false;
        }
      }

      // Verify endorsements exist
      for (final endorsementId in endorsementIds) {
        final endorsementDoc = await _firestore.collection('endorsements').doc(endorsementId).get();
        if (!endorsementDoc.exists) {
          print('Endorsement not found: $endorsementId');
          return false;
        }
      }

      // Check that old embedded data is removed
      if (playerData.containsKey('contracts') || playerData.containsKey('endorsements')) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating migration: $e');
      return false;
    }
  }
} 