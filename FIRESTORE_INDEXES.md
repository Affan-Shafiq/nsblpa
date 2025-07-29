# Firestore Indexes Required

## Conversations Collection

The following composite index is required for the conversations collection to support the query used in the messaging feature:

### Index 1: Conversations by Participant and Updated At
- **Collection**: `conversations`
- **Fields**:
  1. `participants` (Array contains)
  2. `updatedAt` (Descending)
  3. `__name__` (Descending)

**Direct Link**: https://console.firebase.google.com/v1/r/project/salesbetregularapp/firestore/indexes?create_composite=Clhwcm9qZWN0cy9zYWxlc2JldHJlZ3VsYXJhcHAvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2NvbnZlcnNhdGlvbnMvaW5kZXhlcy9fEAEaEAoMcGFydGljaXBhbnRzGAEaDQoJdXBkYXRlZEF0EAIaDAoIX19uYW1lX18QAg

## Contracts Collection

The following composite index is required for the contracts collection to support financial calculations and yearly earnings queries:

### Index 2: Contracts by User ID and Date Range
- **Collection**: `contracts`
- **Fields**:
  1. `userId` (Ascending)
  2. `endDate` (Ascending)
  3. `startDate` (Ascending)
  4. `__name__` (Ascending)

**Direct Link**: https://console.firebase.google.com/v1/r/project/salesbetregularapp/firestore/indexes?create_composite=ClRwcm9qZWN0cy9zYWxlc2JldHJlZ3VsYXJhcHAvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2NvbnRyYWN0cy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoLCgdlbmREYXRlEAEaDQoJc3RhcnREYXRlEAEaDAoIX19uYW1lX18QAQ

## Transactions Collection

The following composite index is required for the transactions collection to support financial history queries:

### Index 3: Transactions by User ID and Date
- **Collection**: `transactions`
- **Fields**:
  1. `userId` (Ascending)
  2. `date` (Descending)
  3. `__name__` (Descending)

**Direct Link**: https://console.firebase.google.com/v1/r/project/salesbetregularapp/firestore/indexes?create_composite=Cldwcm9qZWN0cy9zYWxlc2JldHJlZ3VsYXJhcHAvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3RyYW5zYWN0aW9ucy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoICgRkYXRlEAIaDAoIX19uYW1lX18QAg

## Endorsements Collection

The following composite index is required for the endorsements collection to support financial calculations and yearly earnings queries:

### Index 4: Endorsements by User ID and Date Range
- **Collection**: `endorsements`
- **Fields**:
  1. `userId` (Ascending)
  2. `endDate` (Ascending)
  3. `startDate` (Ascending)
  4. `__name__` (Ascending)

**Direct Link**: https://console.firebase.google.com/v1/r/project/salesbetregularapp/firestore/indexes?create_composite=Cldwcm9qZWN0cy9zYWxlc2JldHJlZ3VsYXJhcHAvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2VuZG9yc2VtZW50cy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoLCgdlbmREYXRlEAEaDQoJc3RhcnREYXRlEAEaDAoIX19uYW1lX18QAQ

## How to Create All Indexes

### Method 1: Via Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `salesbetregularapp`
3. Go to Firestore Database
4. Click on "Indexes" tab
5. Click "Create Index" for each collection
6. Add the fields as specified above

### Method 2: Via Direct Links
Click each link above to create the index directly in Firebase Console.

### Method 3: Via Firebase CLI (firestore.indexes.json)
```json
{
  "indexes": [
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "participants",
          "arrayConfig": "CONTAINS"
        },
        {
          "fieldPath": "updatedAt",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "contracts",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "endDate",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startDate",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "date",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "DESCENDING"
                 }
       ]
     },
     {
       "collectionGroup": "endorsements",
       "queryScope": "COLLECTION",
       "fields": [
         {
           "fieldPath": "userId",
           "order": "ASCENDING"
         },
         {
           "fieldPath": "endDate",
           "order": "ASCENDING"
         },
         {
           "fieldPath": "startDate",
           "order": "ASCENDING"
         },
         {
           "fieldPath": "__name__",
           "order": "ASCENDING"
         }
       ]
     }
   ]
 }
```

## Index Status and Impact

### Conversations Index
- **Status**: Required for messaging functionality
- **Impact**: Without this index, conversation queries will fail
- **Query**: `conversations.where('participants', arrayContains: userId).orderBy('updatedAt', descending: true)`

### Contracts Index
- **Status**: Required for financial calculations
- **Impact**: Without this index, yearly earnings calculations will fail
- **Query**: `contracts.where('userId', isEqualTo: userId).where('startDate', isLessThanOrEqualTo: endDate).where('endDate', isGreaterThanOrEqualTo: startDate)`

### Transactions Index
- **Status**: Required for financial history
- **Impact**: Without this index, transaction history queries will fail
- **Query**: `transactions.where('userId', isEqualTo: userId).orderBy('date', descending: true)`

### Endorsements Index
- **Status**: Required for financial calculations
- **Impact**: Without this index, yearly earnings calculations will fail
- **Query**: `endorsements.where('userId', isEqualTo: userId).where('startDate', isLessThanOrEqualTo: endDate).where('endDate', isGreaterThanOrEqualTo: startDate)`

## Build Time
- **Individual Indexes**: 1-5 minutes each
- **All Indexes**: 5-15 minutes total
- **Status**: Check Firebase Console for build progress

## Additional Notes
- All indexes support queries used in the NSBLPA app
- The `__name__` field is automatically included for consistent ordering
- Indexes are required for proper app functionality
- Monitor Firebase Console for any index build errors 