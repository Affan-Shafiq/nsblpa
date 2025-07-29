# Database Structure Documentation

## Overview

The NSBLPA Players App has been restructured to use separate collections for contracts and endorsements, with automatic income calculation based on active agreements.

## Collections Structure

### 1. Players Collection
```javascript
{
  id: "player_document_id",
  userId: "firebase_auth_uid",
  firstName: "John",
  lastName: "Doe",
  email: "john.doe@example.com",
  profileImageUrl: "https://...",
  team: "Team Name",
  position: "Point Guard",
  jerseyNumber: 23,
  dateOfBirth: "1990-01-01T00:00:00.000Z",
  nationality: "USA",
  stats: {
    gamesPlayed: 82,
    pointsPerGame: 25.5,
    // ... other stats
  },
  contractIds: ["contract_id_1", "contract_id_2"], // References to contracts collection
  endorsementIds: ["endorsement_id_1", "endorsement_id_2"], // References to endorsements collection
  finances: {
    currentSeasonEarnings: 2500000.0,
    careerEarnings: 15000000.0,
    endorsementEarnings: 500000.0,
    contractEarnings: 2000000.0,
    yearlyEarnings: [
      {
        year: 2023,
        earnings: 3000000.0,
        endorsements: 500000.0,
        contracts: 2500000.0
      }
    ],
    recentTransactions: [] // References to transactions collection
  },
  memberSince: "2020-01-01T00:00:00.000Z"
}
```

### 2. Contracts Collection
```javascript
{
  id: "contract_document_id",
  userId: "firebase_auth_uid", // Reference to player
  type: "player", // "player", "endorsement", "sponsorship"
  title: "NBA Player Contract",
  description: "Standard NBA player contract",
  annualValue: 2500000.0,
  startDate: "2023-10-01T00:00:00.000Z",
  endDate: "2024-06-30T00:00:00.000Z",
  status: "active", // "active", "expired", "pending", "terminated"
  documentUrl: "https://...", // Optional
  incentives: ["Playoff bonus", "All-Star bonus"],
  terms: {
    // Additional contract terms
  },
  createdAt: "2023-10-01T00:00:00.000Z",
  updatedAt: "2023-10-01T00:00:00.000Z"
}
```

### 3. Endorsements Collection
```javascript
{
  id: "endorsement_document_id",
  userId: "firebase_auth_uid", // Reference to player (null if available)
  brandName: "Nike",
  category: "Athletic Wear",
  description: "Shoe endorsement deal",
  value: 500000.0,
  duration: "2 years",
  status: "active", // "active", "expired", "pending", "available"
  imageUrl: "https://...", // Optional
  requirements: ["Social media posts", "Public appearances"],
  startDate: "2023-01-01T00:00:00.000Z",
  endDate: "2024-12-31T00:00:00.000Z",
  createdAt: "2023-01-01T00:00:00.000Z",
  updatedAt: "2023-01-01T00:00:00.000Z"
}
```

### 4. Transactions Collection
```javascript
{
  id: "transaction_document_id",
  userId: "firebase_auth_uid", // Reference to player
  description: "Monthly salary payment",
  amount: 208333.33,
  type: "income", // "income", "expense"
  category: "salary",
  date: "2023-11-01T00:00:00.000Z",
  status: "completed" // "completed", "pending", "failed"
}
```

## Automatic Income Calculation

The system automatically calculates player income from multiple sources:

### 1. Contract Earnings
- Sum of all active contracts' annual values
- Prorated for current season based on date ranges
- Only includes contracts with status "active" and not expired

### 2. Endorsement Earnings
- Sum of all active endorsements' values
- Prorated for current season based on date ranges
- Only includes endorsements with status "active"

### 3. Current Season Earnings
- Calculated based on NBA season (October to June)
- Prorated based on days elapsed in current season
- Formula: `(contractEarnings + endorsementEarnings) * (daysElapsed / daysInSeason)`

### 4. Career Earnings
- Sum of all historical earnings from contracts and endorsements

### 5. Yearly Earnings
- Calculated for the last 5 years
- Shows breakdown by year with contract vs endorsement earnings

## Required Firestore Indexes

For optimal performance, create the following composite indexes:

### Contracts Collection
- `userId` (Ascending) + `status` (Ascending)
- `userId` (Ascending) + `createdAt` (Descending)
- `userId` (Ascending) + `startDate` (Ascending) + `endDate` (Ascending)

### Endorsements Collection
- `userId` (Ascending) + `status` (Ascending)
- `userId` (Ascending) + `createdAt` (Descending)
- `userId` (Ascending) + `startDate` (Ascending) + `endDate` (Ascending)
- `status` (Ascending) + `createdAt` (Descending)

### Transactions Collection
- `userId` (Ascending) + `date` (Descending)

## Migration from Old Structure

The old structure embedded contracts and endorsements directly in the player document. To migrate:

1. Use the `MigrationService` to convert existing data
2. Run `migrateAllPlayers()` to process all existing players
3. Validate migration with `validateMigration(playerId)`

## Services

### PlayerService
- Manages player profile and basic data
- Handles automatic finance calculation
- Coordinates with other services

### ContractService
- Manages contracts collection
- Handles CRUD operations for contracts
- Calculates contract-specific earnings

### FinancialService
- Handles all financial calculations
- Manages transactions
- Provides earnings breakdowns and summaries

### MigrationService
- Handles data migration from old structure
- Validates migration success
- Provides migration utilities

## Benefits of New Structure

1. **Scalability**: Separate collections allow for better querying and indexing
2. **Performance**: Reduced document size and better query performance
3. **Flexibility**: Easier to add new contract/endorsement types
4. **Data Integrity**: Better referential integrity with userId references
5. **Automatic Calculations**: Real-time income calculation based on active agreements
6. **Audit Trail**: Timestamps for all changes
7. **Multi-tenancy**: Clear separation of data by user

## Usage Examples

### Adding a New Contract
```dart
final contract = Contract(
  id: '',
  userId: player.userId,
  type: 'player',
  title: 'NBA Contract',
  description: 'Standard NBA player contract',
  annualValue: 2500000.0,
  startDate: DateTime(2023, 10, 1),
  endDate: DateTime(2024, 6, 30),
  status: 'active',
  // ... other fields
);

await contractService.addContract(contract);
// Finances are automatically recalculated
```

### Getting Player Finances
```dart
final finances = await financialService.getFinancialSummary(player.userId);
print('Current season earnings: ${finances?.currentSeasonEarnings}');
```

### Calculating Monthly Earnings
```dart
final monthlyEarnings = await financialService.calculateMonthlyEarnings(
  player.userId, 
  2023, 
  11
);
``` 