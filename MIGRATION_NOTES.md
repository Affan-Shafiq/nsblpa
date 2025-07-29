# Migration Notes - Firebase Auth UID Fix

## Issue Fixed
The conversation service was using player document IDs (like `player_michael_johnson`) instead of Firebase Auth UIDs for conversation participants.

## Changes Made

### 1. ConversationService.getOrCreateConversationByEmail()
- **Before**: Used `receiverDoc.id` (document ID)
- **After**: Uses `receiverData['userId']` (Firebase Auth UID)
- **Added**: Validation to ensure Firebase Auth UID exists

### 2. Validation Added
```dart
final receiverUserId = receiverData['userId'];

// Validate that we have a Firebase Auth UID
if (receiverUserId == null || receiverUserId.isEmpty) {
  _error = 'User with email $receiverEmail does not have a valid Firebase Auth UID';
  notifyListeners();
  return null;
}
```

## Potential Migration Steps

### If Existing Conversations Exist with Wrong IDs
If there are existing conversations in the database that were created with document IDs instead of Firebase Auth UIDs, you may need to migrate them:

1. **Check Existing Conversations**:
   ```javascript
   // In Firebase Console or via script
   db.collection('conversations').get().then(snapshot => {
     snapshot.docs.forEach(doc => {
       const data = doc.data();
       console.log('Conversation ID:', doc.id);
       console.log('Participants:', data.participants);
       console.log('Participant Names:', data.participantNames);
     });
   });
   ```

2. **Migration Script** (if needed):
   ```javascript
   // This would need to be run as a one-time migration
   const conversations = await db.collection('conversations').get();
   
   for (const doc of conversations.docs) {
     const data = doc.data();
     const participants = data.participants;
     
     // Check if participants contain document IDs instead of Firebase Auth UIDs
     const needsMigration = participants.some(participant => 
       participant.startsWith('player_') || participant.includes('_')
     );
     
     if (needsMigration) {
       // Update participants to use Firebase Auth UIDs
       // This would require looking up each player document
       // and replacing the document ID with the userId field
     }
   }
   ```

## Testing
1. Create a new conversation with a valid user email
2. Verify that the conversation participants use Firebase Auth UIDs
3. Check that both users can see the conversation
4. Verify that messages are sent and received correctly

## Notes
- New conversations will use Firebase Auth UIDs correctly
- Existing conversations may need migration if they were created with document IDs
- The validation ensures that only users with valid Firebase Auth UIDs can be added to conversations 